import SwiftUI

struct OrdersListEntry: View {
  var order: Order

  var body: some View {
    HStack {
      Image(systemName: iconName).foregroundStyle(iconStyle)
      Text(order.sortedFullName)
      Spacer()
      Text(order.number)
        .font(.system(.body, design: .monospaced))
    }
  }

  private var iconName: String {
    switch order.checkInStatus {
    case .partial:
      return "circle.bottomhalf.filled.inverse"
    case .full:
      return "checkmark.circle.fill"
    default:
      return "circle"
    }
  }

  private var iconStyle: Color {
    switch order.checkInStatus {
    case .partial:
      return .yellow
    case .full:
      return .green
    default:
      return .red
    }
  }
}

#Preview {
  OrdersListEntry(order: SampleData.shared.order)
}
