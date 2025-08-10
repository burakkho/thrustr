//
//  WelcomeStepView.swift
//  SporHocam
//
//  Welcome Step - Minimal & Clean Design
//

import SwiftUI

// MARK: - Welcome Step
struct WelcomeStepView: View {
    let onNext: () -> Void
    
    @State private var iconScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Icon - Sade ve büyük
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "figure.run")
                        .font(.system(size: 50, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                )
                .scaleEffect(iconScale)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.5)) {
                        iconScale = 1.0
                    }
                }
            
            VStack(spacing: 12) {
                Text(LocalizationKeys.Onboarding.Welcome.title.localized)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text(LocalizationKeys.Onboarding.Welcome.subtitle.localized)
                    .font(.system(size: 17, weight: .regular))
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
                    text: LocalizationKeys.Onboarding.Feature.workout.localized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                MinimalFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: LocalizationKeys.Onboarding.Feature.progress.localized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                MinimalFeatureRow(
                    icon: "fork.knife",
                    text: LocalizationKeys.Onboarding.Feature.nutrition.localized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                MinimalFeatureRow(
                    icon: "target",
                    text: LocalizationKeys.Onboarding.Feature.goals.localized
                )
            }
            .padding(.top, 48)
            .opacity(contentOpacity)
            
            Spacer()
            
            // CTA Button - Daha sade
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text(LocalizationKeys.Onboarding.Welcome.start.localized)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
            }
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
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.blue)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .medium))
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
