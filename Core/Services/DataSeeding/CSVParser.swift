import Foundation

// MARK: - Standardized CSV Parser
struct CSVParser {
    static func parseCSVRow(_ row: String) -> [String] {
        // Very simple and safe CSV parsing
        let fields = row.components(separatedBy: ",")
        return fields.map { field in
            let trimmed = field.trimmingCharacters(in: .whitespacesAndNewlines)
            // Remove quotes safely
            if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count > 1 {
                return String(trimmed.dropFirst().dropLast())
            }
            return trimmed
        }
    }
    
    static func parseCSVFile(_ filename: String) throws -> [[String]] {
        // Support both root Resources and subfolder paths
        var url: URL?
        
        // First try with subfolder path (e.g., "Training/Cardio/outdoor_cardio")
        if filename.contains("/") {
            let components = filename.components(separatedBy: "/")
            let fileName = components.last ?? filename
            let subpath = components.dropLast().joined(separator: "/")
            url = Bundle.main.url(forResource: fileName, withExtension: "csv", subdirectory: subpath)
            Logger.info("Trying subfolder path: \(subpath)/\(fileName).csv")
        }
        
        // If not found or no subfolder, try root Resources
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "csv")
            Logger.info("Trying root Resources: \(filename).csv")
        }
        
        // Try specific subdirectories for metcon_exercises
        if url == nil && filename == "metcon_exercises" {
            url = Bundle.main.url(forResource: "metcon_exercises", withExtension: "csv", subdirectory: "Training/Exercises")
            Logger.info("Trying Training/Exercises: metcon_exercises.csv")
        }
        
        guard let fileURL = url else {
            Logger.error("CSV file not found in bundle: \(filename).csv")
            throw DataSeederError.fileNotFound(filename)
        }
        
        Logger.info("Found CSV file at: \(fileURL.path)")
        
        let csvData: String
        do {
            csvData = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw DataSeederError.parsingError("Failed to read CSV file: \(error)")
        }
        
        // Split by newlines and clean up
        let rows = csvData.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard rows.count > 1 else {
            throw DataSeederError.emptyFile(filename)
        }
        
        var parsedRows: [[String]] = []
        
        for (index, row) in rows.enumerated() {
            let parsedRow = parseCSVRow(row)
            
            // Skip completely empty rows
            if parsedRow.allSatisfy({ $0.isEmpty }) {
                Logger.warning("Skipping empty row at index \(index) in \(filename)")
                continue
            }
            
            parsedRows.append(parsedRow)
        }
        
        Logger.info("Successfully parsed \(parsedRows.count) rows from \(filename)")
        return parsedRows
    }
    
    static func parseJSONFile<T: Codable>(_ filename: String, as type: T.Type) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw DataSeederError.fileNotFound(filename)
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DataSeederError.parsingError("Failed to read JSON file: \(error)")
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw DataSeederError.parsingError("Failed to decode JSON: \(error)")
        }
    }
}