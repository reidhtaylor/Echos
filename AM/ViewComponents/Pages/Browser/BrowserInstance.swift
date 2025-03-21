//
//  PlayableItem.swift
//  AM
//
//  Created by Reid Taylor on 8/6/24.
//

import Foundation
import AppKit
import SwiftUI
import MusicKit

class BrowserInstance : PageInstance {
    
    var view : Browser?

    override init(_ library : MusicLibrary, _ appData : AppData, _ content : ContentView) {
        super.init(library, appData, content)
        view = Browser(inst: self)
    }
    
    public override func draw() -> AnyView {
        if let view = view {
            return AnyView(view)
        } else {
            return AnyView(ZStack {
                Color.black
            })
        }
    }
}
