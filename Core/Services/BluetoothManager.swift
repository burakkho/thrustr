import Foundation
import CoreBluetooth
import SwiftUI

@Observable
class BluetoothManager: NSObject {
    // MARK: - Properties
    private var centralManager: CBCentralManager?
    private var heartRatePeripheral: CBPeripheral?
    private var heartRateCharacteristic: CBCharacteristic?
    
    // Published properties
    var isBluetoothEnabled = false
    var isScanning = false
    var isConnected = false
    var discoveredDevices: [BluetoothDevice] = []
    var connectedDevice: BluetoothDevice?
    var currentHeartRate: Int = 0
    var heartRateHistory: [(Date, Int)] = []
    var batteryLevel: Int?
    
    // Heart rate zones
    var maxHeartRate: Int = 190
    var restingHeartRate: Int = 60
    var currentZone: HeartRateZone = .resting
    
    // MARK: - Constants
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementUUID = CBUUID(string: "0x2A37")
    private let batteryServiceUUID = CBUUID(string: "0x180F")
    private let batteryLevelUUID = CBUUID(string: "0x2A19")
    
    // MARK: - Models
    struct BluetoothDevice: Identifiable {
        let id = UUID()
        let peripheral: CBPeripheral
        let name: String
        let rssi: Int
        
        var signalStrength: String {
            if rssi > -60 { return "Güçlü" }
            else if rssi > -80 { return "Orta" }
            else { return "Zayıf" }
        }
    }
    
    enum HeartRateZone: String, CaseIterable {
        case resting = "Dinlenme"
        case zone1 = "Zone 1: Isınma"
        case zone2 = "Zone 2: Yağ Yakımı"
        case zone3 = "Zone 3: Aerobik"
        case zone4 = "Zone 4: Anaerobik"
        case zone5 = "Zone 5: Maksimum"
        
        var color: Color {
            switch self {
            case .resting: return .blue
            case .zone1: return .green
            case .zone2: return .yellow
            case .zone3: return .orange
            case .zone4: return .red
            case .zone5: return .purple
            }
        }
        
        var emoji: String {
            switch self {
            case .resting: return "😌"
            case .zone1: return "🚶"
            case .zone2: return "🏃‍♀️"
            case .zone3: return "🏃"
            case .zone4: return "🏃‍♂️💨"
            case .zone5: return "🔥"
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard isBluetoothEnabled else {
            Logger.warning("Bluetooth is not enabled")
            return
        }
        
        isScanning = true
        discoveredDevices.removeAll()
        
        centralManager?.scanForPeripherals(
            withServices: [heartRateServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        Logger.info("Started scanning for heart rate devices")
        
        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }
    }
    
    func stopScanning() {
        isScanning = false
        centralManager?.stopScan()
        Logger.info("Stopped scanning")
    }
    
    func connect(to device: BluetoothDevice) {
        stopScanning()
        heartRatePeripheral = device.peripheral
        heartRatePeripheral?.delegate = self
        centralManager?.connect(device.peripheral, options: nil)
        
        Logger.info("Attempting to connect to \(device.name)")
    }
    
    func disconnect() {
        guard let peripheral = heartRatePeripheral else { return }
        
        if let characteristic = heartRateCharacteristic {
            peripheral.setNotifyValue(false, for: characteristic)
        }
        
        centralManager?.cancelPeripheralConnection(peripheral)
        
        isConnected = false
        connectedDevice = nil
        heartRatePeripheral = nil
        heartRateCharacteristic = nil
        currentHeartRate = 0
        
        Logger.info("Disconnected from heart rate device")
    }
    
    func reconnectToLastDevice() {
        // TODO: Implement auto-reconnect using saved device UUID
    }
    
    // MARK: - Heart Rate Methods
    func updateHeartRateZones(max: Int, resting: Int) {
        maxHeartRate = max
        restingHeartRate = resting
        updateCurrentZone()
    }
    
    func updateHeartRateZonesKarvonen(max: Int, resting: Int) {
        maxHeartRate = max
        restingHeartRate = resting
        updateCurrentZoneKarvonen()
    }
    
    private func updateCurrentZone() {
        let percentage = Double(currentHeartRate) / Double(maxHeartRate)
        
        switch percentage {
        case 0..<0.5:
            currentZone = .resting
        case 0.5..<0.6:
            currentZone = .zone1
        case 0.6..<0.7:
            currentZone = .zone2
        case 0.7..<0.8:
            currentZone = .zone3
        case 0.8..<0.9:
            currentZone = .zone4
        default:
            currentZone = .zone5
        }
    }
    
    private func updateCurrentZoneKarvonen() {
        let heartRateReserve = maxHeartRate - restingHeartRate
        let percentage = Double(currentHeartRate - restingHeartRate) / Double(heartRateReserve)
        
        switch percentage {
        case 0..<0.5:
            currentZone = .zone1
        case 0.5..<0.6:
            currentZone = .zone2
        case 0.6..<0.7:
            currentZone = .zone3
        case 0.7..<0.85:
            currentZone = .zone4
        case 0.85...1.0:
            currentZone = .zone5
        default:
            currentZone = .resting
        }
    }
    
    func getAverageHeartRate() -> Int {
        guard !heartRateHistory.isEmpty else { return 0 }
        let sum = heartRateHistory.reduce(0) { $0 + $1.1 }
        return sum / heartRateHistory.count
    }
    
    func getMaxHeartRate() -> Int {
        return heartRateHistory.map { $0.1 }.max() ?? 0
    }
    
    func getTimeInZones() -> [HeartRateZone: TimeInterval] {
        // TODO: Calculate time spent in each zone
        return [:]
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothEnabled = true
            Logger.info("Bluetooth is powered on")
        case .poweredOff:
            isBluetoothEnabled = false
            Logger.warning("Bluetooth is powered off")
        case .unauthorized:
            Logger.error("Bluetooth unauthorized")
        case .unsupported:
            Logger.error("Bluetooth unsupported")
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown Device"
        
        // Filter out already discovered devices
        if !discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            let device = BluetoothDevice(
                peripheral: peripheral,
                name: name,
                rssi: RSSI.intValue
            )
            discoveredDevices.append(device)
            
            Logger.info("Discovered device: \(name) with RSSI: \(RSSI)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectedDevice = discoveredDevices.first { $0.peripheral.identifier == peripheral.identifier }
        
        // Discover services
        peripheral.discoverServices([heartRateServiceUUID, batteryServiceUUID])
        
        Logger.info("Connected to \(peripheral.name ?? "device")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Logger.error("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        isConnected = false
        connectedDevice = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            Logger.error("Disconnected with error: \(error.localizedDescription)")
        } else {
            Logger.info("Device disconnected")
        }
        
        isConnected = false
        connectedDevice = nil
        currentHeartRate = 0
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            Logger.error("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        for service in peripheral.services ?? [] {
            if service.uuid == heartRateServiceUUID {
                peripheral.discoverCharacteristics([heartRateMeasurementUUID], for: service)
            } else if service.uuid == batteryServiceUUID {
                peripheral.discoverCharacteristics([batteryLevelUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            Logger.error("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == heartRateMeasurementUUID {
                heartRateCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                Logger.info("Started monitoring heart rate")
            } else if characteristic.uuid == batteryLevelUUID {
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            Logger.error("Error updating value: \(error!.localizedDescription)")
            return
        }
        
        if characteristic.uuid == heartRateMeasurementUUID {
            parseHeartRate(from: characteristic)
        } else if characteristic.uuid == batteryLevelUUID {
            parseBatteryLevel(from: characteristic)
        }
    }
    
    private func parseHeartRate(from characteristic: CBCharacteristic) {
        guard let data = characteristic.value else { return }
        
        let bytes = [UInt8](data)
        guard bytes.count >= 2 else { return }
        
        // Check if heart rate is 8-bit or 16-bit
        let isHeartRateFormat16Bit = (bytes[0] & 0x01) != 0
        let heartRate: Int
        
        if isHeartRateFormat16Bit {
            heartRate = Int(bytes[1]) | (Int(bytes[2]) << 8)
        } else {
            heartRate = Int(bytes[1])
        }
        
        currentHeartRate = heartRate
        heartRateHistory.append((Date(), heartRate))
        
        // Keep only last 5 minutes of history
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        heartRateHistory = heartRateHistory.filter { $0.0 > fiveMinutesAgo }
        
        updateCurrentZone()
    }
    
    private func parseBatteryLevel(from characteristic: CBCharacteristic) {
        guard let data = characteristic.value else { return }
        let bytes = [UInt8](data)
        guard bytes.count >= 1 else { return }
        
        batteryLevel = Int(bytes[0])
        Logger.info("Battery level: \(batteryLevel ?? 0)%")
    }
}