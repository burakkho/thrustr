import SwiftUI

struct CountdownOverlay: View {
    @Environment(\.theme) private var theme
    @Binding var isShowing: Bool
    @Binding var value: Int
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(value > 0 ? "\(value)" : "GO!")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(value > 0 ? 1.0 : 1.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
                    
                    Text("Get Ready!")
                        .font(theme.typography.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Text("Background Content")
                .font(.title)
        }
        
        CountdownOverlay(
            isShowing: .constant(true),
            value: .constant(3)
        )
    }
}
