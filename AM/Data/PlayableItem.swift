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

enum PlayableItemType {
    case unknown
    case song
    case album
    case playlist
    case artist
    
    var description: String {
        switch self {
            case .unknown: return "Unknown"
            case .song: return "Song"
            case .album: return "Album"
            case .playlist: return "Playlist"
            case .artist: return "Artist"
        }
    }
}

enum PlayableItemSort {
    case dateReleased
    case dateAdded
    case artistName
    case albumName
    case songName
    case popularity
    
    var description: String {
        switch self {
            case .dateReleased: return "Date Released"
            case .dateAdded: return "Date Added"
            case .artistName: return "Artist Name"
            case .albumName: return "Album Name"
            case .songName: return "Song Name"
            case .popularity: return "Popularity"
        }
    }
}

class PlayableItem : Equatable, Identifiable, Hashable {
    let itemType : PlayableItemType
    
    // Apple Music
    var itemAM : MusicItem? = nil
    var itemSongAM : Song? = nil
    var itemAlbumAM : Album? = nil
    var itemPlaylistAM : Playlist? = nil
    var itemArtistAM : Artist? = nil
    
    // Spotify
    var itemSP : [String:Any] = [:]
    var itemSongSP : SpotifySong? = nil
    var itemAlbumSP : SpotifyAlbum? = nil
    var itemPlaylistSP : SpotifyPlaylist? = nil
    var itemArtistSP : SpotifyArtist? = nil
    
    // Apple Music
    public init(_item : MusicItem, _itemType : PlayableItemType) {
        itemType = _itemType
        itemAM = _item
        
        Task {
            if itemType == .song {
                // Load Song
                var req = MusicLibraryRequest<Song>()
                req.filter(matching: \.id, equalTo: itemAM!.id)
                let res = try await req.response()
                guard let song = res.items.first else { return }
                itemSongAM = song
            }
            else if itemType == .album {
                // Load Album
                var req = MusicLibraryRequest<Album>()
                req.filter(matching: \.id, equalTo: itemAM!.id)
                let res = try await req.response()
                guard let album = res.items.first else { return }
                itemAlbumAM = album
            }
            else if itemType == .playlist {
                // Load Playlist
                var req = MusicLibraryRequest<Playlist>()
                req.filter(matching: \.id, equalTo: itemAM!.id)
                let res = try await req.response()
                guard let playlist = res.items.first else { return }
                itemPlaylistAM = playlist
            }
            else if itemType == .artist {
                // Load Artist
                var req = MusicLibraryRequest<Artist>()
                req.filter(matching: \.id, equalTo: itemAM!.id)
                let res = try await req.response()
                guard let artist = res.items.first else { return }
                itemArtistAM = artist
            }
        }
    }
    // Spotify
    public init(json : [String:Any], _itemType : PlayableItemType) {
        itemType = _itemType
        itemSP = json
        
        Task {
            if itemType == .song {
                itemSongSP = SpotifySong(itemSP)
            }
            else if itemType == .album {
                itemAlbumSP = SpotifyAlbum(itemSP)
            }
            else if itemType == .playlist {
                itemPlaylistSP = SpotifyPlaylist(itemSP)
            }
            else if itemType == .artist {
                itemArtistSP = SpotifyArtist(itemSP)
            }
        }
    }
    
    // Takes a set of items and plays the first and adds the rest to the queue
    public func playSet(_ items : [PlayableItem], _ lib : MusicLibrary) async {
        if (items.count == 1) {
            await lib.playSong(items[0].itemSongAM!)
        }
        else {
            await lib.addSongsToQueue(Array(items), lib.queueIndex + 1)
            await lib.playSong(lib.queueIndex + 1) // Play first song
        }
    }
    public func getContainingSongs(_ lib : MusicLibrary) async -> [PlayableItem] {
        var songs : [PlayableItem] = []
            switch itemType {
            case .song: songs = [self]
            case .album: songs = await lib.getSongs(itemAlbumAM!)
            case .playlist: songs = await lib.getPlaylistSongs(self)
            case .artist: /* TODO ** PLAY */ break
            case .unknown: break
        }
        return songs;
    }
    
    public func play(_ lib : MusicLibrary) async {
        await playSet(getContainingSongs(lib), lib)
    }
    public func shuffle(_ lib : MusicLibrary) async {
        await playSet(getContainingSongs(lib).shuffled(), lib)
    }
    public func shuffleNext(_ lib : MusicLibrary) async {
        let songs = await getContainingSongs(lib).shuffled()
        await lib.addSongsToQueue(songs, lib.queueIndex + 1)
    }
    public func shuffleMix(_ lib : MusicLibrary) async {
//        let songs = await getContainingSongs(lib).shuffled()
//        await lib.addSongsToQueue(songs)
    }
    public func shuffleAfter(_ lib : MusicLibrary) async {
        let songs = await getContainingSongs(lib).shuffled()
        await lib.addSongsToQueue(songs)
    }
    
    public func queueNext(_ lib : MusicLibrary) async {
        let songs = await getContainingSongs(lib)
        await lib.addSongsToQueue(songs, lib.queueIndex + 1)
    }
    public func queueAfter(_ lib : MusicLibrary) async {
        let songs = await getContainingSongs(lib)
        await lib.addSongsToQueue(songs)
    }
    
    public func getID() -> String {
        if itemSP.keys.count > 0 {
            return itemSongSP?.songID ?? itemAlbumSP?.albumID ?? itemPlaylistSP?.playlistID ?? itemArtistSP?.artistID ?? "Unknown Title"
        }
        return itemSongAM?.id.rawValue ?? itemAlbumAM?.id.rawValue ?? itemPlaylistAM?.id.rawValue ?? itemArtistAM?.id.rawValue ?? ""
    }
    public func getName() -> String {
        if itemSP.keys.count > 0 {
            return itemSongSP?.name ?? itemAlbumSP?.name ?? itemPlaylistSP?.playlistName ?? itemArtistSP?.name ?? "Unknown Title"
        }
        return itemSongAM?.title ?? itemAlbumAM?.title ?? itemPlaylistAM?.name ?? itemArtistAM?.name ?? "Unknown Title"
    }
    public func getArtistName() -> String {
        if itemSP.keys.count > 0 {
            return itemSongSP?.artistName ?? itemAlbumSP?.artistName ?? itemArtistSP?.name ?? "Unknown Artist"
        }
        return itemSongAM?.artistName ?? itemAlbumAM?.artistName ?? itemArtistAM?.name ?? "Unknown Artist"
    }
    public func getArtwork() -> Artwork? {
        if itemSP.keys.count > 0 {
            return nil
        }
        return itemSongAM?.artwork ?? itemAlbumAM?.artwork ?? itemPlaylistAM?.artwork ?? itemArtistAM?.artwork ?? nil
    }
    public func getArtworkURL() -> String {
        return itemPlaylistSP?.artworkURL ?? itemAlbumSP?.artworkURL ?? itemSongSP?.artworkURL ?? itemArtistSP?.artworkURL ?? ""
    }
    public func getTrackNumber() -> Int {
        return itemSongAM?.trackNumber ?? itemSongSP?.trackNumber ?? -1
    }
    public func getPlayCount() -> Int {
        return itemSongAM?.playCount ?? itemSongSP?.popularity ?? 0
    }
    public func getDuration() -> Double {
        return itemSongAM?.duration ?? itemSongSP?.duration ?? 0
    }
    public func getAlbumTitle() -> String {
        if itemSP.keys.count > 0 {
            return itemSongSP?.albumName ?? itemAlbumSP?.name ?? itemSongSP?.albumName ?? "Unknown Album"
        }
        return itemSongAM?.albumTitle ?? itemAlbumAM?.title ?? "Unknown Album"
    }
    public func getShortDesc() -> String {
        return itemPlaylistAM?.shortDescription ?? itemPlaylistSP?.description ?? "Unknown Desc"
    }
    public func getSubtitle() -> String {
        return itemSongAM?.albumTitle ?? itemAlbumSP?.artistName ?? itemSongSP?.albumName ?? itemAlbumAM?.artistName ?? ""
    }
    public func getYear() -> String {
//        if itemAlbumAM == nil || itemAlbumAM!.releaseDate == nil { return "" }
//        return String(Calendar.current.component(.year, from: itemAlbumAM!.releaseDate!))
        return "2024"
    }
    public func getAddedDate() -> Date {
//        if itemAlbumAM == nil || itemAlbumAM!.releaseDate == nil { return "" }
//        return String(Calendar.current.component(.year, from: itemAlbumAM!.releaseDate!))
        return itemSongAM?.libraryAddedDate ?? itemAlbumAM?.libraryAddedDate ?? itemArtistAM?.libraryAddedDate ?? itemPlaylistAM?.libraryAddedDate ?? Date.distantPast
    }
    
    public static func getSortValue(_ sort: PlayableItemSort, _ item1 : PlayableItem, _ item2 : PlayableItem) -> Bool {
        switch sort {
        case .dateReleased: return item1.getAddedDate() > item2.getAddedDate()
        case .dateAdded: return item1.getAddedDate() < item2.getAddedDate()
        case .artistName: return item1.getArtistName().lowercased() < item2.getArtistName().lowercased()
        case .albumName: return item1.getAlbumTitle().lowercased() < item2.getAlbumTitle().lowercased()
        case .songName: return item1.getName().lowercased() < item2.getName().lowercased()
        case .popularity: return item1.getPlayCount() > item2.getPlayCount()
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemType.description)
        hasher.combine(getID())
    }
    static func == (lhs: PlayableItem, rhs: PlayableItem) -> Bool {
        return lhs.itemType == rhs.itemType && lhs.getID() == rhs.getID()
    }
    
    var id: String {
        itemAM?.id.rawValue ?? ""
    }
}
