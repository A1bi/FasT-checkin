import SwiftUI

struct TicketsListEntry: View {
    @StateObject var ticket: Ticket
    
    var body: some View {
        HStack {
            if #available(iOS 17.0, *) {
                Image(systemName: iconName)
                    .foregroundStyle(iconStyle)
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Image(systemName: iconName)
                    .foregroundStyle(iconStyle)
            }
            Text(ticket.number)
                .font(.system(.body, design: .monospaced))
            Text(ticket.type)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
            if let seat = ticket.seat {
                Text(seat)
            }
        }
    }
    
    private var iconName: String {
        if ticket.checkedIn {
            return "checkmark.circle.fill"
        } else {
            return "circle.badge.questionmark"
        }
    }
    
    private var iconStyle: Color {
        if ticket.checkedIn {
            return .green
        } else {
            return .yellow
        }
    }
}

#Preview {
    TicketsListEntry(ticket: SampleData.shared.ticket())
}
