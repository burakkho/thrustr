import SwiftUI
import SwiftData

// MARK: - Main Training View
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    
    @State private var showingNewWorkout = false
    @State private var selectedTab = 0
    @State private var workoutToShow: Workout?
    @State private var showWorkoutDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment Control
                Picker("Training Options", selection: $selectedTab) {
                    Text("Geçmiş").tag(0)
                    Text("Aktif").tag(1)
                    Text("Şablonlar").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case 0:
                    WorkoutHistoryView(workouts: workouts)
                case 1:
                    ActiveWorkoutView(onWorkoutTap: { workout in
                        workoutToShow = workout
                        showWorkoutDetail = true
                    })
                case 2:
                    WorkoutTemplatesView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Antrenman")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewWorkout = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingNewWorkout) {
                NewWorkoutView { createdWorkout in
                    // Callback when workout is created
                    workoutToShow = createdWorkout
                    showWorkoutDetail = true
                }
            }
            .fullScreenCover(isPresented: $showWorkoutDetail) {
                if let workout = workoutToShow {
                    WorkoutDetailView(workout: workout)
                }
            }
        }
    }
}

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    let workouts: [Workout]
    
    var completedWorkouts: [Workout] {
        workouts.filter { $0.isCompleted }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if completedWorkouts.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Henüz antrenman yok")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("İlk antrenmanını başlatmak için + butonuna bas!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                } else {
                    ForEach(completedWorkouts) { workout in
                        WorkoutHistoryCard(workout: workout)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Workout History Card
struct WorkoutHistoryCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name ?? "Antrenman")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.durationInMinutes) dk")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(workout.totalSets) set")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Parts summary
            HStack(spacing: 8) {
                ForEach(workout.parts.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { part in
                    PartTypeChip(partType: WorkoutPartType(rawValue: part.type) ?? .strength)
                }
                
                if workout.parts.isEmpty {
                    Text("Bölüm yok")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Volume info
            if workout.totalVolume > 0 {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("Toplam Volume: \(Int(workout.totalVolume)) kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Part Type Chip
struct PartTypeChip: View {
    let partType: WorkoutPartType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: partType.icon)
                .font(.caption)
            Text(partType.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(partColor.opacity(0.2))
        .foregroundColor(partColor)
        .cornerRadius(8)
    }
    
    private var partColor: Color {
        switch partType {
        case .strength: return .blue
        case .conditioning: return .red
        case .accessory: return .green
        case .warmup: return .orange
        case .functional: return .purple
        }
    }
}

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { !$0.isCompleted }) private var activeWorkouts: [Workout]
    
    let onWorkoutTap: (Workout) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let activeWorkout = activeWorkouts.first {
                    // Active workout exists
                    ActiveWorkoutCard(workout: activeWorkout) {
                        onWorkoutTap(activeWorkout)
                    }
                } else {
                    // No active workout
                    VStack(spacing: 16) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Aktif Antrenman Yok")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Yeni bir antrenman başlatmak için + butonuna bas")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Antrenman Başlat") {
                            startNewWorkout()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.top, 80)
                }
            }
            .padding()
        }
    }
    
    private func startNewWorkout() {
        let newWorkout = Workout(name: "Antrenman")
        modelContext.insert(newWorkout)
        onWorkoutTap(newWorkout)
    }
}

// MARK: - Active Workout Card
struct ActiveWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with timer
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktif Antrenman")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(workout.name ?? "Antrenman")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Süre")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(Int(currentTime.timeIntervalSince(workout.startTime))))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatItem(title: "Bölüm", value: "\(workout.parts.count)")
                StatItem(title: "Set", value: "\(workout.totalSets)")
                StatItem(title: "Volume", value: "\(Int(workout.totalVolume))kg")
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Devam Et") {
                    onTap()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                
                Button("Bitir") {
                    workout.finishWorkout()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 2)
        )
        .cornerRadius(12)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Workout Templates View
struct WorkoutTemplatesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Şablonlar")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Hazır antrenman şablonları yakında eklenecek!")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 100)
        }
        .padding()
    }
}

// MARK: - New Workout View
struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var workoutName = ""
    let onWorkoutCreated: (Workout) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Yeni Antrenman")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Antrenmanına nasıl başlamak istiyorsun?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Workout name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Antrenman Adı")
                        .font(.headline)
                    
                    TextField("Örn: Push Day, Bacak Günü", text: $workoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Quick start options
                VStack(spacing: 12) {
                    Text("Hızlı Başlangıç")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        QuickStartButton(
                            title: "Boş Antrenman",
                            subtitle: "Sıfırdan başla",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            startEmptyWorkout()
                        }
                        
                        QuickStartButton(
                            title: "Fonksiyonel Antrenman",
                            subtitle: "Functional fitness movements",
                            icon: "figure.strengthtraining.functional",
                            color: .green
                        ) {
                            startFunctionalWorkout()
                        }
                        
                        QuickStartButton(
                            title: "Kardiyo",
                            subtitle: "Kardiyovasküler antrenman",
                            icon: "heart.fill",
                            color: .red
                        ) {
                            startCardioWorkout()
                        }
                    }
                    .padding(.horizontal)
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
        }
    }
    
    private func startEmptyWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? "Antrenman" : workoutName)
        modelContext.insert(workout)
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
    
    private func startFunctionalWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? "Fonksiyonel Antrenman" : workoutName)
        
        // Add functional training part
        let _ = workout.addPart(name: "Fonksiyonel", type: .functional)
        
        modelContext.insert(workout)
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
    
    private func startCardioWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? "Kardiyo" : workoutName)
        
        // Add cardio part
        let _ = workout.addPart(name: "Kardiyo", type: .conditioning)
        
        modelContext.insert(workout)
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
}

// MARK: - Quick Start Button
struct QuickStartButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TrainingView()
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}
