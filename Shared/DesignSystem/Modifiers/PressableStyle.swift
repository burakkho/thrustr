import SwiftUI

struct PressableStyle: ButtonStyle {
    let pressedScale: CGFloat
    let duration: Double

    init(pressedScale: CGFloat = 0.98, duration: Double = 0.12) {
        self.pressedScale = pressedScale
        self.duration = duration
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.easeOut(duration: duration), value: configuration.isPressed)
    }
}


