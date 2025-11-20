import Foundation

class OrderStore: ObservableObject {
    private var allOrders = SampleData.shared.orders
    @Published var orders: [Order]
    @Published var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                orders = allOrders
            } else {
                orders = sort(allOrders.filter {
                    $0.lastName.contains(searchQuery) || $0.firstName.contains(searchQuery) || $0.number.contains(searchQuery)
                })
            }
        }
    }
    
    init() {
        orders = allOrders
    }
    
    private func sort(_ orders: [Order]) -> [Order] {
        return orders.sorted {
            if $0.lastName != $1.lastName {
                $0.lastName < $1.lastName
            } else {
                $0.firstName < $1.firstName
            }
        }
    }
}
