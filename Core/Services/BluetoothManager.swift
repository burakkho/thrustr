import Foundation
import CoreBluetooth
import SwiftUI

@Observable
class BluetoothManager: NSObject {
    // MARK: - Shared Instance
    static let shared = BluetoothManager()
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
    var lastError: String?
    var connectionAttempts: Int = 0
    
    // Heart rate zones
    var maxHeartRate: Int = 190
    var restingHeartRate: Int = 60
    var currentZone: HeartRateZone = .resting
    
    // MARK: - Constants
    private let heartRateServiceUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementUUID = CBUUID(string: "0x2A37")
    private let batteryServiceUUID = CBUUID(string: "0x180F")
    private let batteryLevelUUID = CBUUID(string: "0x2A19")
    
    // UserDefaults key for storing last connected device UUID
    private let lastConnectedDeviceKey = "LastConnectedBluetoothDevice"
    
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
        
        guard centralManager?.state == .poweredOn else {
            Logger.warning("Bluetooth not powered on, state: \(centralManager?.state.rawValue ?? -1)")
            return
        }
        
        isScanning = true
        discoveredDevices.removeAll()
        
        // Scan for all peripherals, not just heart rate (some devices don't advertise heart rate service)
        centralManager?.scanForPeripherals(
            withServices: nil, // Scan all services to find more devices
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )
        
        Logger.info("Started scanning for all Bluetooth devices (looking for heart rate capable)")
        
        // Stop scanning after 15 seconds (longer timeout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            if self?.isScanning == true {
                self?.stopScanning()
                Logger.info("Scanning timeout - stopped after 15 seconds")
            }
        }
    }
    
    func stopScanning() {
        isScanning = false
        centralManager?.stopScan()
        Logger.info("Stopped scanning")
    }
    
    func connect(to device: BluetoothDevice) {
        stopScanning()
        lastError = nil
        connectionAttempts += 1
        
        heartRatePeripheral = device.peripheral
        heartRatePeripheral?.delegate = self
        centralManager?.connect(device.peripheral, options: nil)
        
        // Save device UUID for auto-reconnect
        UserDefaults.standard.set(device.peripheral.identifier.uuidString, forKey: lastConnectedDeviceKey)
        
        Logger.info("Attempting to connect to \(device.name) (attempt \(connectionAttempts))")
        
        // Set timeout for connection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if let self = self, !self.isConnected {
                self.lastError = "Connection timeout"
                Logger.warning("Connection timeout for device: \(device.name)")
                
                // Try to reconnect if attempts < 3
                if self.connectionAttempts < 3 {
                    Logger.info("Retrying connection...")
                    self.connect(to: device)
                } else {
                    self.connectionAttempts = 0
                    Logger.error("Failed to connect after 3 attempts")
                }
            }
        }
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
        guard let uuidString = UserDefaults.standard.string(forKey: lastConnectedDeviceKey),
              let uuid = UUID(uuidString: uuidString) else {
            Logger.info("No saved device UUID found for reconnection")
            return
        }
        
        guard isBluetoothEnabled else {
            Logger.info("Bluetooth not enabled, cannot reconnect")
            return
        }
        
        // Try to retrieve the peripheral by UUID
        let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid])
        
        if let peripheral = peripherals?.first {
            Logger.info("Found saved device, attempting to reconnect to: \(peripheral.name ?? "Unknown")")
            
            // Create a BluetoothDevice wrapper for the existing connect method
            let savedDevice = BluetoothDevice(
                peripheral: peripheral,
                name: peripheral.name ?? "Saved Device",
                rssi: -50 // Default RSSI since we don't have real-time data
            )
            
            connect(to: savedDevice)
        } else {
            Logger.info("Saved device not found, starting scan to find it")
            startScanning() // Fallback to scanning if device not immediately available
        }
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
        
        // Filter potential heart rate devices by name patterns
        let heartRateDevicePatterns = [
            "polar", "garmin", "wahoo", "suunto", "coospo", "magene", 
            "hr", "heart", "chest", "strap", "band", "monitor",
            "h7", "h9", "h10", "4iiii", "heartrate", "hrm"
        ]
        
        let isLikelyHeartRateDevice = heartRateDevicePatterns.contains { pattern in
            name.lowercased().contains(pattern.lowercased())
        }
        
        // Also check if device advertises heart rate service
        let advertisesHeartRate = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let hasHeartRateService = advertisesHeartRate.contains(heartRateServiceUUID)
        
        // Only add devices that are likely heart rate monitors or advertise heart rate service
        if (isLikelyHeartRateDevice || hasHeartRateService) && 
           !discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            
            let device = BluetoothDevice(
                peripheral: peripheral,
                name: name,
                rssi: RSSI.intValue
            )
            discoveredDevices.append(device)
            
            Logger.info("Discovered heart rate device: \(name) with RSSI: \(RSSI), hasService: \(hasHeartRateService)")
        } else {
            // Log all devices for debugging
            Logger.info("Skipped device: \(name) (not heart rate related)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionAttempts = 0 // Reset on successful connection
        lastError = nil
        connectedDevice = discoveredDevices.first { $0.peripheral.identifier == peripheral.identifier }
        
        // Discover services
        peripheral.discoverServices([heartRateServiceUUID, batteryServiceUUID])
        
        Logger.success("Successfully connected to \(peripheral.name ?? "device")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown connection error"
        lastError = errorMessage
        isConnected = false
        connectedDevice = nil
        
        Logger.error("Failed to connect to \(peripheral.name ?? "device"): \(errorMessage)")
        
        // Don't auto-retry here - let the timeout handler manage retries
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