import SwiftUI
import SwiftData

struct WODDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    let wod: WOD
    @State private var viewModel = WODDetailViewModel()
    @State private var showingTimer = false
    @State private var showingHistory = false
    @State private var showingEdit = false
    @State private var showingShare = false

    private var wodResults: [WODResult] {
        viewModel.getSortedResults(for: wod)
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
                    movements: viewModel.prepareMovementsForTimer(from: wod),
                    isRX: viewModel.isRX
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
                // WOD edit functionality
                VStack(spacing: 16) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)

                    Text("WOD Editor")
                        .font(.headline)

                    Text("WOD editing will be available in a future update.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Close") {
                        showingEdit = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    userGender: viewModel.currentUser?.gender,
                    viewModel: viewModel,
                    isRX: $viewModel.isRX,
                    selectedWeight: Binding(
                        get: { viewModel.selectedWeights[movement.id] },
                        set: { viewModel.selectedWeights[movement.id] = $0 }
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
            
            Picker("Mode", selection: $viewModel.isRX) {
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
        .onAppear {
            viewModel.configure(modelContext: modelContext)
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
        viewModel.toggleFavorite(for: wod)
    }
}

// MARK: - Movement Card
private struct MovementCard: View {
    let movement: WODMovement
    let index: Int
    let userGender: String?
    let viewModel: WODDetailViewModel
    @Binding var isRX: Bool
    @Binding var selectedWeight: Double?
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) private var unitSettings
    @State private var weightText = ""

    private var displayRxWeight: String? {
        viewModel.displayRxWeight(for: movement, userGender: userGender)
    }
    
    private var displayScaledWeight: String? {
        viewModel.displayScaledWeight(for: movement, userGender: userGender)
    }

    private var rxWeight: String? {
        movement.rxWeight(for: userGender)
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
                                selectedWeight = viewModel.handleWeightInput(newValue)
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
            weightText = viewModel.getWeightInputText(for: selectedWeight)

            // If no weight selected, try to parse from RX weight
            if selectedWeight == nil, let rx = movement.rxWeight(for: userGender) {
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

