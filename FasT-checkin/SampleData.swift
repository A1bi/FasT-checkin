struct SampleData {
  static let shared = SampleData()

  var order: Order {
    var order = Order(
      id: Int64.random(in: 1...1000),
      number: orderNumber(),
      firstName: ["John", "Roger", "Freddie", "Brian"].randomElement()!,
      lastName: ["Deacon", "Taylor", "Mercury", "May"].randomElement()!,
      paid: Bool.random(),
      balance: Float.random(in: 1...30)
    )
    for i in 1...Int.random(in: 3...5) {
      order.tickets.append(ticket(i: i))
    }
    return order
  }

  func ticket(order: Order? = nil, i: Int? = nil) -> Ticket {
    Ticket(
      id: Int64.random(in: 1...1000),
      number: "\(order != nil ? order!.number : orderNumber())-\(i ?? Int.random(in: 1...5))",
      type: ["Erwachsene", "Ermäßigt", "Freikarte"].randomElement()!,
      seat: "\(["A", "B", "C", "D"].randomElement()!)\(Int.random(in: 1...100))",
      invalidated: Bool.random(),
      checkedIn: Bool.random()
    )
  }

  var orders: [Order] {
    var orders: [Order] = []
    for _ in 1...Int.random(in: 10...25) {
      orders.append(order)
    }
    return orders
  }

  private func orderNumber() -> String {
    String(Int.random(in: 100000...999999))
  }
}
