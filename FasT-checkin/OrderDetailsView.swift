import SwiftUI

struct OrderDetailsView: View {
  @State var order: Order
  @State var isEditing = false
  @State var selectedTickets = Set<Ticket>()
  @State private var markAsPaidConfirmationShown = false
  @State private var checkInAllTicketsConfirmationShown = false
  @Environment(\.dismissModal) var dismiss
  let store = OrderStore()

  var body: some View {
    List(selection: $selectedTickets) {
      Section {
        ForEach(order.tickets) { ticket in
          Group {
            if #available(iOS 17.0, *) {
              TicketsListEntry(ticket: ticket)
                .selectionDisabled(ticket.checkedIn)
            } else {
              TicketsListEntry(ticket: ticket)
            }
          }
          .tag(ticket)
        }
      } header: {
        VStack {
          Text(order.fullName)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 5)
          HStack {
            HStack {
              Image(systemName: "eurosign")
              Text(order.paid ? "bezahlt" : "nicht bezahlt")
            }
            .foregroundStyle(.white)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 4).fill(order.paid ? .green : .red))
            .frame(maxWidth: .infinity, alignment: .leading)
            if (!order.paid) {
              Text(abs(order.balance), format: .currency(code: "EUR"))
                .font(.title2)
                .foregroundStyle(.red)
              Text("offen")
            } else {
              EmptyView()
            }
          }
          .padding(.bottom, 10)
          Text("\(order.validTickets.count) Tickets")
        }
      }
    }
    .navigationTitle("Bestellung \(order.number)")
    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    .animation(.default, value: isEditing)
    .toolbar {
      ToolbarItemGroup(placement: .confirmationAction) {
        if isEditing {
          Button("Done", systemImage: "checkmark") {
            let tickets: [Ticket] = Array(selectedTickets)
            checkInTickets(tickets: tickets)

            isEditing = false
          }
        } else {
          EmptyView()
        }
      }
      // if #available(iOS 26.0, *) {
      //     ToolbarSpacer(.fixed, placement: .primaryAction)
      // }
      ToolbarItemGroup(placement: .primaryAction) {
        if !isEditing {
          Link(destination: URL(string: "https://www.theater-kaisersesch.de/vorverkauf/bestellungen/\(order.id)")!) {
            Image(systemName: "safari")
          }
        } else {
          EmptyView()
        }
        if !order.paid && !isEditing {
          Button(action: {
            markAsPaidConfirmationShown = true
          }) {
            Image("mark_as_paid", label: Text("als bezahlt markieren"))
          }
        } else {
          EmptyView()
        }
        if order.checkInStatus != .full && !isEditing {
          Button(action: {
            isEditing = true
          }) {
            Image("check_in", label: Text("einchecken"))
          }
        } else {
          EmptyView()
        }
      }
      // if #available(iOS 26.0, *) {
      //     ToolbarSpacer(.fixed, placement: .primaryAction)
      // }
      ToolbarItem(placement: .primaryAction) {
        Button("schließen", systemImage: "xmark", action: {
          if isEditing {
            isEditing = false
          } else if dismiss != nil {
            dismiss!()
          }
        })
      }
    }
    .alert("Möchten Sie die Bestellung als bezahlt markieren?", isPresented: $markAsPaidConfirmationShown) {
      Button("als bezahlt markieren") {
        withAnimation {
          Task {
            await store.markOrderAsPaid(order: order)
          }

          order.paid = true
        }
        if order.checkInStatus != .full {
          checkInAllTicketsConfirmationShown = true
        }
      }
      Button("abbrechen", role: .cancel) {}
    }
    .alert("Möchten Sie alle Tickets einchecken?", isPresented: $checkInAllTicketsConfirmationShown) {
      Button("alle Tickets einchecken") {
        withAnimation {
          checkInTickets(tickets: order.tickets)
        }
      }
      Button("nicht einchecken", role: .cancel) {}
    }
  }

  private func checkInTickets(tickets: [Ticket]) {
    for ticket in tickets {
      ticket.checkedIn = true
    }

    Task {
      await store.checkInTickets(tickets: tickets)
    }
  }
}

#Preview("paid") {
  NavigationView {
    var order = SampleData.shared.order
    order.paid = true
    return OrderDetailsView(order: order)
  }
}

#Preview("unpaid") {
  NavigationView {
    var order = SampleData.shared.order
    order.paid = false
    return OrderDetailsView(order: order)
  }
}
