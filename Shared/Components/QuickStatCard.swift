//
//  QuickStatCard.swift
//  SporHocam
//
//  Created by Assistant on 10/8/25.
//

import SwiftUI

struct QuickStatCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    VStack {
        QuickStatCard(
            icon: "figure.walk",
            title: "Bugün",
            value: "8,432",
            subtitle: "adım",
            color: .blue
        )
        
        QuickStatCard(
            icon: "flame.fill",
            title: "Kalori",
            value: "2,150",
            subtitle: "kcal",
            color: .orange
        )
    }
    .padding()
}
