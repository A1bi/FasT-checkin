import Foundation
import ActionCableSwift

class FasTBroadcastReceiver : NSObject {
  private let client: ACClient
  private let channel: ACChannel

  override init() {
    let clientOptions: ACClientOptions = .init(debug: false, reconnect: true)
    let apiHost = Bundle.main.object(forInfoDictionaryKey: "API_HOST") as? String ?? ""
    let wsHost = apiHost.replace("http", "ws")
    self.client = .init(stringURL: "\(wsHost)/cable", options: clientOptions)
    client.headers = ["Origin": apiHost]

    let channelOptions: ACChannelOptions = .init(buffering: true, autoSubscribe: true)
    self.channel = client.makeChannel(name: "Ticketing::CheckpointChannel", options: channelOptions)
  }

  @objc public func connect() {
    self.client.connect()
  }

  @objc public func addOnBroadcast(handler: @escaping (Dictionary<String, Any>) -> Void) {
    self.channel.addOnMessage { (channel, optionalMessage) in
      if ((optionalMessage != nil) && ((optionalMessage?.message) != nil)) {
        handler((optionalMessage?.message)!)
      }
    }
  }
}
