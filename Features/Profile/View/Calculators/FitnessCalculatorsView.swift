import SwiftUI
import SwiftData

struct FitnessCalculatorsView: View {
    @Query private var users: [User]
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    CalculatorsHeaderSection()
                    
                    // Calculator Cards
                    VStack(spacing: 16) {
                        NavigationLink(destination: OneRMCalculatorView()) {
                            CalculatorCard(
                                title: ProfileKeys.OneRMCalculator.title.localized,
                                description: ProfileKeys.OneRMCalculator.subtitle.localized,
                                icon: "dumbbell.fill",
                                color: .blue,
                                details: "fitness_calculators.card.one_rm.details".localized
                            )
                        }
                        
                        NavigationLink(destination: FFMICalculatorView()) {
                            CalculatorCard(
                                title: ProfileKeys.FFMICalculator.title.localized,
                                description: ProfileKeys.FFMICalculator.subtitle.localized,
                                icon: "figure.strengthtraining.traditional",
                                color: .green,
                                details: "fitness_calculators.card.ffmi.details".localized
                            )
                        }
                        
                        NavigationLink(destination: NavyMethodCalculatorView(user: currentUser)) {
                            CalculatorCard(
                                title: ProfileKeys.NavyMethodCalculator.title.localized,
                                description: ProfileKeys.NavyMethodCalculator.calculate.localized,
                                icon: "percent",
                                color: .orange,
                                details: "fitness_calculators.card.navy.details".localized
                            )
                        }
                    }
                    
                    // Info Section
                    CalculatorInfoSection()
                }
                .padding()
            }
            .navigationTitle("fitness_calculators.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Header Section
struct CalculatorsHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "function")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("fitness_calculators.title".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("fitness_calculators.subtitle".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Calculator Card
struct CalculatorCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let details: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Info Section
struct CalculatorInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bilgi")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "info.circle.fill",
                    title: "Doğruluk",
                    description: "Hesaplamalar bilimsel formüllere dayanır"
                )
                
                InfoRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Tahmini Sonuçlar",
                    description: "Sonuçlar yaklaşık değerlerdir, bireysel farklılıklar olabilir"
                )
                
                InfoRow(
                    icon: "heart.fill",
                    title: "Sağlık Uyarısı",
                    description: "Ciddi sağlık kararları için doktora danışın"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    FitnessCalculatorsView()
}
