import SwiftUI

// MARK: - Generic Editable Row Component
struct EditableRow<Content: View>: View {
    @Environment(\.theme) private var theme
    
    // Content
    let content: () -> Content
    
    // Actions
    let onRemove: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onEdit: (() -> Void)?
    
    // Configuration
    let swipeToDelete: Bool
    let confirmDelete: Bool
    let deleteTitle: String
    let deleteMessage: String
    
    // Internal state
    @State private var showingDeleteAlert = false
    
    init(
        @ViewBuilder content: @escaping () -> Content,
        onRemove: @escaping () -> Void,
        onMoveUp: (() -> Void)? = nil,
        onMoveDown: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        swipeToDelete: Bool = true,
        confirmDelete: Bool = true,
        deleteTitle: String = "Delete Item",
        deleteMessage: String = "Are you sure you want to delete this item?"
    ) {
        self.content = content
        self.onRemove = onRemove
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        self.onEdit = onEdit
        self.swipeToDelete = swipeToDelete
        self.confirmDelete = confirmDelete
        self.deleteTitle = deleteTitle
        self.deleteMessage = deleteMessage
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Main content
            content()
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if swipeToDelete {
                Button("Delete") {
                    handleDelete()
                }
                .tint(theme.colors.error)
            }
            
            if let onEdit = onEdit {
                Button("Edit") {
                    onEdit()
                }
                .tint(theme.colors.accent)
            }
        }
        .alert(deleteTitle, isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onRemove()
            }
        } message: {
            Text(deleteMessage)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: theme.spacing.s) {
            // Edit button
            if let onEdit = onEdit {
                ActionButton(
                    icon: "pencil",
                    color: theme.colors.accent,
                    action: onEdit
                )
            }
            
            // Move up button
            if let onMoveUp = onMoveUp {
                ActionButton(
                    icon: "chevron.up",
                    color: theme.colors.accent,
                    action: onMoveUp
                )
            }
            
            // Move down button
            if let onMoveDown = onMoveDown {
                ActionButton(
                    icon: "chevron.down",
                    color: theme.colors.accent,
                    action: onMoveDown
                )
            }
            
            // Remove button
            ActionButton(
                icon: "trash",
                color: theme.colors.error,
                action: handleDelete
            )
        }
    }
    
    private func handleDelete() {
        if confirmDelete {
            showingDeleteAlert = true
        } else {
            onRemove()
        }
    }
}

// MARK: - Action Button Helper
private struct ActionButton: View {
    @Environment(\.theme) private var theme
    
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

// MARK: - Specialized Exercise Edit Row
struct ExerciseEditRow: View {
    let exercise: LiftExercise
    let onRemove: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    var body: some View {
        EditableRow(
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Sets and reps will be entered during workout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            },
            onRemove: onRemove,
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            deleteTitle: "Remove Exercise",
            deleteMessage: "Are you sure you want to remove this exercise from your routine?"
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        // Basic example
        EditableRow(
            content: {
                VStack(alignment: .leading) {
                    Text("Sample Item")
                        .font(.headline)
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            },
            onRemove: { print("Remove") },
            onMoveUp: { print("Move up") },
            onMoveDown: { print("Move down") }
        )
        
        // Exercise example
        ExerciseEditRow(
            exercise: LiftExercise(
                exerciseId: UUID(),
                exerciseName: "Bench Press",
                orderIndex: 0
            ),
            onRemove: { print("Remove exercise") },
            onMoveUp: { print("Move up") },
            onMoveDown: nil
        )
    }
    .padding()
}