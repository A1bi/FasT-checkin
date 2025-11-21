import SwiftUI

struct OrderDetailsView: View {
    var order: Order
    @State var isEditing = false
    @State var selectedTickets = Set<Ticket>()
    @State var additionallyCheckedInTickets = Set<Ticket>()
    @Environment(\.dismiss) var dismiss
    
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
        Text("\(order.tickets.count) Tickets")
            .font(.title3)
        List(order.tickets, id: \.self, selection: $selectedTickets) { ticket in
            if #available(iOS 17.0, *) {
                TicketsListEntry(ticket: ticket, forceCheckIn: additionallyCheckedInTickets.contains(ticket))
                    .selectionDisabled(ticket.checkedIn)
            } else {
                TicketsListEntry(ticket: ticket, forceCheckIn: additionallyCheckedInTickets.contains(ticket))
            }
        }
        .navigationTitle("Bestellung \(order.number)")
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .animation(.default, value: isEditing)
        .toolbar {
            ToolbarItemGroup(placement: .confirmationAction) {
                if isEditing {
                    Button("Done", systemImage: "checkmark") {
                        for ticket in selectedTickets {
                            additionallyCheckedInTickets.insert(ticket)
                        }
                        isEditing = false
                    }
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if !isEditing {
                    Button("einchecken", systemImage: "person.fill.checkmark.rtl", action: {
                        isEditing = true
                    })
                }
                Link(destination: URL(string: "https://www.theater-kaisersesch.de/vorverkauf/bestellungen/\(order.id)")!) {
                    Image(systemName: "safari")
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("schließen", systemImage: "xmark", action: {
                    dismiss()
                })
            }
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailsView(order: SampleData.shared.order)
    }
}
