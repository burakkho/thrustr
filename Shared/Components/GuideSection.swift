//
//  GuideSection.swift
//  SporHocam
//
//  Created by Assistant on 10/8/25.
//

import SwiftUI

// Local button style to avoid project file updates
struct PressableStyle: ButtonStyle {
    let pressedScale: CGFloat
    let duration: Double
    init(pressedScale: CGFloat = 0.98, duration: Double = 0.12) {
        self.pressedScale = pressedScale
        self.duration = duration
    }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.easeOut(duration: duration), value: configuration.isPressed)
    }
}

struct GuideSection: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: theme.spacing.m) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                }
                
                // Content
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.colors.textSecondary)
                    .font(.caption)
            }
            .cardStyle()
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(description))
    }
}

#Preview {
    VStack {
        GuideSection(
            title: "Antrenman Başlat",
            icon: "dumbbell.fill",
            description: "Yeni antrenman oluştur ve egzersizlerini takip et",
            color: .blue
        ) {
            print("Antrenman başlat tıklandı")
        }
        
        GuideSection(
            title: "Beslenme Takibi",
            icon: "fork.knife",
            description: "Günlük kalori ve makro besinlerini kaydet",
            color: .orange
        ) {
            print("Beslenme takibi tıklandı")
        }
        
        GuideSection(
            title: "Profil Ayarları",
            icon: "person.circle.fill",
            description: "Kişisel bilgilerini ve hedeflerini güncelle",
            color: .green
        ) {
            print("Profil ayarları tıklandı")
        }
    }
    .padding()
}
