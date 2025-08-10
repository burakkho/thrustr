//
//  GuideSection.swift
//  SporHocam
//
//  Created by Assistant on 10/8/25.
//

import SwiftUI

struct GuideSection: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
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
