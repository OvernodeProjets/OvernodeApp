import SwiftUI

public struct SupportView: View {
    @StateObject private var vm = SupportViewModel()
    @ObservedObject var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc.string("support_title"))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(OvernodeTheme.textPrimary)
                        Text(loc.string("support_subtitle"))
                            .font(.system(size: 13))
                            .foregroundColor(OvernodeTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { vm.showCreateModal = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text(loc.string("support_new_ticket"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundColor(Color.black)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                
                // Content: Either list or active ticket
                if let active = vm.selectedTicket {
                    SupportTicketDetailView(vm: vm, ticket: active) {
                        vm.selectedTicket = nil
                        vm.loadTickets()
                    }
                } else {
                    SupportTicketListView(vm: vm)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .background(OvernodeTheme.background)
        .sheet(isPresented: $vm.showCreateModal) {
            CreateTicketModalView(vm: vm, isPresented: $vm.showCreateModal)
        }
        .onAppear {
            vm.loadTickets()
        }
    }
}
