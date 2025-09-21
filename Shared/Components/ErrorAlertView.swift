import SwiftUI

// MARK: - Error Alert View Component
// Displays error alerts globally across the app
// Used as overlay in ContentView

struct ErrorAlertView: View {
    @State private var errorUIService = ErrorUIService.shared

    var body: some View {
        EmptyView()
            .alert(
                CommonKeys.Onboarding.Common.error.localized,
                isPresented: $errorUIService.showErrorAlert,
                presenting: errorUIService.currentError
            ) { context in
                Button(CommonKeys.ErrorHandling.okButton.localized) {
                    errorUIService.dismissAlert()
                }

                if context.severity == .high || context.severity == .critical {
                    Button(CommonKeys.ErrorHandling.retryButton.localized) {
                        errorUIService.retryLastAction()
                    }
                }
            } message: { context in
                VStack(alignment: .leading, spacing: 8) {
                    Text(context.error.localizedDescription)

                    if let suggestion = context.error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

#Preview {
    ErrorAlertView()
}