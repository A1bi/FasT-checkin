import Foundation

class Ticket: Hashable, Decodable, Identifiable, ObservableObject {
    var id: Int64
    var number: String
    var type: String
    var seat: String?
    var invalidated: Bool
    @Published var checkedIn: Bool
    
    static func == (t1: Ticket, t2: Ticket) -> Bool {
        t1.id == t2.id
    }
    
    init(id: Int64, number: String, type: String, seat: String?, invalidated: Bool, checkedIn: Bool) {
        self.id = id
        self.number = number
        self.type = type
        self.seat = seat
        self.invalidated = invalidated
        self.checkedIn = checkedIn
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, number, type, seat, invalidated, checkedIn
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        number = try container.decode(String.self, forKey: .number)
        type = try container.decode(String.self, forKey: .type)
        seat = try container.decodeIfPresent(String.self, forKey: .seat)
        invalidated = try container.decode(Bool.self, forKey: .invalidated)
        checkedIn = try container.decode(Bool.self, forKey: .checkedIn)
    }
}
