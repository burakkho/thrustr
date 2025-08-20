import SwiftUI

struct TimerControls: View {
    @Environment(\.theme) private var theme
    let timerState: TimerState
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onReset: () -> Void
    
    enum TimerState: Int {
        case stopped = 0, countdown = 1, running = 2, paused = 3, completed = 4
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            switch timerState {
            case .stopped:
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.success)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                }
                
            case .running:
                Button(action: onPause) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.warning)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                }
                
                Button(action: onStop) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.error)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                }
                
            case .paused:
                Button(action: onResume) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.success)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                }
                
                Button(action: onStop) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.error)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                }
                
            case .completed:
                Button(action: onReset) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                }
                
            case .countdown:
                // During countdown, show minimal controls
                Button(action: onStop) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Cancel")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.error)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.m)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TimerControls(
            timerState: .stopped,
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {},
            onReset: {}
        )
        
        TimerControls(
            timerState: .running,
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {},
            onReset: {}
        )
        
        TimerControls(
            timerState: .paused,
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {},
            onReset: {}
        )
    }
    .padding()
}
