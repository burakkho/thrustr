import Foundation
import SwiftData

struct BenchmarkWOD {
    let name: String
    let type: String // Use String instead of WODType to avoid ambiguity
    let movements: [(name: String, rxMale: String?, rxFemale: String?, reps: Int?)]
    let repScheme: [Int]
    let timeCap: Int?
    let description: String
    let category: WODCategory
}

// MARK: - Benchmark WODs Database
struct BenchmarkWODDatabase {
    static let all: [BenchmarkWOD] = girls + heroes
    
    // The Girls
    static let girls: [BenchmarkWOD] = [
        BenchmarkWOD(
            name: "Fran",
            type: "for_time",
            movements: [
                ("Thrusters", "43kg", "30kg", nil),
                ("Pull-ups", nil, nil, nil)
            ],
            repScheme: [21, 15, 9],
            timeCap: nil,
            description: "21-15-9 reps for time",
            category: .girls
        ),
        BenchmarkWOD(
            name: "Grace",
            type: "for_time",
            movements: [
                ("Clean and Jerk", "61kg", "43kg", 30)
            ],
            repScheme: [],
            timeCap: nil,
            description: "30 reps for time",
            category: .girls
        ),
        BenchmarkWOD(
            name: "Helen",
            type: "for_time",
            movements: [
                ("400m Run", nil, nil, 1),
                ("Kettlebell Swings", "24kg", "16kg", 21),
                ("Pull-ups", nil, nil, 12)
            ],
            repScheme: [3], // 3 rounds
            timeCap: nil,
            description: "3 rounds for time",
            category: .girls
        ),
        BenchmarkWOD(
            name: "Diane",
            type: "for_time",
            movements: [
                ("Deadlifts", "102kg", "70kg", nil),
                ("Handstand Push-ups", nil, nil, nil)
            ],
            repScheme: [21, 15, 9],
            timeCap: nil,
            description: "21-15-9 reps for time",
            category: .girls
        ),
        BenchmarkWOD(
            name: "Cindy",
            type: "amrap",
            movements: [
                ("Pull-ups", nil, nil, 5),
                ("Push-ups", nil, nil, 10),
                ("Air Squats", nil, nil, 15)
            ],
            repScheme: [],
            timeCap: 1200, // 20 minutes
            description: "AMRAP in 20 minutes",
            category: .girls
        ),
        BenchmarkWOD(
            name: "Annie",
            type: "for_time",
            movements: [
                ("Double-unders", nil, nil, nil),
                ("Sit-ups", nil, nil, nil)
            ],
            repScheme: [50, 40, 30, 20, 10],
            timeCap: nil,
            description: "50-40-30-20-10 reps for time",
            category: .girls
        ),
        BenchmarkWOD(
            name: "Christine",
            type: "for_time",
            movements: [
                ("500m Row", nil, nil, 1),
                ("Deadlifts (BW)", nil, nil, 12),
                ("Box Jumps", "21\"", "21\"", 21)
            ],
            repScheme: [3], // 3 rounds
            timeCap: nil,
            description: "3 rounds for time",
            category: .girls
        ),
        BenchmarkWOD(
            name: "Kelly",
            type: "for_time",
            movements: [
                ("400m Run", nil, nil, 1),
                ("Box Jumps", "24\"", "20\"", 30),
                ("Wall Balls", "9kg", "6kg", 30)
            ],
            repScheme: [5], // 5 rounds
            timeCap: nil,
            description: "5 rounds for time",
            category: .girls
        )
    ]
    
    // Hero WODs
    static let heroes: [BenchmarkWOD] = [
        BenchmarkWOD(
            name: "Murph",
            type: "for_time",
            movements: [
                ("1 Mile Run", nil, nil, 1),
                ("Pull-ups", nil, nil, 100),
                ("Push-ups", nil, nil, 200),
                ("Air Squats", nil, nil, 300),
                ("1 Mile Run", nil, nil, 1)
            ],
            repScheme: [],
            timeCap: nil,
            description: "For time (with 20/14 lb vest)",
            category: .heroes
        ),
        BenchmarkWOD(
            name: "DT",
            type: "for_time",
            movements: [
                ("Deadlifts", "70kg", "48kg", 12),
                ("Hang Power Cleans", "70kg", "48kg", 9),
                ("Push Jerks", "70kg", "48kg", 6)
            ],
            repScheme: [5], // 5 rounds
            timeCap: nil,
            description: "5 rounds for time",
            category: .heroes
        ),
        BenchmarkWOD(
            name: "Kalsu",
            type: "for_time",
            movements: [
                ("Thrusters", "61kg", "43kg", 100),
                ("Burpees", nil, nil, 5) // 5 burpees EMOM
            ],
            repScheme: [],
            timeCap: nil,
            description: "100 thrusters with 5 burpees EMOM",
            category: .heroes
        ),
        BenchmarkWOD(
            name: "Amanda",
            type: "for_time",
            movements: [
                ("Muscle-ups", nil, nil, nil),
                ("Squat Snatches", "61kg", "43kg", nil)
            ],
            repScheme: [9, 7, 5],
            timeCap: nil,
            description: "9-7-5 reps for time",
            category: .heroes
        )
    ]
    
    // Create WOD model from benchmark
    static func createWOD(from benchmark: BenchmarkWOD) -> WOD {
        // Convert string type to WODType enum
        let wodType = WODType(rawValue: benchmark.type) ?? .custom
        
        let wod = WOD(
            name: benchmark.name,
            type: wodType,
            repScheme: benchmark.repScheme,
            timeCap: benchmark.timeCap,
            isCustom: false
        )
        
        // Add movements
        for (index, movement) in benchmark.movements.enumerated() {
            let wodMovement = WODMovement(
                name: movement.name,
                rxWeightMale: movement.rxMale,
                rxWeightFemale: movement.rxFemale,
                reps: movement.reps,
                orderIndex: index
            )
            wodMovement.wod = wod
            if wod.movements == nil { wod.movements = [] }
            wod.movements!.append(wodMovement)
        }
        
        return wod
    }
}