//
//  WelcomeStepView.swift
//  SporHocam
//
//  Onboarding Welcome Step - Localized & Fixed
//

import SwiftUI

// MARK: - Welcome Step
struct WelcomeStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text(LocalizationKeys.Onboarding.Welcome.title.localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(LocalizationKeys.Onboarding.Welcome.subtitle.localized)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "dumbbell.fill",
                    text: LocalizationKeys.Onboarding.Feature.workout.localized,
                    color: .blue
                )
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: LocalizationKeys.Onboarding.Feature.progress.localized,
                    color: .green
                )
                FeatureRow(
                    icon: "fork.knife",
                    text: LocalizationKeys.Onboarding.Feature.nutrition.localized,
                    color: .orange
                )
                FeatureRow(
                    icon: "target",
                    text: LocalizationKeys.Onboarding.Feature.goals.localized,
                    color: .red
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: onNext) {
                Text(LocalizationKeys.Onboarding.Welcome.start.localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeStepView {
        print("Next tapped")
    }
}
