import SwiftUI

struct OrdersList: View {
    @State private var presentedOrder: Order?
    @StateObject private var store = OrderStore()
    
    var body: some View {
        NavigationStack {
            List(store.orders, selection: $presentedOrder) { order in
                NavigationLink(value: order) {
                    OrdersListEntry(order: order)
                }
            }
            .searchable(text: $store.searchQuery, prompt: "Name oder Bestellnummer")
            .navigationTitle("Bestellungen")
        }
    }
}

#Preview {
    OrdersList()
}
