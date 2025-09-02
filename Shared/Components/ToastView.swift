import SwiftUI

struct ToastView: View {
    let text: String
    var icon: String? = nil
    var type: ToastType = .info

    var body: some View {
        HStack(spacing: 8) {
            if let icon { 
                Image(systemName: icon)
                    .foregroundColor(type.iconColor)
            }
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .foregroundColor(type.textColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(type.backgroundColor)
        .clipShape(Capsule())
        .shadow(radius: 4)
    }
}

enum ToastType {
    case success, error, warning, info
    
    var backgroundColor: Color {
        switch self {
        case .success: return .green.opacity(0.9)
        case .error: return .red.opacity(0.9) 
        case .warning: return .orange.opacity(0.9)
        case .info: return Color(.systemGray6)
        }
    }
    
    var textColor: Color {
        switch self {
        case .success, .error, .warning: return .white
        case .info: return .primary
        }
    }
    
    var iconColor: Color {
        return textColor
    }
}

struct ToastPresenter<Content: View>: View {
    @Binding var message: String?
    let icon: String?
    let type: ToastType
    let content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
            if let message {
                ToastView(text: message, icon: icon, type: type)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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
    let type: ToastType
    let icon: String?
    
    init(message: Binding<String?>, type: ToastType = .success, icon: String? = nil) {
        self._message = message
        self.type = type
        self.icon = icon ?? type.defaultIcon
    }
    
    func body(content: Content) -> some View {
        ToastPresenter(message: $message, icon: icon, type: type) {
            content
        }
    }
}

extension ToastType {
    var defaultIcon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

extension View {
    func toast(_ message: Binding<String?>, type: ToastType = .success, icon: String? = nil) -> some View {
        modifier(ToastModifier(message: message, type: type, icon: icon))
    }
}


