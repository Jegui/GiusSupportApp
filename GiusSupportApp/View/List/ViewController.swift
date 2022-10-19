//
//  ViewController.swift
//  Basic Chat
//
//  Created by Trevor Beaton on 2/3/21.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    // Data
    private var centralManager: CBCentralManager!
    private var bluefruitPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    private var peripheralArray: [CBPeripheral] = []
    private var rssiArray = [NSNumber]()
    private var timer = Timer()
    
    private var messageQueue: [String] = []
    
    // UI
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var peripheralFoundLabel: UILabel!
    @IBOutlet weak var scanningLabel: UILabel!
    @IBOutlet weak var scanningButton: UIButton!
    
    @IBAction func scanningAction(_ sender: Any) {
        startScanning()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        // Manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        disconnectFromDevice()
        self.tableView.reloadData()
        //startScanning()
    }
    
    func connectToDevice() -> Void {
        centralManager?.connect(bluefruitPeripheral!, options: nil)
    }
    
    func disconnectFromDevice() -> Void {
        if bluefruitPeripheral != nil {
            centralManager?.cancelPeripheralConnection(bluefruitPeripheral!)
        }
    }
    
    func removeArrayData() -> Void {
        centralManager.cancelPeripheralConnection(bluefruitPeripheral)
        rssiArray.removeAll()
        peripheralArray.removeAll()
    }
    
    func startScanning() -> Void {
        // Remove prior data
        peripheralArray.removeAll()
        rssiArray.removeAll()
        // Start Scanning
        centralManager?.scanForPeripherals(withServices: [], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        scanningLabel.text = "Scanning..."
        scanningButton.isEnabled = false
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in
            self.stopScanning()
        }
    }
    
    func scanForBLEDevices() -> Void {
        // Remove prior data
        peripheralArray.removeAll()
        rssiArray.removeAll()
        // Start Scanning
        centralManager?.scanForPeripherals(withServices: [] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        scanningLabel.text = "Scanning..."
        
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in
            self.stopScanning()
        }
    }
    
    func stopTimer() -> Void {
        // Stops Timer
        self.timer.invalidate()
    }
    
    func stopScanning() -> Void {
        scanningLabel.text = ""
        scanningButton.isEnabled = true
        centralManager?.stopScan()
    }
    
    func delayedConnection() -> Void {
        
        BlePeripheral.connectedPeripheral = bluefruitPeripheral
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            //Once connected, move to new view controller to manager incoming and outgoing data
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//
//                    let detailViewController = storyboard.instantiateViewController(withIdentifier: "ConsoleViewController") as! ConsoleViewController
//                    self.navigationController?.pushViewController(detailViewController, animated: true)
            self.navigationController!.pushViewController(GloveDetailViewController(nibName: "GloveDetailViewController", bundle: nil), animated: true )
        })
    }
    func presentConsole() {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        
//        let detailViewController = storyboard.instantiateViewController(withIdentifier: "ConsoleViewController") as! ConsoleViewController
//        self.navigationController?.pushViewController(detailViewController, animated: true)
        self.navigationController!.pushViewController(GloveDetailViewController(nibName: "GloveDetailViewController", bundle: nil), animated: true )
    }
}

// MARK: - CBCentralManagerDelegate
// A protocol that provides updates for the discovery and management of peripheral devices.
extension ViewController: CBCentralManagerDelegate {
    
    // MARK: - Check
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff:
            print("Is Powered Off.")
            presentAlert(title: "Bluetooth Required", description: "Check tour Bluetooth Settings")
            
        case .poweredOn:
            print("Is Powered On.")
            startScanning()
        case .unsupported:
            print("Is Unsupported.")
        case .unauthorized:
            print("Is Unauthorized.")
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        @unknown default:
            print("Error")
        }
    }
    
    // MARK: - Discover
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Function: \(#function),Line: \(#line)")
        
        bluefruitPeripheral = peripheral
        
        if peripheralArray.contains(peripheral) {
            print("Duplicate Found.")
        } else {
            peripheralArray.append(peripheral)
            rssiArray.append(RSSI)
        }
        
        peripheralFoundLabel.text = "Peripherals Found: \(peripheralArray.count)"
        
        bluefruitPeripheral.delegate = self
        
        print("Peripheral Discovered: \(peripheral)")
        
        self.tableView.reloadData()
    }
    
    // MARK: - Connect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        bluefruitPeripheral.discoverServices([])
    }
}

// MARK: - CBPeripheralDelegate
// A protocol that provides updates on the use of a peripheral’s services.
extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        guard let service = services.first(where: {$0.uuid == CBUUID(string: "FFE0")}) else {
            presentAlert(title: "Could not fetch peripherical serivces", description: "")
            return
        }
        BlePeripheral.connectedService = service
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Found \(characteristics.count) characteristics.")
        
        for characteristic in characteristics {
            print("🤯 \(characteristic)")
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {
                
                rxCharacteristic = characteristic
                
                BlePeripheral.connectedRXChar = rxCharacteristic
                
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)

                print("RX Characteristic: \(rxCharacteristic.uuid)")
                presentConsole()
            }
            
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                BlePeripheral.connectedTXChar = txCharacteristic
                print("TX Characteristic: \(txCharacteristic.uuid)")
            }
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        var characteristicASCIIValue = NSString()
        
        guard characteristic == rxCharacteristic,
              let characteristicValue = characteristic.value,
              let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }
        
        characteristicASCIIValue = ASCIIstring
        messageQueue.append(characteristicASCIIValue as String)
        
        if characteristicASCIIValue.contains("}") {
            let completeMessage = "\((messageQueue.joined() + "\n" as String))"
            print("Value Recieved: \((completeMessage as String))")
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object:  completeMessage)
            messageQueue.removeAll()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        peripheral.readRSSI()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Function: \(#function),Line: \(#line)")
        print("Message sent")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        print("Function: \(#function),Line: \(#line)")
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
}

// MARK: - UITableViewDataSource
// The methods adopted by the object you use to manage data and provide cells for a table view.
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripheralArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! TableViewCell
        
        let peripheralFound = self.peripheralArray[indexPath.row]
        
        let rssiFound = self.rssiArray[indexPath.row]
        
        if peripheralFound == nil {
            cell.peripheralLabel.text = "Unknown"
        }else {
            cell.peripheralLabel.text = peripheralFound.name
            cell.rssiLabel.text = "RSSI: \(rssiFound)"
        }
        return cell
    }
    
    
}


// MARK: - UITableViewDelegate
// Methods for managing selections, deleting and reordering cells and performing other actions in a table view.
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        bluefruitPeripheral = peripheralArray[indexPath.row]
        
        BlePeripheral.connectedPeripheral = bluefruitPeripheral
        
        connectToDevice()
        
    }
}

