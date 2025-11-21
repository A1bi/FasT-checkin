import SwiftUI

struct OrdersList: View {
    @State private var presentedOrder: Order?
    @StateObject private var store = OrderStore()
    
    var body: some View {
        NavigationStack {
            Picker("Select Theme", selection: $store.filterType) {
                ForEach(OrderFilterType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            List(store.filteredOrders, selection: $presentedOrder) { order in
                NavigationLink(value: order) {
                    OrdersListEntry(order: order)
                }
            }
            .searchable(text: $store.searchQuery, prompt: "Name oder Bestellnummer")
            .navigationTitle("Bestellungen")
        }
        .onAppear {
            store.filterType = .unpaid
        }
    }
}

#Preview {
    OrdersList()
}
