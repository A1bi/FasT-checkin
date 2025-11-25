import SwiftUI

struct OrdersList: View {
    @StateObject private var store = OrderStore()
    @Environment(\.dismiss) var dismiss
    @State private var firstAppearance = true
    
    var body: some View {
        NavigationStack {
            Picker("Select Theme", selection: $store.filterType) {
                ForEach(OrderFilterType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            List {
                Section {
                    ForEach(store.filteredOrders) { order in
                        NavigationLink(value: order) {
                            OrdersListEntry(order: order)
                        }
                    }
                } header: {
                    Text("\(store.filteredOrders.count) Bestellungen")
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
