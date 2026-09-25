import SwiftUI

public struct WalletOverviewView: View {
    @ObservedObject var vm: WalletViewModel
    @ObservedObject var loc = LocalizationManager.shared
    let userCoins: Int
    
    public init(vm: WalletViewModel, userCoins: Int) {
        self.vm = vm
        self.userCoins = userCoins
    }
    
    public var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            // 1. Coin Balance Card
            coinBalanceCard
            
            // 2. Credit Balance Card
            creditBalanceCard
            
            // 3. Purchase Coins Card
            purchaseCoinsCard
        }
    }
    
    private var coinBalanceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161)) // #202229
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.white.opacity(0.05), lineWidth: 1))
                    Image(systemName: "circle.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
                Text(loc.string("wallet_coin_balance_title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
            }
            .padding(16)
            .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
            
            VStack(alignment: .leading, spacing: 12) {
                let coins = vm.billingInfo?.balances?.coins ?? userCoins
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(coins)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("wallet_coins_suffix"))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Text(loc.string("wallet_coin_balance_desc"))
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            .padding(16)
            
            Spacer()
        }
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
    
    private var creditBalanceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.white.opacity(0.05), lineWidth: 1))
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                Text(loc.string("wallet_credit_balance_title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
            }
            .padding(16)
            .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
            
            VStack(alignment: .leading, spacing: 16) {
                let credit = vm.billingInfo?.balances?.creditEur ?? 0.0
                Text(String(format: "%.2f €", credit))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Button(action: { vm.openAddFunds() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text(loc.string("wallet_add_funds"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Text(loc.string("wallet_stripe_secure"))
                    .font(.system(size: 11))
                    .foregroundColor(OvernodeTheme.textMuted)
            }
            .padding(16)
            
            Spacer()
        }
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
    
    private var purchaseCoinsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.white.opacity(0.05), lineWidth: 1))
                    Image(systemName: "cart.fill")
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                Text(loc.string("wallet_purchase_coins_title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
            }
            .padding(16)
            .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
            
            VStack(spacing: 8) {
                coinPackageRow(coins: 1000, priceText: "1,79 $")
                coinPackageRow(coins: 2500, priceText: "3,99 $")
                coinPackageRow(coins: 5000, priceText: "5,99 $")
            }
            .padding(16)
            
            Spacer()
        }
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
    
    private func coinPackageRow(coins: Int, priceText: String) -> some View {
        Button(action: { vm.purchaseCoinsPackage(coins) }) {
            HStack {
                Text("\(coins) " + loc.string("wallet_coins_suffix"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
                Text(priceText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
