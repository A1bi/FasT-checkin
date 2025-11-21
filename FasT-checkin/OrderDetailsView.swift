import SwiftUI

struct OrderDetailsView: View {
    var order: Order
    
    var body: some View {
        VStack {
            Text(order.fullName)
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                if (order.paid) {
                    Image(systemName: "checkmark.square.fill").foregroundStyle(.green)
                    Text("bezahlt")
                } else {
                    Image(systemName: "xmark.square.fill").foregroundStyle(.red)
                    Text("nicht bezahlt")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
        .padding()
        List {
            Section(header: Text("\(order.tickets.count) Tickets")) {
                ForEach(order.tickets) { ticket in
                    TicketsListEntry(ticket: ticket)
                }
            }
        }
        .navigationTitle("Bestellung \(order.number)")
    }
}

#Preview {
    NavigationStack {
        OrderDetailsView(order: SampleData.shared.order)
    }
}
