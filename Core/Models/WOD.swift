import Foundation
import SwiftUI

enum WODType: String, Codable, CaseIterable {
    case forTime
    case amrap
    case emom
    case custom
}

struct WODTemplate: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let type: WODType
    let description: String
    let movements: [String]
}

enum WODLookup {
    static let benchmark: [WODTemplate] = [
        WODTemplate(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Fran",
            type: .forTime,
            description: "21-15-9: Thrusters 95/65 lb, Pull-ups",
            movements: ["21-15-9 reps", "Thrusters 95/65 lb", "Pull-ups"]
        ),
        WODTemplate(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Murph",
            type: .forTime,
            description: "1 mile run, 100 pull-ups, 200 push-ups, 300 air squats, 1 mile run",
            movements: ["1 mile run", "100 Pull-ups", "200 Push-ups", "300 Air Squats", "1 mile run"]
        ),
        WODTemplate(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Grace",
            type: .forTime,
            description: "30 Clean and Jerks for time (135/95 lb)",
            movements: ["30 Clean & Jerk 135/95 lb"]
        ),
        WODTemplate(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "Helen",
            type: .forTime,
            description: "3 rounds: 400m run, 21 kettlebell swings, 12 pull-ups",
            movements: ["3 rounds", "400m Run", "21 KB Swings", "12 Pull-ups"]
        ),
        WODTemplate(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            name: "Cindy",
            type: .amrap,
            description: "20 min AMRAP: 5 pull-ups, 10 push-ups, 15 air squats",
            movements: ["20 min AMRAP", "5 Pull-ups", "10 Push-ups", "15 Air Squats"]
        )
    ]

    static func template(for id: UUID?) -> WODTemplate? {
        guard let id else { return nil }
        return benchmark.first { $0.id == id }
    }

    static func name(for id: UUID?) -> String? {
        template(for: id)?.name
    }
}


