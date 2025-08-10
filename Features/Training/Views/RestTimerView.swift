import SwiftUI
import AVFoundation

// MARK: - Rest Timer View
struct RestTimerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let duration: Int // seconds
    @State private var timeRemaining: Int
    @State private var isActive = false
    @State private var timer: Timer?
    
    // Audio feedback
    @State private var audioPlayer: AVAudioPlayer?
    
    init(duration: Int) {
        self.duration = duration
        self._timeRemaining = State(initialValue: duration)
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(duration - timeRemaining) / Double(duration)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // Timer circle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 250, height: 250)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            timeRemaining <= 10 ? Color.red : Color.blue,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    // Timer text
                    VStack(spacing: 8) {
                        Text(formatTime(timeRemaining))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                        
                        Text("kalan süre")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Quick time adjustments
                HStack(spacing: 20) {
                    TimeAdjustButton(title: "-15s", action: { adjustTime(-15) })
                    TimeAdjustButton(title: "+15s", action: { adjustTime(15) })
                    TimeAdjustButton(title: "+30s", action: { adjustTime(30) })
                }
                
                // Control buttons
                HStack(spacing: 20) {
                    // Reset button
                    Button("Sıfırla") {
                        resetTimer()
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Play/Pause button
                    Button(isActive ? "Duraklat" : "Başlat") {
                        toggleTimer()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(isActive ? Color.orange : Color.blue)
                    .cornerRadius(10)
                    
                    // Skip button
                    Button("Geç") {
                        completeRest()
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Dinlenme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupAudio()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func adjustTime(_ adjustment: Int) {
        let newTime = max(0, timeRemaining + adjustment)
        timeRemaining = newTime
        
        if timeRemaining == 0 {
            completeRest()
        }
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = duration
        isActive = false
    }
    
    private func toggleTimer() {
        if isActive {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isActive = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Warning sounds
                if timeRemaining == 10 {
                    playSound(name: "warning")
                } else if timeRemaining == 3 || timeRemaining == 2 || timeRemaining == 1 {
                    playSound(name: "tick")
                } else if timeRemaining == 0 {
                    playSound(name: "complete")
                    completeRest()
                }
            }
        }
    }
    
    private func stopTimer() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func completeRest() {
        stopTimer()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        dismiss()
    }
    
    private func setupAudio() {
        // Setup audio session for timer sounds
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func playSound(name: String) {
        // System sounds - you can replace with custom sounds
        switch name {
        case "warning":
            AudioServicesPlaySystemSound(1005) // SMS received sound
        case "tick":
            AudioServicesPlaySystemSound(1104) // SMS received sound
        case "complete":
            AudioServicesPlaySystemSound(1025) // SMS received sound
        default:
            break
        }
        
        // Also provide haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        switch name {
        case "warning":
            feedback.notificationOccurred(.warning)
        case "complete":
            feedback.notificationOccurred(.success)
        default:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}

// MARK: - Time Adjust Button
struct TimeAdjustButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Rest Timer Preset Selector
struct RestTimerPresetView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onTimeSelected: (Int) -> Void
    
    private let presetTimes = [
        (title: "Kısa Dinlenme", subtitle: "Hafif egzersizler için", duration: 30),
        (title: "Orta Dinlenme", subtitle: "Orta ağırlık egzersizleri", duration: 60),
        (title: "Uzun Dinlenme", subtitle: "Ağır compound hareketler", duration: 90),
        (title: "Güç Dinlenmesi", subtitle: "1RM ve maksimal setler", duration: 180),
        (title: "Özel", subtitle: "Manuel süre ayarla", duration: -1)
    ]
    
    @State private var customMinutes = 2
    @State private var showingCustom = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Dinlenme Süresi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Egzersiz türüne göre uygun dinlenme süresini seç")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Preset options
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(presetTimes, id: \.duration) { preset in
                            PresetTimeButton(
                                title: preset.title,
                                subtitle: preset.subtitle,
                                duration: preset.duration
                            ) {
                                if preset.duration == -1 {
                                    showingCustom = true
                                } else {
                                    onTimeSelected(preset.duration)
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustom) {
                CustomTimePickerView(
                    initialMinutes: customMinutes,
                    onTimeSelected: { minutes in
                        onTimeSelected(minutes * 60)
                        dismiss()
                    }
                )
            }
        }
    }
}

// MARK: - Preset Time Button
struct PresetTimeButton: View {
    let title: String
    let subtitle: String
    let duration: Int // -1 for custom
    let action: () -> Void
    
    var durationText: String {
        if duration == -1 {
            return "Custom"
        } else if duration < 60 {
            return "\(duration)s"
        } else {
            let minutes = duration / 60
            let seconds = duration % 60
            return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(durationText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Time Picker
struct CustomTimePickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let initialMinutes: Int
    let onTimeSelected: (Int) -> Void
    
    @State private var selectedMinutes: Int
    
    init(initialMinutes: Int, onTimeSelected: @escaping (Int) -> Void) {
        self.initialMinutes = initialMinutes
        self.onTimeSelected = onTimeSelected
        self._selectedMinutes = State(initialValue: initialMinutes)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Özel Dinlenme Süresi")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Time picker
                VStack(spacing: 20) {
                    HStack {
                        Text("Süre:")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(1...10, id: \.self) { minute in
                            Text("\(minute) dakika")
                                .tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 150)
                }
                
                Spacer()
                
                // Confirm button
                Button("Süreyi Ayarla") {
                    onTimeSelected(selectedMinutes)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RestTimerView(duration: 90)
}
