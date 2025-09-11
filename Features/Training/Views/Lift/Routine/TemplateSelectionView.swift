import SwiftUI
import SwiftData

// MARK: - Template Selection View
struct TemplateSelectionView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<LiftWorkout> { $0.isTemplate && !$0.isCustom })
    private var templateWorkouts: [LiftWorkout]
    
    let onTemplateSelected: (LiftWorkout) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Templates list
                if templateWorkouts.isEmpty {
                    emptyStateSection
                } else {
                    templatesListSection
                }
            }
            .navigationTitle("routine.create.fromTemplate".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Choose a Template")
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text("Select a template to customize and save as your own routine")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(theme.colors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(theme.colors.textSecondary)
                .opacity(0.2),
            alignment: .bottom
        )
    }
    
    // MARK: - Templates List Section
    private var templatesListSection: some View {
        ScrollView {
            VStack(spacing: theme.spacing.m) {
                ForEach(templateWorkouts) { template in
                    TemplateSelectionCard(
                        template: template,
                        onSelect: {
                            onTemplateSelected(template)
                            dismiss()
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: theme.spacing.l) {
            Spacer()
            
            VStack(spacing: theme.spacing.m) {
                Image(systemName: "doc.text")
                    .font(.largeTitle)
                    .foregroundColor(theme.colors.textSecondary)
                
                Text("No Templates Available")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("Templates will be loaded automatically when available")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Template Selection Card
private struct TemplateSelectionCard: View {
    @Environment(\.theme) private var theme
    
    let template: LiftWorkout
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                // Header info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.localizedName)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("\(template.exercises?.count ?? 0) \("routine.exercises".localized)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Duration badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(template.estimatedDuration ?? 45) min")
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.s)
                    .padding(.vertical, 4)
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(theme.radius.s)
                }
                
                // Exercise preview
                if !(template.exercises?.isEmpty ?? true) {
                    exercisePreviewSection
                }
                
                // Select button indicator
                HStack {
                    Text("Tap to customize this template")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding()
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(theme.colors.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardButtonStyle())
    }
    
    private var exercisePreviewSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Exercises:")
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], alignment: .leading, spacing: 4) {
                ForEach(Array((template.exercises ?? []).prefix(4)), id: \.id) { exercise in
                    Text("• \(exercise.exerciseName)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)
                }
                
                if (template.exercises?.count ?? 0) > 4 {
                    Text("• +\((template.exercises?.count ?? 0) - 4) more")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
        .padding(.vertical, theme.spacing.s)
        .padding(.horizontal, theme.spacing.s)
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(theme.radius.s)
    }
}

// MARK: - Pressable Card Button Style
private struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    TemplateSelectionView { template in
        print("Selected template: \(template.localizedName)")
    }
}