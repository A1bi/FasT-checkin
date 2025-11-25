import Foundation

enum OrderCheckInStatus {
    case none
    case partial
    case full
}

struct Order: Hashable, Decodable, Identifiable {
    var id: Int64
    var number: String
    var firstName: String?
    var lastName: String?
    var paid: Bool
    var balance: Float
    var tickets: [Ticket] = []
    
    var fullName: String {
        "\(firstName ?? "?") \(lastName ?? "?")"
    }
    
    var sortedFullName: String {
        "\(lastName ?? "?"), \(firstName ?? "?")"
    }
    
    var checkInStatus: OrderCheckInStatus {
        switch tickets.filter({ $0.checkedIn }).count {
        case tickets.count:
            .full
        case 0:
            .none
        default:
            .partial
        }
    }
}
