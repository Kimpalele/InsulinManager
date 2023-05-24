//
//  ViewController.swift
//  InsulinManager
//
//  Created by Kim Jogholt on 2023-04-18.
//  Copyright © 2023 KimJ. All rights reserved.
//

import UIKit
import CoreBluetooth

final class ViewController: UIViewController, BluetoothSerialDelegate {
    
    //MARK: Variables
    
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var inputDose: UITextField!
    
    var alert: UIAlertController!
    var pos: Double = 0
    let productName: String = "Insulin Manager"
    
    

    //MARK: Functions

    override func viewDidLoad() {
        super.viewDidLoad()
        
        serial = BluetoothSerial(delegate: self)
        reloadView()
        

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reloadView),
                        name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
    }

    deinit{
        NotificationCenter.default.removeObserver(self)
    }


    //Refreshes main screen
    @objc func reloadView() {
        serial.delegate = self

        if serial.isReady {
            //When connected display the name of the device
            //And make the disconnect button red
            navItem.title = serial.connectedPeripheral!.name
            barButton.title = "Disconnect"
            barButton.tintColor = UIColor.red
            barButton.isEnabled = true
        } else if serial.centralManager.state == .poweredOn {
            //If BT is on but not connected, display the app name
            //and make the connect button blue, highlighting it
            navItem.title = productName
            barButton.title = "Connect"
            barButton.tintColor = UIColor.link
            barButton.isEnabled = true
        } else {
            //If either BT is off or something else is wrong, disable button
            navItem.title = productName
            barButton.title = "Connect"
            barButton.tintColor = UIColor.link
            barButton.isEnabled = false
        }
    }

    //MARK: BluetoothSerialDelegate

    //Notifies user and screen when device disconnects
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadView()
        createButtonAlert(title: "Disconnected", msg: "Connection has been terminated", confirmText: "OK")
        
    }

    //Notifies user and screen when bluetooth is off
    func serialDidChangeState() {
        reloadView()
        if serial.centralManager.state != .poweredOn {
            createButtonAlert(title: "No Bluetooth", msg: "Bluetooth is off", confirmText: "OK")
            
        }
    }
    
    //MARK: More functions

    //Checks if app is connected to device
    func notConnected() -> Bool {
        if !serial.isReady {
            return true
        } else {
            return false
        }
    }

    //Could add "OK" as a standard label for
    //the button but I prefer having it fluid
    func createButtonAlert(title: String, msg: String, confirmText: String){
        alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmText, style: UIAlertAction.Style.default,
            handler: { action -> Void in self.dismiss(animated: true) }))

        present(alert, animated: true)
    }

    //Creates a timed alert for however long you want and afterwards
    //the times has ended it dismisses itself
    func createTimedAlert(title: String, msg: String, timer: Double){
        alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        Timer.scheduledTimer(timeInterval: timer, target: self, selector:
            #selector(ViewController.dismissAlert), userInfo: nil, repeats: false)
    }

    //So that we cam dismiss our timed alerts
    @objc func dismissAlert(){
        alert.dismiss(animated: true)
    }

    //Checks if device is connected. If so, the buttonpress
    //will disconnect device, if not, open scanner screen
    @IBAction func connectButton(_ sender: Any) {
        if serial.connectedPeripheral == nil {
            performSegue(withIdentifier: "Scanner", sender: self)
        } else {
            serial.disconnect()
            reloadView()
        }
    }
    
    @IBAction func resetButton(_ sender: Any) {
        if !notConnected(){
            if (pos > 0){
                //Creating a popup alert notifying the user that the motor
                //position is being reset and notifies user with interactive
                //popup alert telling the user its done.
                createTimedAlert(title: "Resetting. . .", msg: "Resetting motor position", timer: 5)
                serial.sendMessageToDevice("reset")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.createButtonAlert(title: "Done", msg: "Position reset", confirmText: "OK") }
                pos = 0
                
            } else {
                createButtonAlert(title: "Hold up!",
                                  msg: "Motor is already at\nthe starting position", confirmText: "OK")
            }
        } else {
            createButtonAlert(title: "No connection",
                              msg: "Can't reset motor position\nwithout a connection", confirmText: "OK")
        }
    }
    
    //Reads the user input and sends the input as a string
    @IBAction func sendDose(_ sender: UIButton) {
        if !notConnected(){
            if let dose = inputDose.text, !dose.isEmpty {
                pos += Double(dose)!
                serial.sendMessageToDevice(dose)
                NSLog(dose)
                createTimedAlert(title: "Heads up!", msg: "Motor in motion!", timer: 2)
                view.endEditing(true)
            } else {
                createButtonAlert(title: "No input",
                                  msg: "You haven't entered an input", confirmText: "OK")
            }
        } else {
            createButtonAlert(title: "No connection",
                              msg: "Can't distribute dose\nwithout a connection", confirmText: "OK")
            
        }
        
    }



}
