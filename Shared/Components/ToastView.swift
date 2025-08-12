import SwiftUI

struct ToastView: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon) }
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
    }
}

struct ToastPresenter<Content: View>: View {
    @Binding var message: String?
    let icon: String?
    let content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
            if let message {
                ToastView(text: message, icon: icon)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { self.message = nil }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: message)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        ToastPresenter(message: $message, icon: "checkmark.circle.fill") {
            content
        }
    }
}


