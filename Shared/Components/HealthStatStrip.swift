import SwiftUI

struct DashboardHealthStatStripItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(color: Color.shadowLight, radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title) \(value)"))
    }
}

struct DashboardHealthStatStripPlaceholder: View {
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .foregroundColor(.blue)
                .font(.title2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderPrimary, lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.shadowLight, radius: 3, y: 1)
    }
}


