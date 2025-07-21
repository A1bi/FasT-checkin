//
//  FasTBroadcastReceiver.swift
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.25.
//  Copyright © 2025 Albisigns. All rights reserved.
//

import Foundation
import ActionCableSwift

class FasTBroadcastReceiver : NSObject {
    private let client: ACClient
    private let channel: ACChannel
    
    override init() {
        let clientOptions: ACClientOptions = .init(debug: false, reconnect: true)
        
        #if DEBUG
        self.client = .init(stringURL: "ws://localhost:3000/cable", options: clientOptions)
        client.headers = ["Origin": "http://localhost:3000"]
        #else
        self.client = .init(stringURL: "wss://www.theater-kaisersesch.de/cable", options: clientOptions)
        client.headers = ["Origin": "https://www.theater-kaisersesch.de"]
        #endif
        
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
