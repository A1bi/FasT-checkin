import Foundation

enum OrderFilterType: String, CaseIterable, Identifiable {
    case all = "alle"
    case unpaid = "unbezahlt"
    case notFullyCheckedIn = "einzuchecken"
    
    var id: String { self.rawValue }
}

@MainActor
class OrderStore: ObservableObject {
    private let apiHost: String
    private let apiKey: String
    @Published var orders: [Order] = []
    @Published var filteredOrders: [Order] = []
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
        apiHost = Self.configValue(for: "API_HOST")
        apiKey = Self.configValue(for: "API_KEY")
    }
    
    func fetch() async {
        do {
            let request = apiRequestForPath(path: "ticketing/check_ins/orders")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            self.orders = try decoder.decode([Order].self, from: data)
            
            updateFilteredOrders()
        } catch {
            print("Error fetching orders:", error)
        }
    }
    
    func checkInTickets(tickets: [Ticket]) async {
        do {
            var request = apiRequestForPath(path: "ticketing/check_ins")
            request.httpMethod = "POST"
            
            var checkIns: [Dictionary<String, String>] = []
            for ticket in tickets {
                let checkIn: Dictionary<String, String> = [
                    "ticket_id": String(ticket.id),
                    "date": Date().ISO8601Format(),
                    "medium": "box_office_direct"
                ]
                checkIns.append(checkIn)
            }
            let message: Dictionary<String, Array> = ["check_ins": checkIns]
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Error checking in tickets:", error)
        }
    }
    
    func markOrderAsPaid(order: Order) async {
        do {
            var request = apiRequestForPath(path: "ticketing/check_ins/orders/\(order.id)/mark_as_paid")
            request.httpMethod = "POST"
            
            let _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Error marking order as paid:", error)
        }
    }
    
    private func apiRequestForPath(path: String) -> URLRequest {
        let url = URL(string: "\(apiHost)/api/\(path)")!
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
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
        
        filteredOrders = sort(filteredOrders)
        
        if !searchQuery.isEmpty {
            filteredOrders = filteredOrders.filter {
                $0.lastName != nil && $0.lastName!.range(of: searchQuery, options: .caseInsensitive) != nil ||
                $0.firstName != nil && $0.firstName!.range(of: searchQuery, options: .caseInsensitive) != nil ||
                $0.number.contains(searchQuery)
            }
        }
    }
    
    private func sort(_ orders: [Order]) -> [Order] {
        return orders.sorted {
            if $0.lastName != $1.lastName {
                $0.lastName ?? "" < $1.lastName ?? ""
            } else {
                $0.firstName ?? "" < $1.firstName ?? ""
            }
        }
    }
    
    static private func configValue(for key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
