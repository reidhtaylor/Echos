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

class PageInstance {
    @ObservedObject var library: MusicLibrary
    @State var appData: AppData
    var content: ContentView
    
    public init(_ library : MusicLibrary, _ appData : AppData, _ content : ContentView) {
        self.library = library
        self.appData = appData
        self.content = content
    }
    
    public func draw() -> AnyView {
        AnyView(AnyView(ZStack { }))
    }
}
