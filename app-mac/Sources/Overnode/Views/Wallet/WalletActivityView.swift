import SwiftUI

public struct WalletActivityView: View {
    @ObservedObject var vm: WalletViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: WalletViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(loc.string("wallet_activity_type"))
                    .frame(width: 140, alignment: .leading)
                Text(loc.string("wallet_activity_id"))
                    .frame(minWidth: 120, alignment: .leading)
                Spacer()
                Text(loc.string("wallet_activity_amount"))
                    .frame(width: 100, alignment: .trailing)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(OvernodeTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.125, green: 0.133, blue: 0.161).opacity(0.6))
            
            Divider().background(OvernodeTheme.borderSubtle)
            
            if !vm.transactions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(vm.transactions) { tx in
                        HStack {
                            Text(tx.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                                .foregroundColor(OvernodeTheme.textPrimary)
                                .cornerRadius(4)
                                .frame(width: 140, alignment: .leading)
                            
                            Text(String(tx.id.prefix(12)))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(OvernodeTheme.textSecondary)
                                .frame(minWidth: 120, alignment: .leading)
                            
                            Spacer()
                            
                            let isPositive = tx.amount >= 0
                            Text(String(format: "%@%.2f", isPositive ? "+" : "", tx.amount))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(isPositive ? Color.green : Color.red)
                                .frame(width: 100, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        
                        Divider().background(OvernodeTheme.borderSubtle.opacity(0.5))
                    }
                }
            } else if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(32)
            } else {
                Text(loc.string("wallet_no_transactions"))
                    .font(.system(size: 13))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
        }
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
}
