//
//  QuickStatCard.swift
//  SporHocam
//
//  Created by Assistant on 10/8/25.
//

import SwiftUI

struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
