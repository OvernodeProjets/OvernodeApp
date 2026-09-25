import SwiftUI

public struct StoreBundlesView: View {
    @ObservedObject var vm: StoreViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    public init(vm: StoreViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(vm.bundles) { bundle in
                bundleCard(bundle: bundle)
            }
        }
    }
    
    private func bundleCard(bundle: StoreBundle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                        .frame(width: 32, height: 32)
                    Image(systemName: bundle.iconName)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: bundle.iconColor))
                }
                Text(bundle.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
            }
            .padding(16)
            .overlay(Rectangle().frame(height: 1).foregroundColor(OvernodeTheme.borderSubtle), alignment: .bottom)
            
            // Body
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(bundle.price)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(bundle.period)
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Text(bundleDescription(bundle))
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .lineLimit(3)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(bundleFeatures(bundle), id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.133, green: 0.773, blue: 0.365)) // emerald
                                .padding(.top, 2)
                            Text(feature)
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.textSecondary)
                        }
                    }
                }
                
                Spacer(minLength: 8)
                
                // Subscribe button
                Button(action: { vm.subscribeBundle(bundle) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 12))
                        Text(loc.string("store_subscribe"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
    
    private func bundleDescription(_ bundle: StoreBundle) -> String {
        switch bundle.id {
        case "auto_renew": return loc.string("bundle_auto_renew_desc")
        case "upgraded_pack": return loc.string("bundle_upgraded_desc")
        case "god_pack": return loc.string("bundle_god_desc")
        default: return bundle.description
        }
    }
    
    private func bundleFeatures(_ bundle: StoreBundle) -> [String] {
        switch bundle.id {
        case "auto_renew":
            return [
                loc.string("bundle_auto_renew_f1"),
                loc.string("bundle_auto_renew_f2"),
                loc.string("bundle_auto_renew_f3")
            ]
        case "upgraded_pack":
            return [
                loc.string("bundle_upgraded_f1"),
                loc.string("bundle_upgraded_f2"),
                loc.string("bundle_upgraded_f3")
            ]
        case "god_pack":
            return [
                loc.string("bundle_god_f1"),
                loc.string("bundle_god_f2"),
                loc.string("bundle_god_f3")
            ]
        default:
            return bundle.features
        }
    }
}

private extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let r, g, b: UInt64
        switch clean.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }
        self.init(
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0
        )
    }
}
