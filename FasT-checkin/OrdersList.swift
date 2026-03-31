import SwiftUI

extension EnvironmentValues {
  @Entry var dismissModal: DismissAction? = nil
}

struct OrdersList: View {
  @StateObject private var store = OrderStore()
  @Environment(\.dismiss) var dismiss
  @State private var firstAppearance = true

  var body: some View {
    NavigationView {
      List {
        Section {
          ForEach(store.filteredOrders) { order in
            NavigationLink(destination: OrderDetailsView(order: order)
              .environment(\.dismissModal, dismiss)
            ) {
              OrdersListEntry(order: order)
            }
          }
          .listRowInsets(.init(top: 0, leading: 15, bottom: 0, trailing: 15))
        } header: {
          VStack {
            Picker("Select Theme", selection: $store.filterType) {
              ForEach(OrderFilterType.allCases) { type in
                Text(type.rawValue).tag(type)
              }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            Text("\(store.filteredOrders.count) Bestellungen")
          }
          .padding(.vertical, 15)
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
      }
      .searchable(text: $store.searchQuery, prompt: "Name oder Bestellnummer")
      .navigationTitle("Bestellungen")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("schließen", systemImage: "xmark", action: {
            dismiss()
          })
        }
      }
      .refreshable {
        await store.fetch()
      }
      .onAppear {
        Task {
          await store.fetch()

          if firstAppearance {
            store.filterType = .unpaid
            if store.filteredOrders.isEmpty {
              store.filterType = .notFullyCheckedIn
            }
            firstAppearance = false
          }
        }
      }
    }
  }
}

#Preview {
  OrdersList()
}
