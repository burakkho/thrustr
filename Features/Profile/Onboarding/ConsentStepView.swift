import SwiftUI

struct ConsentStepView: View {
    @Binding var data: OnboardingData
    let onNext: () -> Void
    
    @State private var termsAccepted = false
    @State private var privacyAccepted = false
    @State private var marketingOptIn = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("onboarding.consent.title".localized)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("onboarding.consent.subtitle".localized)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 16) {
                    ConsentRow(
                        title: "onboarding.consent.terms.title".localized,
                        description: "onboarding.consent.terms.desc".localized,
                        linkTitle: "onboarding.consent.viewTerms".localized,
                        linkAction: openTerms,
                        isOn: $termsAccepted
                    )
                    ConsentRow(
                        title: "onboarding.consent.privacy.title".localized,
                        description: "onboarding.consent.privacy.desc".localized,
                        linkTitle: "onboarding.consent.viewPrivacy".localized,
                        linkAction: openPrivacy,
                        isOn: $privacyAccepted
                    )
                    Toggle("onboarding.consent.marketing".localized, isOn: $marketingOptIn)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            PrimaryButton(title: "onboarding.continue".localized, icon: "arrow.right", isEnabled: canContinue) {
                data.consentAccepted = true
                data.marketingOptIn = marketingOptIn
                data.consentTimestamp = Date()
                onNext()
            }
            .disabled(!canContinue)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $showSheet) {
            sheet
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            // Sync local toggles with persisted onboarding data when restoring progress
            termsAccepted = data.consentAccepted
            privacyAccepted = data.consentAccepted
            marketingOptIn = data.marketingOptIn
        }
    }
    
    private var canContinue: Bool { termsAccepted && privacyAccepted }
    
    private func openTerms() {
        present(document: LegalDocumentView(title: "onboarding.consent.viewTerms".localized, resourceBaseName: "terms"))
    }
    
    private func openPrivacy() {
        present(document: LegalDocumentView(title: "onboarding.consent.viewPrivacy".localized, resourceBaseName: "privacy"))
    }
    
    @State private var showSheet = false
    @State private var sheet: AnyView = AnyView(EmptyView())
    
    private func present(document: some View) {
        sheet = AnyView(document)
        showSheet = true
    }
    
}

private struct ConsentRow: View {
    let title: String
    let description: String
    let linkTitle: String
    let linkAction: () -> Void
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            Button(action: linkAction) {
                HStack(spacing: 6) {
                    Text(linkTitle).font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


