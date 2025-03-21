//
//  CallbackEvent.swift
//  AM
//
//  Created by Reid Taylor on 11/9/24.
//

class CallbackEvent<Args> {
    private var eventHandlers: [String:(Args) -> Void] = [:]
    
    func subscribe(_ key: String, _ value: @escaping (Args) -> Void) {
        eventHandlers[key] = value
    }
    
    func trigger(_ args : Args = ()) {
        for handler in eventHandlers.values {
            handler(args)
        }
    }
}
