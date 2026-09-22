import SwiftUI

public struct ServerSubdomainsTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var showingAddSheet = false
    @State private var newPrefix = ""
    @State private var selectedDomain = "overnode.fr"
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("subdomains_title"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("subdomains_subtitle"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    newPrefix = ""
                    if let first = vm.availableDomains.first {
                        selectedDomain = first
                    }
                    showingAddSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text(loc.string("subdomains_create_button"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(OvernodeTheme.accentGold)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Subdomains list
            if vm.isLoading && vm.subdomains.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if vm.subdomains.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "network")
                        .font(.system(size: 32))
                        .foregroundColor(OvernodeTheme.textMuted)
                    Text(loc.string("subdomains_empty"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.subdomains) { sub in
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.20, green: 0.75, blue: 0.85))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.fqdn)
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                
                                Text(loc.string("subdomains_cloudflare_active"))
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                            }
                            
                            Spacer()
                            
                            // Copy button
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(sub.fqdn, forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(OvernodeTheme.textSecondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                            
                            // Delete button
                            Button(role: .destructive, action: {
                                Task { await vm.deleteSubdomain(sub.id) }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(OvernodeTheme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(OvernodeTheme.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSubdomainSheetView(
                vm: vm,
                isPresented: $showingAddSheet,
                prefix: $newPrefix,
                selectedDomain: $selectedDomain
            )
        }
        .onAppear {
            Task { await vm.loadSubdomains() }
        }
    }
}

private struct AddSubdomainSheetView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var isPresented: Bool
    @Binding var prefix: String
    @Binding var selectedDomain: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("subdomains_modal_title"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.string("subdomains_prefix_label"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                
                HStack(spacing: 8) {
                    TextField("myserver", text: $prefix)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                    
                    Text(".")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    
                    Picker("", selection: $selectedDomain) {
                        ForEach(vm.availableDomains, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    .frame(width: 140)
                }
            }
            
            HStack {
                Spacer()
                Button(loc.string("generic_cancel")) {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(OvernodeTheme.textSecondary)
                
                Button(loc.string("generic_create")) {
                    let p = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    guard !p.isEmpty else { return }
                    isPresented = false
                    Task { await vm.createSubdomain(subdomain: p, domainName: selectedDomain) }
                }
                .buttonStyle(.borderedProminent)
                .tint(OvernodeTheme.accentGold)
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(OvernodeTheme.cardBackground)
    }
}

