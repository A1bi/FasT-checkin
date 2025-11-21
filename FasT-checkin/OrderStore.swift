import Foundation

enum OrderFilterType: String, CaseIterable, Identifiable {
    case all = "alle"
    case unpaid = "unbezahlt"
    case notFullyCheckedIn = "nicht eingecheckt"
    
    var id: String { self.rawValue }
}

class OrderStore: ObservableObject {
    @Published var orders: [Order]
    @Published var filteredOrders: [Order]
    @Published var filterType: OrderFilterType = .all {
        didSet {
            updateFilteredOrders()
        }
    }
    @Published var searchQuery: String = "" {
        didSet {
            updateFilteredOrders()
        }
    }
    
    init() {
        self.orders = SampleData.shared.orders
        self.filteredOrders = SampleData.shared.orders
    }
    
    private func updateFilteredOrders() {
        switch filterType {
        case .unpaid:
            filteredOrders = orders.filter { !$0.paid }
        case .notFullyCheckedIn:
            filteredOrders = orders.filter { $0.checkInStatus != .full }
        default:
            filteredOrders = orders
        }
        
        if !searchQuery.isEmpty {
            filteredOrders = sort(filteredOrders.filter {
                $0.lastName.contains(searchQuery) || $0.firstName.contains(searchQuery) || $0.number.contains(searchQuery)
            })
        }
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
