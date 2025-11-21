import SwiftUI

struct OrdersList: View {
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
            List(store.filteredOrders) { order in
                NavigationLink(value: order) {
                    OrdersListEntry(order: order)
                }
            }
            .navigationDestination(for: Order.self) { order in
                OrderDetailsView(order: order)
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
        .task {
            await store.fetch()
        }
    }
}

#Preview {
    OrdersList()
}
