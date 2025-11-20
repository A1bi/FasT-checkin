import SwiftUI

struct OrdersListEntry: View {
    var order: Order
    
    var body: some View {
        HStack {
            Text(order.sortedFullName)
            Spacer()
            Text(order.number)
                .font(.system(.body, design: .monospaced))
        }
    }
}

#Preview {
    OrdersListEntry(order: SampleData.shared.order)
}
