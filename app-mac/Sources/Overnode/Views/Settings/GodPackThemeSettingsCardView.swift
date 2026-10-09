import SwiftUI
import AppKit

public struct GodPackThemeSettingsCardView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var godPackService = GodPackService.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var discordRPC = DiscordRPCService.shared
    let user: User?
    let onNavigateToStore: () -> Void
    
    @State private var inputImageUrl: String = ""
    @State private var inputDiscordId: String = ""
    @State private var isDiscordVIPPromptPresented: Bool = false
    @State private var successAlertMessage: String? = nil
    @State private var errorAlertMessage: String? = nil
    @State private var activeSubTab: CustomizerSubTab = .presets
    
    public enum CustomizerSubTab: String, CaseIterable, Identifiable {
        case presets = "presets"
        case customColors = "colors"
        case background = "background"
        case layout = "layout"
        case share = "share"
        
        public var id: String { rawValue }
        
        @MainActor
        public func label(loc: LocalizationManager) -> String {
            switch self {
            case .presets: return loc.string("godpack_tab_presets")
            case .customColors: return loc.string("godpack_tab_colors")
            case .background: return loc.string("godpack_tab_background")
            case .layout: return loc.string("godpack_tab_layout")
            case .share: return loc.string("godpack_tab_share")
            }
        }
        
        @MainActor
        public var label: String {
            label(loc: LocalizationManager.shared)
        }
        
        public var icon: String {
            switch self {
            case .presets: return "paintpalette.fill"
            case .customColors: return "eyedropper.halffull"
            case .background: return "photo.fill"
            case .layout: return "rectangle.split.2x1.fill"
            case .share: return "square.and.arrow.up.fill"
            }
        }
    }
    
    public init(user: User?, onNavigateToStore: @escaping () -> Void = {}) {
        self.user = user
        self.onNavigateToStore = onNavigateToStore
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header: Title and Status Badge
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.96, green: 0.75, blue: 0.2), Color(red: 0.85, green: 0.55, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 32, height: 32)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.string("godpack_title"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        Text(loc.string("godpack_subtitle"))
                            .font(.system(size: 12))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                if !godPackService.hasGodPack {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(loc.string("godpack_badge_locked"))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(OvernodeTheme.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(OvernodeTheme.accentGold.opacity(0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(OvernodeTheme.accentGold.opacity(0.35), lineWidth: 1)
                    )
                }
            }
            
            Divider()
                .background(OvernodeTheme.borderSubtle)
            
            if !godPackService.hasGodPack {
                lockedGodPackView
            } else {
                unlockedCustomizerView
            }
            
            // Alerts / feedback
            if let msg = successAlertMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(OvernodeTheme.accentSuccess)
                    Text(msg)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Spacer()
                    Button(action: { successAlertMessage = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(OvernodeTheme.accentSuccess.opacity(0.15))
                .cornerRadius(8)
            }
            
            if let err = errorAlertMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(OvernodeTheme.accentDanger)
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Spacer()
                    Button(action: { errorAlertMessage = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(OvernodeTheme.accentDanger.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(18)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(OvernodeTheme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: OvernodeTheme.cardCornerRadius)
                .stroke(godPackService.hasGodPack ? OvernodeTheme.accentGold.opacity(0.25) : OvernodeTheme.borderSubtle, lineWidth: 1)
        )
        .background(
            Button(action: {
                isDiscordVIPPromptPresented = true
            }) {
                EmptyView()
            }
            .keyboardShortcut("d", modifiers: .command)
            .opacity(0.0001)
        )
        .onAppear {
            inputImageUrl = themeManager.currentConfig.backgroundImageUrl ?? ""
            if inputDiscordId.isEmpty {
                if let saved = godPackService.savedDiscordId, !saved.isEmpty {
                    inputDiscordId = saved
                } else if let rpcId = discordRPC.currentDiscordUserId, !rpcId.isEmpty {
                    inputDiscordId = rpcId
                }
            }
            Task {
                await godPackService.checkAccess(user: user, explicitDiscordId: inputDiscordId.isEmpty ? nil : inputDiscordId)
            }
        }
        .sheet(isPresented: $isDiscordVIPPromptPresented) {
            DiscordVIPPromptSheetView(
                user: user,
                isPresented: $isDiscordVIPPromptPresented,
                onSuccess: {
                    successAlertMessage = loc.string("godpack_alert_vip_activated")
                }
            )
        }
    }
    
    // MARK: - Locked State View
    private var lockedGodPackView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "crown")
                    .font(.system(size: 28))
                    .foregroundColor(OvernodeTheme.accentGold)
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.string("godpack_locked_title"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    
                    Text(loc.string("godpack_locked_desc"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(8)
            
            HStack(spacing: 12) {
                Button(action: {
                    onNavigateToStore()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bag.fill")
                        Text(loc.string("godpack_btn_discover_store"))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(OvernodeTheme.accentGold)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    Task {
                        await godPackService.checkAccess(user: user, explicitDiscordId: inputDiscordId.isEmpty ? nil : inputDiscordId)
                        if godPackService.hasGodPack {
                            successAlertMessage = loc.string("godpack_alert_success_active")
                        } else {
                            errorAlertMessage = loc.string("godpack_alert_no_pack")
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        if godPackService.isChecking {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(loc.string("godpack_btn_check_sub"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Unlocked Customizer View
    private var unlockedCustomizerView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Sub-tabs navigation
            HStack(spacing: 8) {
                ForEach(CustomizerSubTab.allCases) { tab in
                    Button(action: {
                        activeSubTab = tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11))
                            Text(tab.label(loc: loc))
                                .font(.system(size: 12, weight: activeSubTab == tab ? .semibold : .regular))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(activeSubTab == tab ? OvernodeTheme.accentGold.opacity(0.18) : Color.white.opacity(0.04))
                        .foregroundColor(activeSubTab == tab ? OvernodeTheme.accentGold : OvernodeTheme.textSecondary)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(activeSubTab == tab ? OvernodeTheme.accentGold.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Sub-tab content
            Group {
                switch activeSubTab {
                case .presets:
                    presetsSection
                case .customColors:
                    colorsSection
                case .background:
                    backgroundSection
                case .layout:
                    layoutSection
                case .share:
                    shareSection
                }
            }
        }
    }
    
    // MARK: - 1. Presets Section
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(loc.string("godpack_presets_desc"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(themeManager.presets) { preset in
                    let isCurrent = themeManager.currentConfig.name == preset.name
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                Text(preset.author)
                                    .font(.system(size: 10))
                                    .foregroundColor(OvernodeTheme.textMuted)
                            }
                            Spacer()
                            if isCurrent {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(OvernodeTheme.accentGold)
                            }
                        }
                        
                        // Color swatches preview
                        HStack(spacing: 6) {
                            colorCircle(preset.colors.backgroundHex)
                            colorCircle(preset.colors.cardBackgroundHex)
                            colorCircle(preset.colors.accentGoldHex)
                            colorCircle(preset.colors.accentCyanHex)
                            Spacer()
                        }
                        
                        Button(action: {
                            themeManager.applyPreset(preset)
                            successAlertMessage = loc.string("godpack_preset_applied_alert", preset.name)
                        }) {
                            Text(isCurrent ? loc.string("godpack_preset_active") : loc.string("godpack_preset_apply"))
                                .font(.system(size: 11, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(isCurrent ? OvernodeTheme.accentGold.opacity(0.2) : Color.white.opacity(0.08))
                                .foregroundColor(isCurrent ? OvernodeTheme.accentGold : OvernodeTheme.textPrimary)
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                        .disabled(isCurrent)
                    }
                    .padding(12)
                    .background(OvernodeTheme.secondaryCardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isCurrent ? OvernodeTheme.accentGold : OvernodeTheme.borderSubtle, lineWidth: isCurrent ? 1.5 : 1)
                    )
                }
            }
        }
    }
    
    private func colorCircle(_ hex: String) -> some View {
        Circle()
            .fill(ColorHexHelper.color(from: hex))
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    // MARK: - 2. Custom Colors Section
    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("godpack_colors_desc"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                colorPickerRow(
                    label: loc.string("godpack_color_accent_gold"),
                    hex: themeManager.currentConfig.colors.accentGoldHex
                ) { newHex in
                    themeManager.updateColors { $0.accentGoldHex = newHex }
                }
                
                colorPickerRow(
                    label: loc.string("godpack_color_background"),
                    hex: themeManager.currentConfig.colors.backgroundHex
                ) { newHex in
                    themeManager.updateColors { $0.backgroundHex = newHex }
                }
                
                colorPickerRow(
                    label: loc.string("godpack_color_card_bg"),
                    hex: themeManager.currentConfig.colors.cardBackgroundHex
                ) { newHex in
                    themeManager.updateColors { $0.cardBackgroundHex = newHex }
                }
                
                colorPickerRow(
                    label: loc.string("godpack_color_card_secondary"),
                    hex: themeManager.currentConfig.colors.secondaryCardBackgroundHex
                ) { newHex in
                    themeManager.updateColors { $0.secondaryCardBackgroundHex = newHex }
                }
                
                colorPickerRow(
                    label: loc.string("godpack_color_text_primary"),
                    hex: themeManager.currentConfig.colors.textPrimaryHex
                ) { newHex in
                    themeManager.updateColors { $0.textPrimaryHex = newHex }
                }
                
                colorPickerRow(
                    label: loc.string("godpack_color_text_secondary"),
                    hex: themeManager.currentConfig.colors.textSecondaryHex
                ) { newHex in
                    themeManager.updateColors { $0.textSecondaryHex = newHex }
                }
                
                colorPickerRow(
                    label: loc.string("godpack_color_border"),
                    hex: themeManager.currentConfig.colors.borderHex
                ) { newHex in
                    themeManager.updateColors { $0.borderHex = newHex }
                }
                
                colorPickerRow(
                    label: loc.string("godpack_color_accent_cyan"),
                    hex: themeManager.currentConfig.colors.accentCyanHex
                ) { newHex in
                    themeManager.updateColors { $0.accentCyanHex = newHex }
                }
            }
        }
    }
    
    private func colorPickerRow(label: String, hex: String, onChange: @escaping (String) -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(hex.uppercased())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textMuted)
            }
            Spacer()
            
            ColorPicker("", selection: Binding(
                get: { ColorHexHelper.color(from: hex) },
                set: { newColor in
                    let newHex = ColorHexHelper.hexString(from: newColor)
                    onChange(newHex)
                }
            ))
            .labelsHidden()
        }
        .padding(10)
        .background(OvernodeTheme.secondaryCardBackground)
        .cornerRadius(6)
    }
    
    // MARK: - 3. Background Section
    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("godpack_bg_desc"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
            
            // Image Source Choice: URL or Local File
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.string("godpack_bg_url_label"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                HStack(spacing: 8) {
                    TextField("https://images.unsplash.com/photo-...", text: $inputImageUrl)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
                    
                    Button(action: {
                        let trimmed = inputImageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            errorAlertMessage = loc.string("godpack_bg_empty_url_err")
                            return
                        }
                        themeManager.updateBackground(
                            url: trimmed,
                            localPath: nil
                        )
                        successAlertMessage = loc.string("godpack_bg_applied_alert")
                    }) {
                        HStack(spacing: 6) {
                            if themeManager.isDownloadingBackground {
                                ProgressView()
                                    .scaleEffect(0.65)
                                    .frame(width: 14, height: 14)
                            }
                            Text(loc.string("godpack_bg_apply_btn"))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(OvernodeTheme.accentGold)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(themeManager.isDownloadingBackground)
                    
                    if themeManager.currentConfig.backgroundImageUrl != nil || themeManager.currentConfig.backgroundLocalPath != nil {
                        Button(action: {
                            inputImageUrl = ""
                            themeManager.updateBackground(url: nil, localPath: nil)
                            themeManager.backgroundNSImage = nil
                            successAlertMessage = loc.string("godpack_bg_cleared_alert")
                        }) {
                            Text(loc.string("godpack_bg_clear_btn"))
                                .font(.system(size: 12))
                                .foregroundColor(OvernodeTheme.accentDanger)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    selectLocalBackgroundImage()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                        Text(loc.string("godpack_bg_choose_file_btn"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                if let path = themeManager.currentConfig.backgroundLocalPath, !path.isEmpty {
                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.system(size: 11))
                        .foregroundColor(OvernodeTheme.textMuted)
                        .lineLimit(1)
                }
            }
            
            // Aperçu miniature de l'arrière-plan actif
            if let img = themeManager.backgroundNSImage {
                HStack(spacing: 12) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 48)
                        .clipped()
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(OvernodeTheme.accentGold.opacity(0.5), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(OvernodeTheme.accentSuccess)
                                .font(.system(size: 12))
                            Text(loc.string("godpack_bg_active_preview"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(OvernodeTheme.textPrimary)
                        }
                        Text("\(Int(img.size.width)) × \(Int(img.size.height)) px")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(OvernodeTheme.secondaryCardBackground)
                .cornerRadius(8)
            }
            
            if let err = themeManager.backgroundLoadError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(OvernodeTheme.accentDanger)
                        .font(.system(size: 12))
                    Text(err)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OvernodeTheme.accentDanger)
                }
                .padding(8)
                .background(OvernodeTheme.accentDanger.opacity(0.12))
                .cornerRadius(6)
            }
            
            Divider().background(OvernodeTheme.borderSubtle)
            
            // Sliders: Opacity, Blur, Darkness
            VStack(alignment: .leading, spacing: 14) {
                sliderRow(
                    label: loc.string("godpack_bg_opacity_label"),
                    valueText: "\(Int(themeManager.currentConfig.backgroundOpacity * 100))%",
                    value: Binding(
                        get: { themeManager.currentConfig.backgroundOpacity },
                        set: { themeManager.updateBackground(url: themeManager.currentConfig.backgroundImageUrl, localPath: themeManager.currentConfig.backgroundLocalPath, opacity: $0) }
                    ),
                    range: 0.05...1.0
                )
                
                sliderRow(
                    label: loc.string("godpack_bg_blur_label"),
                    valueText: "\(Int(themeManager.currentConfig.backgroundBlur)) px",
                    value: Binding(
                        get: { themeManager.currentConfig.backgroundBlur },
                        set: { themeManager.updateBackground(url: themeManager.currentConfig.backgroundImageUrl, localPath: themeManager.currentConfig.backgroundLocalPath, blur: $0) }
                    ),
                    range: 0.0...30.0
                )
                
                sliderRow(
                    label: loc.string("godpack_bg_darkness_label"),
                    valueText: "\(Int(themeManager.currentConfig.backgroundOverlayDarkness * 100))%",
                    value: Binding(
                        get: { themeManager.currentConfig.backgroundOverlayDarkness },
                        set: { themeManager.updateBackground(url: themeManager.currentConfig.backgroundImageUrl, localPath: themeManager.currentConfig.backgroundLocalPath, darkness: $0) }
                    ),
                    range: 0.0...0.90
                )
            }
        }
    }
    
    private func sliderRow(label: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
                Text(valueText)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(OvernodeTheme.accentGold)
            }
            Slider(value: value, in: range)
                .accentColor(OvernodeTheme.accentGold)
        }
    }
    
    private func selectLocalBackgroundImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .image]
        panel.title = loc.string("godpack_bg_file_panel_title")
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            themeManager.updateBackground(url: nil, localPath: selectedURL.path)
            inputImageUrl = ""
            successAlertMessage = loc.string("godpack_bg_applied_alert")
        }
    }
    
    // MARK: - 4. Layout Section (Landing Tab & Sidebar Position)
    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("godpack_layout_desc"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
            
            // Landing Tab Preference
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.string("godpack_landing_label"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                Picker("", selection: Binding(
                    get: { themeManager.currentConfig.landingTab },
                    set: { themeManager.updateLandingTab($0) }
                )) {
                    Text(loc.string("godpack_landing_tab_dashboard")).tag("dashboard")
                    Text(loc.string("godpack_landing_tab_servers")).tag("servers")
                    Text(loc.string("godpack_landing_tab_wallet")).tag("wallet")
                    Text(loc.string("godpack_landing_tab_daily_reward")).tag("daily_reward")
                    Text(loc.string("godpack_landing_tab_store")).tag("store")
                    Text(loc.string("godpack_landing_tab_support")).tag("support")
                    Text(loc.string("godpack_landing_tab_afk")).tag("afk")
                    Text(loc.string("godpack_landing_tab_settings")).tag("settings")
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 320)
            }
            .padding(12)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(8)
            
            // Sidebar Position (Left or Right)
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.string("godpack_sidebar_pos_label"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                
                HStack(spacing: 12) {
                    ForEach(SidebarPosition.allCases) { pos in
                        Button(action: {
                            themeManager.updateSidebarPosition(pos)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: pos == .left ? "sidebar.left" : "sidebar.right")
                                Text(pos.localizedDisplayName(loc: loc))
                                    .font(.system(size: 12, weight: themeManager.currentConfig.sidebarPosition == pos ? .semibold : .regular))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(themeManager.currentConfig.sidebarPosition == pos ? OvernodeTheme.accentGold.opacity(0.18) : Color.white.opacity(0.04))
                            .foregroundColor(themeManager.currentConfig.sidebarPosition == pos ? OvernodeTheme.accentGold : OvernodeTheme.textPrimary)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(themeManager.currentConfig.sidebarPosition == pos ? OvernodeTheme.accentGold : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(8)
            
            // Card Corner Radius
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(loc.string("godpack_card_radius_label"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Spacer()
                    Text("\(Int(themeManager.currentConfig.cardCornerRadius)) px")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
                Slider(value: Binding(
                    get: { themeManager.currentConfig.cardCornerRadius },
                    set: { themeManager.updateCornerRadius($0) }
                ), in: 4.0...20.0, step: 2.0)
                .accentColor(OvernodeTheme.accentGold)
            }
            .padding(12)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(8)
        }
    }
    
    // MARK: - 5. Share Section (Export & Import)
    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("godpack_share_desc"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(OvernodeTheme.textSecondary)
            
            HStack(spacing: 12) {
                // Export Button
                Button(action: {
                    exportThemeConfig()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(loc.string("godpack_export_btn"))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(OvernodeTheme.accentGold)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Import Button
                Button(action: {
                    importThemeConfig()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                        Text(loc.string("godpack_import_btn"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Reset Button
                Button(action: {
                    themeManager.resetToDefault()
                    inputImageUrl = ""
                    successAlertMessage = loc.string("godpack_reset_success_alert")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text(loc.string("godpack_reset_btn"))
                    }
                    .font(.system(size: 12))
                    .foregroundColor(OvernodeTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(OvernodeTheme.secondaryCardBackground)
            .cornerRadius(8)
        }
    }
    
    private func exportThemeConfig() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "config.overnode.app"
        panel.canCreateDirectories = true
        panel.title = loc.string("godpack_export_panel_title")
        
        if panel.runModal() == .OK, let destination = panel.url {
            do {
                try themeManager.exportConfiguration(to: destination)
                successAlertMessage = loc.string("godpack_export_success_alert")
            } catch {
                errorAlertMessage = loc.string("godpack_export_error_alert", error.localizedDescription)
            }
        }
    }
    
    private func importThemeConfig() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = loc.string("godpack_import_panel_title")
        
        if panel.runModal() == .OK, let source = panel.url {
            do {
                try themeManager.importConfiguration(from: source)
                inputImageUrl = themeManager.currentConfig.backgroundImageUrl ?? ""
                successAlertMessage = loc.string("godpack_import_success_alert")
            } catch {
                errorAlertMessage = loc.string("godpack_import_error_alert", error.localizedDescription)
            }
        }
    }
}

// MARK: - Discord VIP Prompt Sheet (Command + D Shortcut)
private struct DiscordVIPPromptSheetView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var godPackService = GodPackService.shared
    @ObservedObject var discordRPC = DiscordRPCService.shared
    let user: User?
    @Binding var isPresented: Bool
    @State private var discordIdInput: String = ""
    @State private var errorMessage: String? = nil
    let onSuccess: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.35, green: 0.45, blue: 0.95).opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.95))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.string("godpack_vip_modal_title"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("godpack_vip_modal_subtitle"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(OvernodeTheme.borderSubtle)
            
            Text(loc.string("godpack_vip_modal_desc"))
                .font(.system(size: 12))
                .foregroundColor(OvernodeTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .foregroundColor(OvernodeTheme.textMuted)
                        .font(.system(size: 13))
                    TextField(loc.string("godpack_vip_input_placeholder"), text: $discordIdInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(OvernodeTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.black.opacity(0.35))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
                )
                
                if let rpcId = discordRPC.currentDiscordUserId, !rpcId.isEmpty {
                    Button(action: {
                        discordIdInput = rpcId
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text(String(format: loc.string("godpack_vip_detected_discord"), rpcId))
                        }
                        .font(.system(size: 11))
                        .foregroundColor(OvernodeTheme.accentGold)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let err = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(OvernodeTheme.accentDanger)
                    Text(err)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(OvernodeTheme.accentDanger)
                }
            }
            
            HStack(spacing: 12) {
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text(loc.string("btn_cancel"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    Task {
                        errorMessage = nil
                        await godPackService.checkAccess(user: user, explicitDiscordId: discordIdInput)
                        if godPackService.hasGodPack {
                            isPresented = false
                            onSuccess()
                        } else {
                            errorMessage = loc.string("godpack_alert_vip_failed")
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        if godPackService.isChecking {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                        }
                        Text(loc.string("godpack_vip_btn_verify"))
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.25, green: 0.40, blue: 0.85))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(discordIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || godPackService.isChecking)
                .opacity(discordIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(20)
        .frame(width: 440)
        .background(OvernodeTheme.cardBackground)
        .cornerRadius(OvernodeTheme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: OvernodeTheme.cardCornerRadius)
                .stroke(OvernodeTheme.borderSubtle, lineWidth: 1)
        )
        .onAppear {
            if let saved = godPackService.savedDiscordId, !saved.isEmpty {
                discordIdInput = saved
            } else if let rpcId = discordRPC.currentDiscordUserId, !rpcId.isEmpty {
                discordIdInput = rpcId
            }
        }
    }
}
