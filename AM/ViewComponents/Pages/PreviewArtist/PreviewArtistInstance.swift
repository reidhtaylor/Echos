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

class PreviewArtistInstance : PageInstance, ObservableObject, Equatable, Hashable {
    
    var view : PreviewArtist?
    var artist : PlayableItem
    
    init(_ library : MusicLibrary, _ appData : AppData, _ content : ContentView, artist : PlayableItem) {
        self.artist = artist
        super.init(library, appData, content)
        view = PreviewArtist(inst: self)
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(artist.getName())
    }
    static func == (lhs: PreviewArtistInstance, rhs: PreviewArtistInstance) -> Bool {
        return lhs.artist == rhs.artist
    }
}
