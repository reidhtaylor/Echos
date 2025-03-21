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

class PreviewPlaylistInstance : PageInstance, ObservableObject, Equatable, Hashable {
    
    var view : PreviewPlaylist?
    var playlist : PlayableItem
    @Published var songs : [PlayableItem] = []
    
    @Published var sortMode : PlayableItemSort = .albumName
    @Published var sortDirection : Int = 1
    
    init(_ library : MusicLibrary, _ appData : AppData, _ content : ContentView, playlist : PlayableItem) {
        self.playlist = playlist
        super.init(library, appData, content)
        view = PreviewPlaylist(inst: self)
        
        Task {
            sortMode = .albumName
            if library.musicSource == .appleMusic {
                self.songs = await library.getPlaylistSongs(playlist)
                self.sort()
            }
            else {
                library.getPlaylistSongs(playlist.itemPlaylistSP!) { tracks in
                    self.songs = tracks
                    self.sort()
                }
            }
        }
        
    }
    
    public func sort() {
        self.songs = self.songs.sorted(by: { PlayableItem.getSortValue(sortMode, $0, $1) })
        if sortDirection == 0 {
            self.songs = self.songs.reversed()
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
        hasher.combine(playlist.getName())
    }
    static func == (lhs: PreviewPlaylistInstance, rhs: PreviewPlaylistInstance) -> Bool {
        return lhs.playlist == rhs.playlist && lhs.songs.count == rhs.songs.count
    }
}
