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

class CollectionViewerInstance : PageInstance {
    
    var view : CollectionViewer?
    var catalogue : LineCatalogue

    override init(_ library : MusicLibrary, _ appData : AppData, _ content : ContentView) {
        self.catalogue = LineCatalogue(title: "", items: [])
        
        super.init(library, appData, content)
        view = CollectionViewer(inst: self)
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
