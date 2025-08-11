import SwiftUI

struct PressableStyle: ButtonStyle {
    let pressedScale: CGFloat
    let duration: Double
    let pressedOpacity: Double

    init(pressedScale: CGFloat = 0.95, duration: Double = 0.10, pressedOpacity: Double = 0.85) {
        self.pressedScale = pressedScale
        self.duration = duration
        self.pressedOpacity = pressedOpacity
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.easeInOut(duration: duration), value: configuration.isPressed)
    }
}


