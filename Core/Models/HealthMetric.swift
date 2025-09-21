import Foundation
import SwiftUI

enum HealthMetric: String, CaseIterable {
    case steps
    case weight
    case heartRate

    var displayName: String {
        switch self {
        case .steps: return CommonKeys.HealthKit.stepsMetric.localized
        case .weight: return CommonKeys.HealthKit.weightMetric.localized
        case .heartRate: return CommonKeys.HealthKit.heartRateMetric.localized
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .weight: return "scalemass"
        case .heartRate: return "heart.fill"
        }
    }

    func unit(for unitSystem: UnitSystem) -> String {
        switch self {
        case .steps: return CommonKeys.HealthKit.stepsUnit.localized
        case .weight:
            switch unitSystem {
            case .metric: return "kg"
            case .imperial: return "lb"
            }
        case .heartRate: return CommonKeys.HealthKit.heartRateUnit.localized
        }
    }

    var color: Color {
        switch self {
        case .steps: return .blue
        case .weight: return .green
        case .heartRate: return .red
        }
    }
}