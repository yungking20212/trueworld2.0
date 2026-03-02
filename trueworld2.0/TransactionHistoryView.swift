import SwiftUI

struct TransactionHistoryView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppDesignSystem.Components.DynamicBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header (Glassmorphic)
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Transaction History")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                if viewModel.withdrawalHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.15))
                        
                        Text("No Payout History Yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("Monetize your creations and hit the minimum payout to start your creator journey.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.25))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.withdrawalHistory) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await viewModel.fetchWithdrawalHistory() }
        }
    }
}

struct TransactionRow: View {
    let transaction: WithdrawalAudit
    
    var body: some View {
        HStack(spacing: 16) {
            // Visual Indicator
            ZStack {
                Circle()
                    .fill(transaction.action == "WITHDRAWAL_SUCCESS" ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.action == "WITHDRAWAL_SUCCESS" ? "checkmark.circle.fill" : "clock_fill")
                    .font(.system(size: 20))
                    .foregroundColor(transaction.action == "WITHDRAWAL_SUCCESS" ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.action.replacingOccurrences(of: "_", with: " "))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            Text("$\(Double(transaction.amount) / 100.0, specifier: "%.2f")")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
