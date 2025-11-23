import Foundation

class Ticket: Hashable, Decodable, Identifiable, ObservableObject {
    var id: Int64
    var number: String
    var type: String
    var seat: String?
    @Published var checkedIn: Bool
    
    static func == (t1: Ticket, t2: Ticket) -> Bool {
        t1.id == t2.id
    }
    
    init(id: Int64, number: String, type: String, seat: String?, checkedIn: Bool) {
        self.id = id
        self.number = number
        self.type = type
        self.seat = seat
        self.checkedIn = checkedIn
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, number, type, seat, checkedIn
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        number = try container.decode(String.self, forKey: .number)
        type = try container.decode(String.self, forKey: .type)
        seat = try container.decodeIfPresent(String.self, forKey: .seat)
        checkedIn = try container.decode(Bool.self, forKey: .checkedIn)
    }
}
