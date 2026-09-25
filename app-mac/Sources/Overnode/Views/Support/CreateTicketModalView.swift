import SwiftUI

public struct CreateTicketModalView: View {
    @ObservedObject var vm: SupportViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var isPresented: Bool
    
    public init(vm: SupportViewModel, isPresented: Binding<Bool>) {
        self.vm = vm
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Title
            HStack {
                Text(loc.string("support_modal_title"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(OvernodeTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(OvernodeTheme.borderSubtle)
            
            // Subject
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.string("support_field_subject"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                TextField("Ex: Problème d'allocation...", text: $vm.newSubject)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
            }
            
            // Category & Priority
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.string("support_field_category"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Picker("", selection: $vm.newCategory) {
                        Text(loc.string("support_cat_tech")).tag("technical")
                        Text(loc.string("support_cat_billing")).tag("billing")
                        Text(loc.string("support_cat_general")).tag("general")
                        Text(loc.string("support_cat_abuse")).tag("abuse")
                    }
                    .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.string("support_field_priority"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(OvernodeTheme.textSecondary)
                    Picker("", selection: $vm.newPriority) {
                        Text(loc.string("support_priority_low")).tag("low")
                        Text(loc.string("support_priority_medium")).tag("medium")
                        Text(loc.string("support_priority_high")).tag("high")
                        Text(loc.string("support_priority_urgent")).tag("urgent")
                    }
                    .labelsHidden()
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.string("support_field_desc"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(OvernodeTheme.textSecondary)
                TextEditor(text: $vm.newDescription)
                    .font(.system(size: 13))
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(red: 0.125, green: 0.133, blue: 0.161))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
            }
            
            // Error
            if let err = vm.errorMessage {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(Color.red)
            }
            
            // Actions
            HStack(spacing: 10) {
                Spacer()
                Button(loc.string("generic_cancel")) {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(OvernodeTheme.textSecondary)
                
                Button(action: { vm.createTicket() }) {
                    HStack(spacing: 6) {
                        if vm.isCreatingTicket {
                            ProgressView().controlSize(.small)
                        }
                        Text(loc.string("support_btn_send_ticket"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(vm.isCreatingTicket)
            }
        }
        .padding(20)
        .frame(width: 480)
        .background(Color(red: 0.098, green: 0.106, blue: 0.125))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(OvernodeTheme.borderSubtle, lineWidth: 1))
    }
}
