import SwiftUI

public struct StoreResourceCardItemView: View {
    @ObservedObject var loc = LocalizationManager.shared
    let type: String
    let title: String
    let description: String
    let unitMultiplier: String
    let costPerUnit: Int
    let iconName: String
    let iconColor: Color
    let userCoins: Int
    let isPurchasing: Bool
    let onBuy: (Int) -> Void
    
    @State private var amount: Int = 1
    
    public init(
        type: String,
        title: String,
        description: String,
        unitMultiplier: String,
        costPerUnit: Int,
        iconName: String,
        iconColor: Color,
        userCoins: Int,
        isPurchasing: Bool,
        onBuy: @escaping (Int) -> Void
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.unitMultiplier = unitMultiplier
        self.costPerUnit = costPerUnit
        self.iconName = iconName
        self.iconColor = iconColor
        self.userCoins = userCoins
        self.isPurchasing = isPurchasing
        self.onBuy = onBuy
    }
    
    var totalPrice: Int {
        amount * costPerUnit
    }
    
    var canAfford: Bool {
        userCoins >= totalPrice
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .frame(width: 32, height: 32)
                    Image(systemName: iconName)
                        .font(.system(size: 13))
                        .foregroundColor(iconColor)
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
            }
            .padding(16)
            .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
            
            // Content
            VStack(alignment: .leading, spacing: 14) {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Stepper selector
                HStack {
                    Text(loc.string("store_quantity"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: { if amount > 1 { amount -= 1 } }) {
                            Image(systemName: "minus")
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .disabled(amount <= 1)
                        
                        Text("\(amount)")
                            .lineLimit(1)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .frame(minWidth: 24)
                        
                        Button(action: { if amount < 20 { amount += 1 } }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .disabled(amount >= 20)
                    }
                }
                
                Divider().background(OvernodeTheme.borderSubtle)
                
                // Price summary
                HStack {
                    Text(loc.string("store_total_cost"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(OvernodeTheme.accentGold)
                        Text("\(totalPrice) " + loc.string("wallet_coins_suffix"))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(canAfford ? OvernodeTheme.textPrimary : Color.red.opacity(0.8))
                    }
                }
                
                // Purchase button
                Button(action: { onBuy(amount) }) {
                    HStack(spacing: 6) {
                        if isPurchasing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: canAfford ? "cart.badge.plus" : "exclamationmark.circle")
                                .font(.system(size: 12))
                            Text(canAfford ? loc.string("store_buy_button") : loc.string("store_insufficient_funds"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(canAfford ? Color.white : Color.white.opacity(0.1))
                    .foregroundColor(canAfford ? Color.black : Color.white.opacity(0.4))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford || isPurchasing)
            }
            .padding(16)
            
            Spacer()
        }
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
}
