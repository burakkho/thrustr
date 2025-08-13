import SwiftUI

struct WODSelectorLocalView: View {
    @Environment(\.dismiss) private var dismiss
    let part: WorkoutPart
    let onSelect: (WODTemplate?, String?) -> Void

    @State private var selectedTab: Int = 0
    @State private var customText: String = ""
    @State private var favoriteIds: Set<String> = []

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Picker("", selection: $selectedTab) {
                    Text(LocalizationKeys.Training.WOD.benchmarks.localized).tag(0)
                    Text(LocalizationKeys.Training.WOD.forTime.localized).tag(1)
                    Text(LocalizationKeys.Training.WOD.amrap.localized).tag(2)
                    Text(LocalizationKeys.Training.WOD.emom.localized).tag(3)
                    Text(LocalizationKeys.Training.WOD.custom.localized).tag(4)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedTab {
                case 0:
                    List {
                        if !favorites.isEmpty {
                            Section(header: Text(LocalizationKeys.Training.WOD.favorites.localized)) {
                                ForEach(favorites) { wod in row(for: wod) }
                            }
                        }
                        Section(header: Text(LocalizationKeys.Training.WOD.benchmarks.localized)) {
                            ForEach(WODLookup.benchmark) { wod in row(for: wod) }
                        }
                    }
                    .listStyle(.insetGrouped)
                case 1:
                    WODQuickForm(title: LocalizationKeys.Training.WOD.forTime.localized) { result in
                        onSelect(nil, result)
                        dismiss()
                    }
                case 2:
                    AMRAPForm { result in
                        onSelect(nil, result)
                        dismiss()
                    }
                case 3:
                    EMOMForm { result in
                        onSelect(nil, result)
                        dismiss()
                    }
                default:
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizationKeys.Training.WOD.customResult.localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("e.g., 5 RFT 10+8+6", text: $customText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                        Spacer()
                        Button(LocalizationKeys.Common.save.localized) {
                            onSelect(nil, customText.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                        .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(LocalizationKeys.Training.WOD.title.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(LocalizationKeys.Common.close.localized) { dismiss() } } }
            .onAppear { loadFavorites() }
        }
    }
}

private extension WODSelectorLocalView {
    var favorites: [WODTemplate] {
        let ids = favoriteIds
        return WODLookup.benchmark.filter { ids.contains($0.id.uuidString) }
    }

    func loadFavorites() {
        let arr = UserDefaults.standard.array(forKey: "training.favorite.wods") as? [String] ?? []
        favoriteIds = Set(arr)
    }

    func toggleFavorite(_ wod: WODTemplate) {
        if favoriteIds.contains(wod.id.uuidString) {
            favoriteIds.remove(wod.id.uuidString)
        } else {
            favoriteIds.insert(wod.id.uuidString)
        }
        UserDefaults.standard.set(Array(favoriteIds), forKey: "training.favorite.wods")
    }

    @ViewBuilder
    func row(for wod: WODTemplate) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(wod.name).font(.headline)
                Text(wod.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { toggleFavorite(wod) }) {
                Image(systemName: favoriteIds.contains(wod.id.uuidString) ? "heart.fill" : "heart")
                    .foregroundColor(.red)
            }
            Button(action: { onSelect(wod, nil); dismiss() }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct WODQuickForm: View {
    let title: String
    let onSave: (String) -> Void
    @State private var minutes: String = ""
    @State private var seconds: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text(LocalizationKeys.Training.WOD.enterTime.localized).font(.headline)
            HStack(spacing: 8) {
                TextField("MM", text: $minutes).keyboardType(.numberPad).frame(width: 60)
                Text(":")
                TextField("SS", text: $seconds).keyboardType(.numberPad).frame(width: 60)
            }
            Spacer()
            Button(LocalizationKeys.Common.save.localized) {
                let mm = minutes.trimmingCharacters(in: .whitespaces)
                let ss = seconds.trimmingCharacters(in: .whitespaces)
                onSave("\(mm.pad2()):\(ss.pad2())")
            }
            .disabled(!isValid)
            .buttonStyle(PressableStyle())
        }
        .padding()
    }

    private var isValid: Bool {
        guard let m = Int(minutes), let s = Int(seconds), m >= 0, (0...59).contains(s) else { return false }
        return true
    }
}

private struct AMRAPForm: View {
    let onSave: (String) -> Void
    @State private var rounds: String = ""
    @State private var reps: String = ""
    var body: some View {
        VStack(spacing: 12) {
            Text(LocalizationKeys.Training.WOD.amrap.localized).font(.headline)
            HStack {
                TextField(LocalizationKeys.Training.WOD.rounds.localized, text: $rounds).keyboardType(.numberPad)
                TextField(LocalizationKeys.Training.WOD.reps.localized, text: $reps).keyboardType(.numberPad)
            }
            Spacer()
            Button(LocalizationKeys.Common.save.localized) { onSave("\(rounds) rds + \(reps) reps") }
                .disabled(Int(rounds) == nil || Int(reps) == nil)
                .buttonStyle(PressableStyle())
        }
        .padding()
    }
}

private struct EMOMForm: View {
    let onSave: (String) -> Void
    @State private var completedRounds: String = ""
    @State private var totalRounds: String = "10"
    var body: some View {
        VStack(spacing: 12) {
            Text(LocalizationKeys.Training.WOD.emomCompleted.localized).font(.headline)
            HStack {
                TextField(LocalizationKeys.Common.completed.localized, text: $completedRounds).keyboardType(.numberPad)
                Text("/")
                TextField(LocalizationKeys.Training.WOD.total.localized, text: $totalRounds).keyboardType(.numberPad)
            }
            Spacer()
            Button(LocalizationKeys.Common.save.localized) { onSave("\(completedRounds)/\(totalRounds) rounds") }
                .disabled(Int(completedRounds) == nil || Int(totalRounds) == nil)
                .buttonStyle(PressableStyle())
        }
        .padding()
    }
}

private extension String {
    func pad2() -> String {
        let v = self.trimmingCharacters(in: .whitespaces)
        if v.count == 1 { return "0" + v }
        if v.isEmpty { return "00" }
        return v
    }
}


