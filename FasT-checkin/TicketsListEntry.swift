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
      if #available(iOS 16.0, *) {
        Text(ticket.number)
          .font(.system(.body, design: .monospaced))
          .foregroundStyle(labelColor)
          .strikethrough(ticket.invalidated)
        Text(ticket.type)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(labelColor)
          .strikethrough(ticket.invalidated)
          .padding(.horizontal, 10)
      } else {
        Text(ticket.number)
          .font(.system(.body, design: .monospaced))
          .foregroundStyle(labelColor)
        Text(ticket.type)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(labelColor)
          .padding(.horizontal, 10)
      }
      if let seat = ticket.seat {
        Text(seat)
      }
    }
  }

  private var iconName: String {
    if ticket.invalidated {
      return "xmark"
    } else if ticket.checkedIn {
      return "checkmark.circle.fill"
    } else {
      return "circle.badge.questionmark"
    }
  }
  
  private var iconStyle: Color {
    if ticket.invalidated {
      return .red
    } else if ticket.checkedIn {
      return .green
    } else {
      return .yellow
    }
  }

  private var labelColor: Color {
    ticket.invalidated ? .gray : .primary
  }
}

#Preview {
  TicketsListEntry(ticket: SampleData.shared.ticket())
}
