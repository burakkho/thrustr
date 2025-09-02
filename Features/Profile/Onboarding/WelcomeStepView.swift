//
//  WelcomeStepView.swift
//  Thrustr
//
//  Welcome Step - Minimal & Clean Design
//

import SwiftUI

// MARK: - Welcome Step
struct WelcomeStepView: View {
    let onNext: () -> Void
    
    @State private var iconScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Logo - Sade ve büyük
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 120, height: 120)
                .overlay(
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                )
                .scaleEffect(reduceMotion ? 1.0 : iconScale)
                .onAppear {
                    if reduceMotion { iconScale = 1.0 } else {
                        withAnimation(.easeOut(duration: 0.5)) { iconScale = 1.0 }
                    }
                }
            
            VStack(spacing: 12) {
                Text(CommonKeys.Onboarding.welcomeTitle.localized)
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                
                Text(CommonKeys.Onboarding.welcomeSubtitle.localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            .opacity(contentOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    contentOpacity = 1.0
                }
            }
            
            // Özellikler - Daha minimal
            VStack(spacing: 0) {
                MinimalFeatureRow(
                    icon: "figure.strengthtraining.traditional",
                    text: CommonKeys.Onboarding.featureWorkout.localized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                MinimalFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: CommonKeys.Onboarding.featureProgress.localized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                MinimalFeatureRow(
                    icon: "fork.knife",
                    text: CommonKeys.Onboarding.featureNutrition.localized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                MinimalFeatureRow(
                    icon: "target",
                    text: CommonKeys.Onboarding.featureGoals.localized
                )
            }
            .padding(.top, 48)
            .opacity(contentOpacity)
            
            Spacer()
            
            // CTA Button - Daha sade
            PrimaryButton(title: CommonKeys.Onboarding.welcomeStart.localized, icon: "arrow.right") {
                onNext()
            }
            .accessibilityLabel(Text(CommonKeys.Onboarding.welcomeStart.localized))
            .accessibilityHint(Text("Onboarding'a başla"))
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Minimal Feature Row
struct MinimalFeatureRow: View {
    let icon: String
    let text: String
    
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.subheadline)
                .foregroundColor(.green)
                .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                appeared = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeStepView {
        print("Next tapped")
    }
}
