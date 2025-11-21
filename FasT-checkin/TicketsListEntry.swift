import SwiftUI

struct TicketsListEntry: View {
    var ticket: Ticket
    var forceCheckIn: Bool = false
    
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
        if checkedIn {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var iconStyle: Color {
        if checkedIn {
            return .green
        } else {
            return .red
        }
    }
    
    private var checkedIn: Bool {
        forceCheckIn || ticket.checkedIn
    }
}

#Preview {
    TicketsListEntry(ticket: SampleData.shared.ticket())
}
