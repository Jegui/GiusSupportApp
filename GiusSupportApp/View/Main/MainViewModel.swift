//
//  MainViewModel.swift
//  GiusSupportApp
//
//  Created by Juan Emilio Eguizabal on 16/10/2022.
//

import CoreBluetooth
import Foundation

enum MainAlert {
    case bluetoothNeeded
    case periphericalServicesFetchFailed
}

class MainViewModel: NSObject {
    
    // Data
    private var centralManager: CBCentralManager?
    private var bluefruitPeripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?
    private var peripheralArray: [CBPeripheral] = []
    private var rssiArray = [NSNumber]()
    private var timer = Timer()
    
    var refreshView: (()-> Void)?
    var presentAlert: ((MainAlert) -> Void)?
    var titleString: String = ""
    var welcomeMessage: String = ""
    var infoString: String = ""
    
    init(titleString: String, welcomeMessage: String) {
        self.titleString = titleString
        self.welcomeMessage = welcomeMessage
    }
}


// MARK: - CBCentralManagerDelegate
// A protocol that provides updates for the discovery and management of peripheral devices.
extension MainViewModel: CBCentralManagerDelegate {
    
    func startScanning() -> Void {
        // Remove prior data
        peripheralArray.removeAll()
        rssiArray.removeAll()
        // Start Scanning
        centralManager?.scanForPeripherals(withServices: [], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        infoString = "Scanning..."
        //scanningButton.isEnabled = false
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in
            self.stopScanning()
        }
    }
    
    func stopTimer() -> Void {
        // Stops Timer
        self.timer.invalidate()
    }
    
    func stopScanning() -> Void {
        infoString = "Scanning stopped"
//        scanningButton.isEnabled = true
        centralManager?.stopScan()
    }
    
    
    // MARK: - Check
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff:
            print("Is Powered Off.")
            presentAlert?(.bluetoothNeeded)
            
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
        
        infoString = "Peripherals Found: \(peripheralArray.count)"
        
        bluefruitPeripheral?.delegate = self
        
        print("Peripheral Discovered: \(peripheral)")
        
        refreshView?()
    }
    
    // MARK: - Connect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        bluefruitPeripheral?.discoverServices([])
    }
}

// MARK: - CBPeripheralDelegate
// A protocol that provides updates on the use of a peripheral’s services.
extension MainViewModel: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        guard let service = services.first(where: {$0.uuid == CBUUID(string: "FFE0")}) else {
//            presentAlert(title: "Could not fetch peripherical serivces", description: "")
            presentAlert?(.periphericalServicesFetchFailed)
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

//                print("RX Characteristic: \(rxCharacteristic?.uuid)")
//                presentConsole()
            }
            
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                BlePeripheral.connectedTXChar = txCharacteristic
//                print("TX Characteristic: \(txCharacteristic.uuid)")
            }
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        var characteristicASCIIValue = NSString()
        
        guard characteristic == rxCharacteristic,
                let characteristicValue = characteristic.value,
              let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }
        
        characteristicASCIIValue = ASCIIstring
        
        print("Value Recieved: \((characteristicASCIIValue as String))")
        
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: "\((characteristicASCIIValue as String))")
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
