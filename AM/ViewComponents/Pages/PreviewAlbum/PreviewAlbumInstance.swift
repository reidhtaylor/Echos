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

class PreviewAlbumInstance : PageInstance, ObservableObject, Equatable, Hashable {
    
    var view : PreviewAlbum?
    var album : PlayableItem
    @Published var songs : [PlayableItem] = []
    
    init(_ library : MusicLibrary, _ appData : AppData, _ content : ContentView, album : PlayableItem) {
        self.album = album
        super.init(library, appData, content)
        view = PreviewAlbum(inst: self)
        
        Task {
            if library.musicSource == .appleMusic {
                self.songs = (await library.getSongs(album.itemAlbumAM!)).sorted(by: { $0.getTrackNumber() < $1.getTrackNumber() })
            }
            else {
                library.getSongs(album.itemAlbumSP!) { tracks in
                    self.songs = tracks.sorted(by: { $0.getTrackNumber() < $1.getTrackNumber() })
                }
            }
        }
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
        hasher.combine(songs.count)
        hasher.combine(album.getName())
    }
    static func == (lhs: PreviewAlbumInstance, rhs: PreviewAlbumInstance) -> Bool {
        return lhs.album == rhs.album && lhs.songs.count == rhs.songs.count
    }
}
