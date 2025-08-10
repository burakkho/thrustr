import SwiftUI

struct FitnessCalculatorsView: View {
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
                                title: "1RM Hesaplayıcı",
                                description: "Maksimum tekrar hesaplama",
                                icon: "dumbbell.fill",
                                color: .blue,
                                details: "Egzersiz performansınızı değerlendirin"
                            )
                        }
                        
                        NavigationLink(destination: FFMICalculatorView()) {
                            CalculatorCard(
                                title: "FFMI Hesaplayıcı",
                                description: "Yağsız kas kütlesi indeksi",
                                icon: "figure.strengthtraining.traditional",
                                color: .green,
                                details: "Doğal genetik potansiyelinizi öğrenin"
                            )
                        }
                        
                        NavigationLink(destination: NavyMethodCalculatorView()) {
                            CalculatorCard(
                                title: "Navy Method",
                                description: "Vücut yağ oranı hesaplama",
                                icon: "percent",
                                color: .orange,
                                details: "Sadece ölçümlerle yağ oranınızı hesaplayın"
                            )
                        }
                    }
                    
                    // Info Section
                    CalculatorInfoSection()
                }
                .padding()
            }
            .navigationTitle("Fitness Hesaplayıcıları")
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
                Text("Fitness Hesaplayıcıları")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Bilimsel formüllerle performansınızı değerlendirin")
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
