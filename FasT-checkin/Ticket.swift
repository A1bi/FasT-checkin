import Foundation

struct Ticket: Hashable, Decodable, Identifiable {
    var id: Int64
    var number: String
    var type: String
    var seat: String?
    var checkedIn: Bool
}
