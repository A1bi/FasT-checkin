struct SampleData {
    static let shared = SampleData()
    
    var order: Order {
        var order = Order(
            id: Int64.random(in: 1...1000),
            number: String(Int.random(in: 100000...999999)),
            firstName: ["John", "Roger", "Freddie", "Brian"].randomElement()!,
            lastName: ["Deacon", "Taylor", "Mercury", "May"].randomElement()!,
            paid: Bool.random()
        )
        for i in 1...Int.random(in: 1...5) {
            let ticket = Ticket(
                id: Int64.random(in: 1...1000),
                number: "\(order.number)-\(i)",
                seat: "\(["A", "B", "C", "D"].randomElement()!)\(Int.random(in: 1...100))",
                checkedIn: Bool.random()
            )
            order.tickets.append(ticket)
        }
        return order
    }
    
    var orders: [Order] {
        var orders: [Order] = []
        for _ in 1...Int.random(in: 10...25) {
            orders.append(order)
        }
        return orders
    }
}
