import Foundation
import WatchConnectivity

// MARK: - Watch Communication Service Protocol (Clean Architecture)
protocol WatchCommunicationServiceProtocol: Sendable {
    static func sendMessage(_ message: WatchMessage) async throws -> WatchCommunicationResult
    static func sendWorkoutSession(_ session: WatchWorkoutSession) async throws -> WatchCommunicationResult
    static func requestHealthData() async throws -> WatchHealthData?
    static func syncUserSettings(_ settings: WatchUserSettings) async throws -> WatchCommunicationResult
    static func updateApplicationContext(_ data: [String: Any]) async throws

    // Connection State
    static var isReachable: Bool { get }
    static var isConnected: Bool { get }
    static var connectionStatus: String { get }
}

// MARK: - Watch Session Delegate Protocol
protocol WatchSessionDelegate: AnyObject, Sendable {
    func didReceiveMessage(_ message: WatchMessage)
    func didReceiveWorkoutSession(_ session: WatchWorkoutSession)
    func didReceiveHealthData(_ healthData: WatchHealthData)
    func didUpdateConnectionStatus(_ isConnected: Bool)
    func didReceiveError(_ error: WatchCommunicationError)
}

// MARK: - Watch Communication Error
enum WatchCommunicationError: Error, Sendable {
    case watchNotReachable
    case sessionNotActivated
    case encodingFailed
    case decodingFailed
    case timeout
    case watchAppNotInstalled
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .watchNotReachable:
            return "Apple Watch ulaşılabilir değil"
        case .sessionNotActivated:
            return "Watch connectivity session aktif değil"
        case .encodingFailed:
            return "Veri kodlaması başarısız"
        case .decodingFailed:
            return "Veri çözümlemesi başarısız"
        case .timeout:
            return "İşlem zaman aşımına uğradı"
        case .watchAppNotInstalled:
            return "Watch uygulaması yüklü değil"
        case .unknown(let message):
            return "Bilinmeyen hata: \(message)"
        }
    }
}

// MARK: - Message Encoder/Decoder Protocol
protocol WatchMessageCodingProtocol: Sendable {
    static func encode<T: Codable>(_ object: T) throws -> [String: Any]
    static func decode<T: Codable>(_ data: [String: Any], as type: T.Type) throws -> T
    static func encodeMessage(_ message: WatchMessage) throws -> [String: Any]
    static func decodeMessage(_ data: [String: Any]) throws -> WatchMessage
}

// MARK: - Watch Health Service Protocol
protocol WatchHealthServiceProtocol: Sendable {
    static func getCurrentHeartRate() async throws -> Int?
    static func getStepsCount() async throws -> Int?
    static func getCaloriesCount() async throws -> Int?
    static func startHealthMonitoring() async throws
    static func stopHealthMonitoring() async throws
}

// MARK: - Watch Storage Service Protocol
protocol WatchStorageServiceProtocol: Sendable {
    static func saveWorkoutSession(_ session: WatchWorkoutSession) async throws
    static func loadWorkoutSessions() async throws -> [WatchWorkoutSession]
    static func deleteWorkoutSession(_ sessionId: UUID) async throws
    static func saveUserSettings(_ settings: WatchUserSettings) async throws
    static func loadUserSettings() async throws -> WatchUserSettings?
}