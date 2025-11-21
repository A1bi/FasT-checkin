import SwiftUI

struct OrdersList: View {
    @State private var presentedOrder: Order?
    @StateObject private var store = OrderStore()
    @Environment(\.dismiss) var dismiss
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("schließen", systemImage: "xmark", action: {
                        dismiss()
                    })
                }
            }
        }
        .onAppear {
            store.filterType = .unpaid
        }
    }
}

#Preview {
    OrdersList()
}
