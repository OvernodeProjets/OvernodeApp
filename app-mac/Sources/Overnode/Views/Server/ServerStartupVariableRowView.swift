import SwiftUI

public struct ServerStartupVariableRowView: View {
    @Binding var variable: ServerStartupVariable
    let onSave: (String, String) -> Void
    
    public init(variable: Binding<ServerStartupVariable>, onSave: @escaping (String, String) -> Void) {
        self._variable = variable
        self.onSave = onSave
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(variable.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(OvernodeTheme.textPrimary)
                Text(variable.envVariable)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(OvernodeTheme.textSecondary)
            }
            .frame(width: 160, alignment: .leading)
            
            TextField(variable.defaultValue ?? "", text: $variable.serverValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
            
            Button(action: {
                onSave(variable.envVariable, variable.serverValue)
            }) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(Color(red: 0.25, green: 0.78, blue: 0.50))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
