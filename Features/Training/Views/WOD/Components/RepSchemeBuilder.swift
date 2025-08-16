import SwiftUI

struct RepSchemeBuilder: View {
    @Binding var repScheme: [Int]
    @Environment(\.theme) private var theme
    @State private var showingCustomInput = false
    @State private var customReps = ""
    
    // Common rep schemes
    private let presets: [(name: String, scheme: [Int])] = [
        ("21-15-9", [21, 15, 9]),
        ("21-18-15-12-9-6-3", [21, 18, 15, 12, 9, 6, 3]),
        ("10-9-8-7-6-5-4-3-2-1", [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]),
        ("5 Rounds", [5]),
        ("3 Rounds", [3]),
        ("10 Rounds", [10]),
        ("EMOM 10", [10]),
        ("Chipper", [50, 40, 30, 20, 10])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            HStack {
                Label("Rep Scheme", systemImage: "repeat")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                Spacer()
                
                Menu {
                    ForEach(presets, id: \.name) { preset in
                        Button(preset.name) {
                            repScheme = preset.scheme
                        }
                    }
                } label: {
                    Text("Presets")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            
            // Visual Rep Builder
            if !repScheme.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.m) {
                        ForEach(Array(repScheme.enumerated()), id: \.offset) { index, reps in
                            RepBubble(
                                value: reps,
                                onUpdate: { newValue in
                                    if newValue > 0 {
                                        repScheme[index] = newValue
                                    }
                                },
                                onDelete: {
                                    repScheme.remove(at: index)
                                }
                            )
                        }
                        
                        // Add new rep button
                        Button(action: { showingCustomInput = true }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(theme.colors.accent)
                                Text("Add")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.accent)
                            }
                            .frame(width: 60, height: 80)
                            .background(theme.colors.accent.opacity(0.1))
                            .cornerRadius(theme.radius.m)
                        }
                    }
                    .padding(.vertical, theme.spacing.s)
                }
            } else {
                // Empty state
                Button(action: { showingCustomInput = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add rep scheme")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                    .foregroundColor(theme.colors.textSecondary)
                    .cornerRadius(theme.radius.m)
                }
            }
            
            // Display formatted scheme
            if !repScheme.isEmpty {
                Text(formatRepScheme())
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(theme.spacing.m)
                    .frame(maxWidth: .infinity)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.m)
            }
        }
        .sheet(isPresented: $showingCustomInput) {
            CustomRepInput { value in
                if value > 0 {
                    repScheme.append(value)
                }
            }
        }
    }
    
    private func formatRepScheme() -> String {
        if repScheme.count == 1 {
            return "\(repScheme[0]) Rounds"
        }
        return repScheme.map { String($0) }.joined(separator: "-")
    }
}

// MARK: - Rep Bubble Component
private struct RepBubble: View {
    let value: Int
    let onUpdate: (Int) -> Void
    let onDelete: () -> Void
    
    @Environment(\.theme) private var theme
    @State private var isEditing = false
    @State private var editValue = ""
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            ZStack(alignment: .topTrailing) {
                // Main bubble
                VStack {
                    if isEditing {
                        TextField("", text: $editValue)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .onSubmit {
                                if let newValue = Int(editValue) {
                                    onUpdate(newValue)
                                }
                                isEditing = false
                            }
                    } else {
                        Text("\(value)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .onTapGesture {
                                editValue = String(value)
                                isEditing = true
                            }
                    }
                }
                .frame(width: 60, height: 60)
                .background(theme.colors.accent)
                .foregroundColor(.white)
                .clipShape(Circle())
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.colors.error)
                        .background(Circle().fill(.white))
                }
                .offset(x: 8, y: -8)
            }
            
            // Increment/Decrement buttons
            HStack(spacing: 4) {
                Button(action: { onUpdate(value - 1) }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .disabled(value <= 1)
                
                Button(action: { onUpdate(value + 1) }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Custom Rep Input
private struct CustomRepInput: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    let onAdd: (Int) -> Void
    
    @State private var repValue = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.xl) {
                Text("Add Reps")
                    .font(theme.typography.headline)
                
                TextField("Enter number", text: $repValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                
                HStack(spacing: theme.spacing.m) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                    .foregroundColor(theme.colors.textPrimary)
                    .cornerRadius(theme.radius.m)
                    
                    Button("Add") {
                        if let value = Int(repValue) {
                            onAdd(value)
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                    .disabled(Int(repValue) == nil)
                }
            }
            .padding()
            .presentationDetents([.height(300)])
            .onAppear {
                isFocused = true
            }
        }
    }
}