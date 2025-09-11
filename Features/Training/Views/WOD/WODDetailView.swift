import SwiftUI
import SwiftData

struct WODDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Query private var user: [User]
    
    let wod: WOD
    @State private var selectedWeights: [UUID: Double] = [:]
    @State private var isRX = true
    @State private var showingTimer = false
    @State private var showingHistory = false
    @State private var showingEdit = false
    @State private var showingShare = false
    
    private var currentUser: User? {
        user.first
    }
    
    private var wodResults: [WODResult] {
        (wod.results ?? []).sorted { $0.completedAt > $1.completedAt }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    headerCard
                    movementsSection
                    rxScaledToggle
                    resultsSection
                    startButton
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .fullScreenCover(isPresented: $showingTimer) {
                EnhancedWODTimerView(
                    wod: wod,
                    movements: (wod.movements ?? []).map { movement in
                        let updatedMovement = movement
                        updatedMovement.userWeight = selectedWeights[movement.id]
                        updatedMovement.isRX = isRX
                        return updatedMovement
                    },
                    isRX: isRX
                )
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    WODHistoryView()
                        .navigationTitle("WOD History")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(CommonKeys.Onboarding.Common.done.localized) { 
                                    showingHistory = false 
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingShare) {
                WODShareView(wod: wod, result: nil)
            }
            .sheet(isPresented: $showingEdit) {
                // WOD edit view would go here
                Text("Edit WOD - Coming Soon")
            }
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            headerTitleRow
            repSchemeView
            timeCapView
            personalRecordView
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }
    
    private var headerTitleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(wod.wodType.displayName)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                Text(wod.name)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            Spacer()
            
            Button(action: toggleFavorite) {
                Image(systemName: wod.isFavorite ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(wod.isFavorite ? theme.colors.warning : theme.colors.textSecondary)
            }
        }
    }
    
    private var repSchemeView: some View {
        Group {
            if !wod.repScheme.isEmpty {
                HStack {
                    Image(systemName: "repeat")
                        .foregroundColor(theme.colors.accent)
                    Text(wod.formattedRepScheme)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    private var timeCapView: some View {
        Group {
            if let timeCap = wod.formattedTimeCap {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(theme.colors.warning)
                    Text(timeCap)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.warning)
                }
            }
        }
    }
    
    private var personalRecordView: some View {
        Group {
            if let pr = wod.personalRecord {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(theme.colors.success)
                    Text("PR: \(pr.displayScore)")
                        .font(theme.typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.success)
                    
                    if pr.isRX {
                        Text("(RX)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.success)
                    }
                }
                .padding(theme.spacing.m)
                .frame(maxWidth: .infinity)
                .background(theme.colors.success.opacity(0.1))
                .cornerRadius(theme.radius.m)
            }
        }
    }
    
    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Movements")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
            
            ForEach(Array((wod.movements ?? []).enumerated()), id: \.element.id) { index, movement in
                MovementCard(
                    movement: movement,
                    index: index + 1,
                    userGender: currentUser?.gender,
                    isRX: $isRX,
                    selectedWeight: Binding(
                        get: { selectedWeights[movement.id] },
                        set: { selectedWeights[movement.id] = $0 }
                    )
                )
            }
        }
    }
    
    private var rxScaledToggle: some View {
        HStack {
            Text("Mode:")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            Picker("Mode", selection: $isRX) {
                Text("RX").tag(true)
                Text("Scaled").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
    private var resultsSection: some View {
        Group {
            if !wodResults.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    Text("Recent Results")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    ForEach(wodResults.prefix(3)) { result in
                        ResultRow(result: result, wod: wod)
                    }
                }
            }
        }
    }
    
    private var startButton: some View {
        VStack(spacing: theme.spacing.m) {
            Button(action: { showingTimer = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start WOD")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.accent)
                .foregroundColor(.white)
                .cornerRadius(theme.radius.m)
            }
            
            HStack(spacing: theme.spacing.m) {
                Button(action: { showingShare = true }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Share")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                    .foregroundColor(theme.colors.textPrimary)
                    .cornerRadius(theme.radius.m)
                }
                
                Button(action: { showingHistory = true }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                    .foregroundColor(theme.colors.textPrimary)
                    .cornerRadius(theme.radius.m)
                }
            }
            
            if wod.isCustom {
                Button(action: { showingEdit = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit WOD")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.colors.backgroundSecondary)
                    .foregroundColor(theme.colors.textPrimary)
                    .cornerRadius(theme.radius.m)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(CommonKeys.Onboarding.Common.close.localized) { 
                dismiss() 
            }
        }
    }
    
    private func toggleFavorite() {
        wod.isFavorite.toggle()
        try? modelContext.save()
        HapticManager.shared.impact(.light)
    }
}

// MARK: - Movement Card
private struct MovementCard: View {
    let movement: WODMovement
    let index: Int
    let userGender: String?
    @Binding var isRX: Bool
    @Binding var selectedWeight: Double?
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    @State private var weightText = ""
    
    private var rxWeight: String? {
        movement.rxWeight(for: userGender)
    }
    
    private var scaledWeight: String? {
        movement.scaledWeight(for: userGender)
    }
    
    private var displayRxWeight: String? {
        guard let rx = rxWeight else { return nil }
        // Parse weight value and convert to user's preferred units
        let numbers = rx.filter { "0123456789.".contains($0) }
        if let weight = Double(numbers) {
            return UnitsFormatter.formatWeight(kg: weight, system: unitSettings.unitSystem)
        }
        return rx // Fallback to original string
    }
    
    private var displayScaledWeight: String? {
        guard let scaled = scaledWeight else { return nil }
        // Parse weight value and convert to user's preferred units
        let numbers = scaled.filter { "0123456789.".contains($0) }
        if let weight = Double(numbers) {
            return UnitsFormatter.formatWeight(kg: weight, system: unitSettings.unitSystem)
        }
        return scaled // Fallback to original string
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Text("\(index).")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(movement.displayText)
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    if let displayRx = displayRxWeight {
                        HStack(spacing: theme.spacing.s) {
                            Text("RX: \(displayRx)")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.accent)
                            
                            if let displayScaled = displayScaledWeight {
                                Text("Scaled: \(displayScaled)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Weight Input (if applicable)
                if rxWeight != nil {
                    HStack(spacing: theme.spacing.s) {
                        TextField("Weight", text: $weightText)
                            .textFieldStyle(.plain)
                            .font(theme.typography.body)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                            .padding(theme.spacing.s)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.s)
                            .onChange(of: weightText) { oldValue, newValue in
                                guard let inputWeight = Double(newValue) else { return }
                                // Always store in kg internally
                                selectedWeight = unitSettings.unitSystem == .metric ? inputWeight : UnitsConverter.lbsToKg(inputWeight)
                            }
                        
                        Text(unitSettings.unitSystem == .metric ? "kg" : "lb")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            
            if let notes = movement.notes, !notes.isEmpty {
                Text(notes)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .italic()
            }
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
        .onAppear {
            if let weight = selectedWeight {
                // Display in user's preferred units
                let displayWeight = unitSettings.unitSystem == .metric ? weight : UnitsConverter.kgToLbs(weight)
                weightText = String(format: "%.0f", displayWeight)
            } else if let rx = rxWeight {
                // Parse weight from RX string (e.g., "43kg" -> 43)
                let numbers = rx.filter { "0123456789.".contains($0) }
                if let parsed = Double(numbers) {
                    selectedWeight = parsed // Always store in kg
                    let displayWeight = unitSettings.unitSystem == .metric ? parsed : UnitsConverter.kgToLbs(parsed)
                    weightText = String(format: "%.0f", displayWeight)
                }
            }
        }
    }
}

// MARK: - Result Row
private struct ResultRow: View {
    let result: WODResult
    let wod: WOD
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.displayScore)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(result.completedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            if result.isRX {
                Text("RX")
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, theme.spacing.s)
                    .padding(.vertical, 4)
                    .background(theme.colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(theme.radius.s)
            }
            
            if result.isPR(among: wod.results ?? []) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(theme.colors.warning)
            }
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}

