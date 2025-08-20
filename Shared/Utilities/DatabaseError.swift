import Foundation

enum DatabaseError: LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case notFound
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        case .notFound:
            return "Data not found"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

extension Result where Failure == DatabaseError {
    /// Logs error if present and returns success value
    func logIfError() -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            Logger.error(error.localizedDescription)
            return nil
        }
    }
}