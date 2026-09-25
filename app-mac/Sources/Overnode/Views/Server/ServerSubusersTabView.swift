import SwiftUI

public struct ServerSubusersTabView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @State private var showingAddSheet = false
    @State private var newEmail = ""
    
    public init(vm: ServerDetailViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loc.string("subusers_title"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(OvernodeTheme.textPrimary)
                    Text(loc.string("subusers_subtitle"))
                        .font(.system(size: 12))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    newEmail = ""
                    showingAddSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 12))
                        Text(loc.string("subusers_invite_button"))
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
            
            // Subusers List
            if vm.isLoading && vm.subusers.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if vm.subusers.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 32))
                        .foregroundColor(OvernodeTheme.textMuted)
                    Text(loc.string("subusers_empty"))
                        .font(.system(size: 13))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(OvernodeTheme.cardBackground)
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.subusers) { sub in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(red: 0.125, green: 0.133, blue: 0.161))
                                    .frame(width: 32, height: 32)
                                Text(String(sub.email.prefix(1)).uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.email)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(OvernodeTheme.textPrimary)
                                
                                HStack(spacing: 6) {
                                    if sub.twoFactorEnabled {
                                        HStack(spacing: 3) {
                                            Image(systemName: "checkmark.shield.fill")
                                                .font(.system(size: 9))
                                            Text(loc.string("subusers_2fa_enabled"))
                                                .font(.system(size: 10))
                                        }
                                        .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
                                    }
                                    
                                    Text("\(sub.permissions.count) " + loc.string("subusers_perms_count"))
                                        .font(.system(size: 10))
                                        .foregroundColor(OvernodeTheme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive, action: {
                                Task { await vm.deleteSubuser(sub.id) }
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
            InviteSubuserSheetView(
                vm: vm,
                isPresented: $showingAddSheet,
                email: $newEmail
            )
        }
        .onAppear {
            Task { await vm.loadSubusers() }
        }
    }
}

private struct InviteSubuserSheetView: View {
    @ObservedObject var vm: ServerDetailViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var isPresented: Bool
    @Binding var email: String
    @State private var controlPower = true
    @State private var manageFiles = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(loc.string("subusers_modal_title"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(OvernodeTheme.textPrimary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.string("subusers_email_label"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                
                TextField("colleague@example.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(loc.string("subusers_permissions_title"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                
                Toggle(loc.string("subusers_perm_power"), isOn: $controlPower)
                    .toggleStyle(.checkbox)
                Toggle(loc.string("subusers_perm_files"), isOn: $manageFiles)
                    .toggleStyle(.checkbox)
            }
            
            HStack {
                Spacer()
                Button(loc.string("generic_cancel")) {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(OvernodeTheme.textSecondary)
                
                Button(loc.string("subusers_invite_submit")) {
                    let em = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !em.isEmpty else { return }
                    isPresented = false
                    var perms: [String] = ["websocket.connect"]
                    if controlPower { perms.append(contentsOf: ["control.start", "control.stop", "control.restart"]) }
                    if manageFiles { perms.append(contentsOf: ["file.create", "file.read", "file.update", "file.delete"]) }
                    Task { await vm.addSubuser(email: em, permissions: perms) }
                }
                .buttonStyle(.borderedProminent)
                .tint(OvernodeTheme.accentGold)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background(OvernodeTheme.cardBackground)
    }
}

