//
//  OnboardingDesignSystem.swift
//  Thrustr
//
//  Onboarding Design System - Modern Visual Components
//

import SwiftUI

// MARK: - Design Constants
struct OnboardingDesign {
    // Colors
    static let primaryColor = Color.appPrimary
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "007AFF").opacity(0.05),
            Color(hex: "5856D6").opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardBackground = Color(.systemBackground)
    static let cardShadowColor = Color.black.opacity(0.08)
    
    // Spacing
    static let cornerRadius: CGFloat = 20
    static let cardCornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 56
    
    // Animation
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let easeAnimation = Animation.easeInOut(duration: 0.3)
}

// MARK: - Animated Number Display
struct AnimatedNumberView: View {
    let value: Int
    let suffix: String
    let color: Color
    
    @State private var animatedValue: Int = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(animatedValue)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(suffix)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(color.opacity(0.7))
                .offset(y: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedValue = value
            }
        }
    }
}

// MARK: - Premium Card Component
struct PremiumCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.cardCornerRadius)
                    .fill(OnboardingDesign.cardBackground)
                    .shadow(color: OnboardingDesign.cardShadowColor, radius: 10, x: 0, y: 4)
            )
    }
}

// MARK: - Gradient Button
struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isEnabled: Bool
    
    init(title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: OnboardingDesign.buttonHeight)
            .background(
                Group {
                    if isEnabled {
                        OnboardingDesign.primaryGradient
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(OnboardingDesign.cardCornerRadius)
            .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.96 : 1.0))
            .shadow(color: isEnabled ? Color(hex: "007AFF").opacity(0.3) : .clear,
                   radius: reduceMotion ? 0 : (isPressed ? 5 : 10), y: reduceMotion ? 0 : (isPressed ? 2 : 5))
        }
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            let animation = reduceMotion ? nil : OnboardingDesign.springAnimation
            withAnimation(animation) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Primary Button (Solid, no gradient)
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isEnabled: Bool
    
    init(title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: OnboardingDesign.buttonHeight)
            .background(isEnabled ? OnboardingDesign.primaryColor : Color.gray.opacity(0.4))
            .cornerRadius(OnboardingDesign.cardCornerRadius)
            .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.98 : 1.0))
            .shadow(color: isEnabled ? Color.black.opacity(0.08) : .clear, radius: 6, y: 3)
        }
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            let animation = reduceMotion ? nil : OnboardingDesign.springAnimation
            withAnimation(animation) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - Feature Card with Animation
struct AnimatedFeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    let delay: Double
    
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                )
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .opacity(appeared ? 1 : 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.1), radius: 5, y: 2)
        )
        .offset(x: reduceMotion ? 0 : (appeared ? 0 : -50))
        .opacity(reduceMotion ? 1 : (appeared ? 1 : 0))
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(OnboardingDesign.springAnimation.delay(delay)) {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Interactive Progress Bar
enum OnboardingProgressBarStyle { case regular, compact }

struct InteractiveProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    var style: OnboardingProgressBarStyle = .compact
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        switch style {
        case .regular:
            regularBody
        case .compact:
            compactBody
        }
    }
    
    // Minimal/compact variant
    private var compactBody: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track (very thin)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.18))
                    .frame(height: 4)
                // Progress (solid brand color)
                RoundedRectangle(cornerRadius: 3)
                    .fill(OnboardingDesign.primaryColor)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(reduceMotion ? nil : OnboardingDesign.easeAnimation, value: progress)
                // Minimal dots overlay
                HStack(spacing: 0) {
                    ForEach(1...totalSteps, id: \.self) { step in
                        let isFilled = CGFloat(step) <= CGFloat(currentStep)
                        Circle()
                            .fill(isFilled ? OnboardingDesign.primaryColor : Color.clear)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.35), lineWidth: isFilled ? 0 : 1)
                            )
                            .frame(width: 6, height: 6)
                        if step < totalSteps { Spacer() }
                    }
                }
                .frame(height: 4)
            }
        }
        .frame(height: 10)
        .padding(.horizontal)
    }
    
    // Original/regular variant
    private var regularBody: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(OnboardingDesign.primaryGradient)
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(reduceMotion ? nil : OnboardingDesign.springAnimation, value: progress)
                    HStack(spacing: 0) {
                        ForEach(0..<totalSteps, id: \.self) { step in
                            Circle()
                                .fill(step < currentStep ? Color.white : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(step < currentStep ? Color.clear : Color.white, lineWidth: 2)
                                )
                                .scaleEffect(reduceMotion ? 1.0 : (step == currentStep - 1 ? 1.2 : 1.0))
                                .animation(reduceMotion ? nil : OnboardingDesign.springAnimation, value: currentStep)
                            if step < totalSteps - 1 { Spacer() }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .frame(height: 20)
            HStack {
                Text("\(CommonKeys.Onboarding.step.localized) \(currentStep) / \(totalSteps)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(progress * 100))% \(CommonKeys.Onboarding.Common.completed.localized)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: OnboardingDesign.cardShadowColor, radius: 5, y: 2)
        )
    }
}

// MARK: - Visual Input Field
struct VisualInputField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    
    @FocusState private var isFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            HStack {
                TextField(placeholder, text: $text)
                    .font(.headline)
                    .focused($isFocused)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color(hex: "007AFF") : Color.clear, lineWidth: 2)
                    )
            )
            .dynamicTypeSize(.medium ... .accessibility5)
        }
    }
}

// MARK: - Visual Slider Component
struct VisualSlider: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(value))")
                    .font(.title)
                    .foregroundStyle(gradient)
                + Text(" \(unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Progress
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(gradient)
                        .frame(width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), height: 8)
                }
                .frame(height: 8)
            }
            .overlay(
                Slider(value: $value, in: range, step: step)
                    .opacity(0.01)
                    .accessibilityLabel(Text(title))
                    .accessibilityValue(Text("\(Int(value)) \(unit)"))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: OnboardingDesign.cardShadowColor, radius: 8, y: 4)
        )
        .dynamicTypeSize(.medium ... .accessibility5)
    }
}

// MARK: - Selection Card
struct SelectionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? [color, color.opacity(0.7)] : [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(isSelected ? .white : color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Circle()
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(color)
                            .frame(width: 16, height: 16)
                            .opacity(isSelected ? 1 : 0)
                            .scaleEffect(isSelected ? 1 : 0.5)
                            .animation(OnboardingDesign.springAnimation, value: isSelected)
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? color.opacity(0.2) : OnboardingDesign.cardShadowColor,
                           radius: isSelected ? 12 : 6, y: isSelected ? 6 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(reduceMotion ? 1.0 : (isPressed ? 0.98 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            let animation = reduceMotion ? nil : OnboardingDesign.springAnimation
            withAnimation(animation) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
