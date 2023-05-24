import UIKit
import CoreBluetooth

//Global serial handler
var serial: BluetoothSerial!

//Delegate functions
protocol BluetoothSerialDelegate: AnyObject {

    //called upon when state of the CBCentralManager changes
    func serialDidChangeState()

    //Called when a device is disconnected
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?)
    
    //Called when a new device is discovered while scanning
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?)
    
    //Called when a device is connected
    func serialDidConnect(_ peripheral: CBPeripheral)
    
    //Called when trying to establish a connection failed
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?)
    
    //Called when a device is ready for communication
    func serialIsReady(_ peripheral: CBPeripheral)
}

extension BluetoothSerialDelegate {
    func serialDidChangeState() {}
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?){}
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?){}
    func serialDidConnect(_ peripheral: CBPeripheral){}
    func serialDidReceiveData(_ data: Data){}
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?){}
    func serialIsReady(_ peripheral: CBPeripheral){}
}

final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    //The delegate object that we call on from other ViewControllers
    weak var delegate: BluetoothSerialDelegate?

    //Used for basically everything
    var centralManager: CBCentralManager!

    //The peripheral we're trying to connect to, nil if there is none
    var pendingPeripheral: CBPeripheral?

    //The connected device, nil if there is none connected
    var connectedPeripheral: CBPeripheral?

    //The characteristic 0xFFE1 we need to write to
    weak var writeCharacteristic: CBCharacteristic?

    //Whether the serial is ready to send data
    var isReady: Bool {
        get {
            return centralManager.state == .poweredOn &&
                connectedPeripheral != nil &&
                writeCharacteristic != nil
        }
    }

    var isPoweredOn: Bool {
        return centralManager.state == .poweredOn
    }

    //We will only be searching for devices with the same characteristics as the HM-10 module
    var serviceUUID = CBUUID(string: "FFE0")

    var characteristicUUID = CBUUID(string: "FFE1")

    //Authentic HM-10 modules requires a 'withoutResponse'
    //Add this for 'didDiscoverCharacteristicsFor' if you don't know and it will sort itself
    //writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
    private var writeType: CBCharacteristicWriteType = .withoutResponse

    // MARK: functions

    //Initialize this instance
    init(delegate: BluetoothSerialDelegate) {
        super.init()
        self.delegate = delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {return}

        //Start scanning for devices with HM-10 service UUID
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)

        //Retrieve peripherals that are already connected
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        for peripheral in peripherals {
            delegate?.serialDidDiscoverPeripheral(peripheral, RSSI: nil)
        }
    }

    func stopScan() {
        centralManager.stopScan()
    }
    
    //Attempt to establish a connection
    func connectToPeripheral(_ peripheral: CBPeripheral){
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
        

    func disconnect() {
        
        //Neccesary if CBPeripheral is nil otherwise app crashes
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        } else if let p = pendingPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        
    }
    
    //reading strength of the signal
    func readRSSI() {
        guard isReady else { return }
        connectedPeripheral!.readRSSI()
    }

    //Will be called upon with button pressed to send strings for the arduino to receive
    func sendMessageToDevice(_ message: String) {
        guard isReady else {return}

        if let data = message.data(using: String.Encoding.utf8) {
            connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
        }else {NSLog("Error trying to send message")}
        
    }


    //MARK: CBCentralManagerDelegate functions

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //Send results to the delegate
        delegate?.serialDidDiscoverPeripheral(peripheral, RSSI: RSSI)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        // send to the delegate
        delegate?.serialDidConnect(peripheral)

        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        pendingPeripheral = nil
        
        //send result to delegate
        delegate?.serialDidFailToConnect(peripheral, error: error as NSError?)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        pendingPeripheral = nil

        // send it to the delegate
        delegate?.serialDidDisconnect(peripheral, error: error as NSError?)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        connectedPeripheral = nil
        pendingPeripheral = nil

        // send it to the delegate
        delegate?.serialDidChangeState()
    }

    //MARK: CBPeripheralDelegate functions
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //Discover HM-10 characteristic for all services
        for service in peripheral.services!{
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // check whether the characteristic we're looking for (0xFFE1) is present - just to be sure
        for characteristic in service.characteristics! {
            if characteristic.uuid == characteristicUUID {
                
                // keep a reference to this characteristic so we can write to it
                writeCharacteristic = characteristic
                
                // notify the delegate we're ready for communication
                delegate?.serialIsReady(peripheral)
            }
        }
    }
}


