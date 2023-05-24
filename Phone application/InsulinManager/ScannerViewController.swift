import UIKit
import CoreBluetooth

final class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BluetoothSerialDelegate {

    //MARK: Variables
    
    @IBOutlet weak var tryAgain: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    //Discovered peripherals
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []

    var selectedPeripheral: CBPeripheral?

    //MARK: Functions

    override func viewDidLoad(){
        super.viewDidLoad()

        //The button will only be availble once a scan is timed out
        tryAgain.isEnabled = false
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //Tell the delegate to notificate the current screen if something goes wrong
        serial.delegate = self

        if serial.centralManager.state != .poweredOn {
            title = "Bluetooth turned off"
            return
        }

        serial.startScan()
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }

    override func didReceiveMemoryWarning() {
        //Dispose unneccesary resources
        super.didReceiveMemoryWarning()
    }

    //Will be called upon 10 seconds after the try again button has been pressed
    @objc func scanTimeOut() {
        serial.stopScan()
        tryAgain.isEnabled = true
        title = "Scanning done"
    }

    //Will be called 10 seconds after first connection attempt
    @objc func connectTimeOut() {

        //Dont bother if we succeded connecting
        if let _ = serial.connectedPeripheral{
            return
        }

        if let _ = selectedPeripheral {
            serial.disconnect()
            selectedPeripheral = nil
        }
    }

    //MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    //Adds discovered peripherals into the tableview for the user to see and select
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //TODO: Change cell label tag to 1
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let label = cell.viewWithTag(1) as? UILabel
        label?.text = peripherals[(indexPath as NSIndexPath).row].peripheral.name
        return cell
    }

    //MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)

        //When user has selected a device, stop scanning and proceed to the next screen
        serial.stopScan()
        selectedPeripheral = peripherals[(indexPath as NSIndexPath).row].peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        
        //Set a timer for 10 seconds then call on the timeout func
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(ScannerViewController.connectTimeOut), userInfo: nil, repeats: false)
    }

    //MARK: BluetoothSerialDelegate

    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        //Check if its a duplicate
        for existing in peripherals {
            if existing.peripheral.identifier == peripheral.identifier {return}
        }

        //add into the array, sort and reload again
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append((peripheral: peripheral, RSSI: theRSSI))
        peripherals.sort {$0.RSSI < $1.RSSI}
        tableView.reloadData()
    }

    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        tryAgain.isEnabled = true
        let alert = UIAlertController(title: "Error!", message: "Failed to connect", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {action -> Void in alert.dismiss(animated: true) }))
        present(alert, animated: true)
    
    }

    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        tryAgain.isEnabled = true
        let alert = UIAlertController(title: "Error!", message: "Connection failed", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {action -> Void in alert.dismiss(animated: true) }))
        present(alert, animated: true)

    }

    //Returns to main screen once connection has been established
    func serialIsReady(_ peripheral: CBPeripheral) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
        dismiss(animated: true, completion: nil)
        NSLog("Connection established")
    }
    
    //Returns to main screen if bluetooth is turned off while scanner screen is active
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
            dismiss(animated: true, completion: nil)
            NSLog("Bluetooth off")
        }
    }

    //MARK: IBActions
    
    @IBAction func cancel(_ sender: Any){
        serial.stopScan()
        dismiss(animated: true)
    }
    
    @IBAction func tryAgain(_ sender: AnyObject){
        peripherals = []
        tableView.reloadData()
        tryAgain.isEnabled = false
        title = "Scanning ..."
        serial.startScan()
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }
    

}
