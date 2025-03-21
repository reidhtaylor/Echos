//
//  MusicLibrary.swift
//  AM
//
//  Created by Reid Taylor on 12/19/23.
//

import Foundation
import AppKit
import SwiftUI
import MusicKit

enum MusicSource {
    case none
    case appleMusic
    case spotify
}
@MainActor
final class MusicLibrary : ObservableObject {
    @Published var initialized = false
    @Published var loaded = false
    @Published var signing = false
    @Published var selectingSource = true
    @Published var loadDescription = ""
    
    // Spotify
    @Published var spotifyAuthURL : URL? = nil
    @Published var spotifyAuthResponse : String = ""
    @Published var spotifyAuthCode : String = ""
    @Published var spotifyAccessToken : String = ""
    @Published var spotifyProfile : Dictionary<String, String> = [:]
    static let redirectURI : String = "http://localhost:8888/callback"
    
    @Published var songs: [PlayableItem] = []
    @Published var albums: [PlayableItem] = []
    @Published var playlists: [PlayableItem] = []
    @Published var artists: [PlayableItem] = []
    
    private var playlistTracksRegister = 0;
    private var likedTracksLoadedFlag = 0;
    private var artistsRegister = 0;
    
    @Published var currentlyPlaying: PlayableItem? = nil
    
    @Published var queue : [PlayableItem] = []
    @Published var queueIndex : Int = -1
    
    @Published var currentPlayback = 0.0
    var playbackTimer: Timer? = nil
    @Published var projectedPlaybackState : MusicPlayer.PlaybackStatus = .stopped
    
    @Published var musicSource : MusicSource = .none
    private var loadProgress : [String] = []
    
    @Published var pinnedItems: [PlayableItem] = [] // Song / Album / Playlist
    @Published var catalogues : [LineCatalogue] = []
    
    @Published var onLibraryUpdate : CallbackEvent<()> = .init()
    @Published var onPlayingSongChanged : CallbackEvent<(PlayableItem?)> = .init()
    @Published var onForcePlaybackUpdte : CallbackEvent<(Double, Double)> = .init()
    
    @Published var ERROR : Int = 777
    
    public func SetupSource(_ source : MusicSource) {
        // Start signing (overlay will pray)
        self.signing = true
        
        Task {
            // Set Source type
            self.musicSource = source
            
            // Authorize Apple Music (1.3s)
            if source == .appleMusic {
                let status = await MusicAuthorization.request()
                if status != .authorized { return }
                
                self.signing = false
                print("- Apple Music has been Authorized")
            }
            // Authorize Spotify
            if source == .spotify {
                // Set static links and keys
                let clientID = "66cf5ef124e2471ba793cac67c7fab5b"
                let clientSecret = "ab71bf713d49496e8af3c85fffc307a2"
                let authURL = "https://accounts.spotify.com/authorize"
                let tokenURL = "https://accounts.spotify.com/api/token"
//                let redirectURL = URL(string: "spotify-ios-quick-start://spotify-login-callback")!
                
                // Instantiate SDK
//                lazy var configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
                
                // Create url to request authorization code
                var components = URLComponents (string: authURL + "?")!
                components.queryItems = [
                    URLQueryItem(name: "client_id", value: clientID),
                    URLQueryItem(name: "response_type", value: "code"),
                    URLQueryItem(name: "scope", value: "user-read-private user-read-email playlist-read-private playlist-read-collaborative user-library-read user-modify-playback-state user-read-playback-state"),
                    URLQueryItem(name: "redirect_uri", value: MusicLibrary.redirectURI),
                    URLQueryItem(name: "state", value: "1234567891234567"),
                    URLQueryItem(name: "show_dialogue", value: "TRUE"),
                ]
                guard let url = components.url else {
                    throw URLError(.badURL)
                }
                
                // Open Login/Auth Page
                spotifyAuthURL = url

                // Wait till Authorization code is recieved (or error)
                while spotifyAuthResponse.count == 0 {
                    try? await Task.sleep(for: .seconds(0.5))
                }
                
                // Process Response
                let responseType = spotifyAuthResponse.split(separator: "?")[1].split(separator: "=")[0]
                if responseType == "code" {
                    // Got Auth Code
                    let response = spotifyAuthResponse.split(separator: "=")[1]
                    let code = response.split(separator: "&")[0]
                    //let state = response.split(separator: "&")[1]
                    spotifyAuthCode = String(code)
                }
                else {
                    // Auth didn't come through
                    let response = spotifyAuthResponse.split(separator: "=")[1]
                    let errorCode = response.split(separator: "&")[0]
                    //let state = response.split(separator: "&")[1]
                    print("ERROR: " + errorCode)
                    return
                }
                
                // Create Access Token Request
                components = URLComponents (string: tokenURL + "?")!
                components.queryItems = [
                    URLQueryItem(name: "grant_type", value: "authorization_code"),
                    URLQueryItem(name: "code", value: spotifyAuthCode),
                    URLQueryItem(name: "redirect_uri", value: MusicLibrary.redirectURI),
                    URLQueryItem(name: "client_id", value: clientID),
                    URLQueryItem(name: "client_secret", value: clientSecret),
                ]
                guard let url = components.url else { throw URLError(.badURL) }
                
                // Request Access Token
                var request = URLRequest(url: url)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
                request.setValue("Basic " + (clientID + ":" + clientSecret).data(using: .utf8)!.base64EncodedString(), forHTTPHeaderField: "Authorization")
                request.httpMethod = "POST"
                
                // Handle Json Response Received
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard let data = data else { return }
                    let jsonData = String(data: data, encoding: .utf8)
                    let jsonResult = try? JSONSerialization.jsonObject(with: Data(jsonData!.utf8), options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]
                    
                    DispatchQueue.main.async {
                        self.spotifyAccessToken = jsonResult?["access_token"] as! String
                        
                        getRequest("https://api.spotify.com/v1/me", authToken: self.spotifyAccessToken, onSuccess: { val in
                            self.spotifyProfile["id"] = val["id"] as? String
                            
                            // Stop signing and start loading assets
                            self.signing = false
                        })
                    }
                }.resume()
                
                print("- Spotify has been Authorized")
            }
        }
    }
    public func LoadSource() {
        // _______________________________ APPLE MUSIC
        self.loadDescription = "Querying Media"
        
        // ****** Apple Music
//        if musicSource == .appleMusic {
//            // LOAD SONGS
//            Task {
//                // ****** Apple Music (1.1s)
//                // Query Songs
//                let rqSongs = MusicLibraryRequest<Song>() // Request song collection
//                let resSongs = try await rqSongs.response()
//                
//                self.songs.removeAll() // Empty songs
//                for song in resSongs.items {
//                    self.songs.append(PlayableItem(_item: song, _itemType: .song))
//                }
//                loadProgress.append("SONGS_LOADED")
//                onLibraryUpdate.trigger()
//            }
//            
//            // LOAD ALBUMS
//            Task {
//                // ****** Apple Music (1.9s)
//                // Query Albums
//                let rqAlbums = MusicLibraryRequest<Album>() // Request album collection
//                let resAlbums = try await rqAlbums.response()
//                
//                self.albums.removeAll() // Empty albums
//                for album in resAlbums.items {
//                    self.albums.append(PlayableItem(_item: album, _itemType: .album))
//                }
//                
//                loadProgress.append("ALBUMS_LOADED")
//                onLibraryUpdate.trigger()
//            }
//            
//            self.loadDescription = "Querying Collections"
//            
//            // LOAD PLAYLISTS
//            Task {
//                // ****** Apple Music
//                // Query Playlists
//                let rqPlaylists = MusicLibraryRequest<Playlist>() // Request playlist collection
//                let resPlaylists = (try await rqPlaylists.response()).items
//                self.playlists.removeAll() // Empty playlists
//                for pl in resPlaylists {
//                    self.playlists.append(PlayableItem(_item: pl, _itemType: .playlist))
//                }
//                
//                for p in self.playlists {
//                    while (p.itemPlaylistAM == nil) { try? await Task.sleep(nanoseconds: 100_000_000) }
//                }
//                
//                loadProgress.append("PLAYLISTS_LOADED")
//                onLibraryUpdate.trigger()
//            }
//            
//            // LOAD ARTISTS
//            Task {
//                // ****** Apple Music
//                // Query Artists
//                let rqArtists = MusicLibraryRequest<Artist>()
//                let resArtists = (try await rqArtists.response()).items
//                self.artists.removeAll()
//                for art in resArtists {
//                    self.artists.append(PlayableItem(_item: art, _itemType: .artist))
//                }
//                for a in self.artists {
//                    while (a.itemArtistAM == nil) { try? await Task.sleep(nanoseconds: 100_000_000) }
//                }
//                
//                loadProgress.append("ARTISTS_LOADED")
//                onLibraryUpdate.trigger()
//            }
//        }
//        // ****** Spotify Music
//        else {
//            
//            let addSpotifyArtist = { (artist: [String: Any]) -> Void in
//                let item = PlayableItem(json: artist, _itemType: .artist)
//                self.artists.append(item)
//            }
//            let addSpotifyAlbum = { (album: [String: Any]) -> Void in
//                let item = PlayableItem(json: album, _itemType: .album)
//                self.albums.append(item)
//            }
//            
//            let addSpotifyTrack = { (track: [String: Any]) -> PlayableItem in
//                let item = PlayableItem(json: track, _itemType: .song)
//                self.songs.append(item)
//                
//                // LOAD ARTISTS
//                let trackJSON = track["track"]! as! NSDictionary
//                let artistsJSON = trackJSON["artists"] as! NSArray
//                for a in artistsJSON {
//                    let artistJSON = a as! NSDictionary
//                    addSpotifyArtist(artistJSON as! [String:Any])
//                }
//                
//                // LOAD ALBUMS
//                let albumJSON = trackJSON["album"] as! NSDictionary
//                addSpotifyAlbum(albumJSON as! [String:Any])
//                
//                return item
//            }
//            
//            let addSpotifyPlaylist = { (pl: [String: Any]) -> PlayableItem in
//                let item = PlayableItem(json: pl, _itemType: .playlist)
//                self.playlists.append(item)
//                
//                Task {
//                    // Wait for playlist to be setup before querying its tracks
//                    await self.waitUntilPropertyNonNull({ item }, keyPath: \.itemPlaylistSP)
//                    
//                    // Check for tracks in playlist
//                    getRequest("https://api.spotify.com/v1/playlists/\(item.itemPlaylistSP!.id)/tracks?limit=100", authToken: self.spotifyAccessToken, onSuccess: { val in
//                        
//                        // Get all tracks from this playlist
//                        let playlistTracks = val["items"] as? NSArray
//                        var newTracks : [PlayableItem] = []
//                        for track in playlistTracks! {
//                            let item = addSpotifyTrack(track as! [String:Any])
//                            newTracks.append(item)
//                        }
//                        
//                        Task {
//                            // Wait for tracks to setup
//                            await self.waitUntilAllPropertiesNonNull({ newTracks }, keyPath: \.itemSongSP?.name)
//                            self.playlistTracksRegister += 1;
//                        }
//                    })
//                }
//                
//                return item
//            }
//            
//            // LOAD LIKED/SAVED SONGS
//            // Create API request
//            getRequest("https://api.spotify.com/v1/me/tracks?limit=50", authToken: self.spotifyAccessToken, onSuccess:
//                { val in
//        
//                    let spotifyTracks = val["items"] as? NSArray
//                    for track in spotifyTracks! {
//                        let _ = addSpotifyTrack(track as! [String:Any])
//                    }
//                    self.likedTracksLoadedFlag = 1
//                }
//            )
//            
//            // LOAD PLAYLISTS
//            // Create API request
//            getRequest("https://api.spotify.com/v1/me/playlists?limit=50&offset=0", authToken: self.spotifyAccessToken, onSuccess:
//                { val in
//                    self.playlistTracksRegister = 0;
//                
//                    // Get playlists
//                    let spotifyPlaylists = val["items"] as? NSArray
//                    for pl in spotifyPlaylists! {
//                        let _ = addSpotifyPlaylist(pl as! [String:Any])
//                    }
//                }
//            )
//            
//            Task {
//                // Wait for playlists to setup
//                await self.waitUntilAllPropertiesNonNull({ self.playlists }, keyPath: \.itemPlaylistSP?.playlistName)
//                // Wait until tracks from playlists are registered
//                await self.waitUntil({ self.playlistTracksRegister == self.playlists.count && self.likedTracksLoadedFlag == 1 })
//                
//                // Refresh
//                self.loadProgress.append("SONGS_LOADED")
//                self.loadProgress.append("PLAYLISTS_LOADED")
//                self.onLibraryUpdate.trigger()
//                
//                // Load Artists
//                var batchIndex = 0
//                var batchIDs : [String] = []
//
//                // Remove any duplicates
//                var seen = Set<PlayableItem>()
//                for item in self.artists { seen.insert(item) }
//                self.artists = Array(seen)
////                print(String(self.artists.count) + " vs " + String(seen.count))
//                
//                seen = Set<PlayableItem>()
//                for item in self.albums { seen.insert(item) }
//                self.albums = Array(seen)
////                print(String(self.albums.count) + " vs " + String(seen.count))
//                
//                for _ in 0..<Int(ceil(Double(self.artists.count) / 50.0)) {
//                    batchIDs = []
//                    for j in 0..<50 {
//                        if batchIndex + j >= self.artists.count {
//                            break
//                        }
//                        batchIDs.append(self.artists[batchIndex + j].getID())
//                    }
//                    
//                    getRequest("https://api.spotify.com/v1/artists?ids=\(batchIDs.joined(separator: ","))", authToken: self.spotifyAccessToken, onSuccess:
//                                { val in
//                        
//                        let artistItems = val["artists"] as! NSArray
//                        for art in artistItems {
//                            let index = self.artists.firstIndex(where: { $0.itemArtistSP?.name == ((art as! NSDictionary)["name"] as! String) })!
//                            
//                            self.artists[index].itemArtistSP!.loadImages(art as! NSDictionary)
//                            
//                            self.artistsRegister += 1
//                        }
//                    })
//                    batchIndex += 50
//                    batchIDs = []
//                }
//                
//                await waitUntil({ artistsRegister == self.artists.count })
//                
//                print("artists loaded")
//                
//                loadProgress.append("ARTISTS_LOADED")
//                self.onLibraryUpdate.trigger()
//            }
//            
//            loadProgress.append("ALBUMS_LOADED")
//            onLibraryUpdate.trigger()
//        }
//        
//        Task {
//            // Wait for SONGS, ALBUMS, PLAYLISTS, and ARTISTS
//            while (!loadProgress.contains("SONGS_LOADED") || !loadProgress.contains("ALBUMS_LOADED") || !loadProgress.contains("PLAYLISTS_LOADED") || !loadProgress.contains("ARTISTS_LOADED")) {
//                try? await Task.sleep(nanoseconds: 100_000_000)
//            }
//            
//            // LOAD PINNED ITEMS
//            let pinned = UserDefaults.standard.string(forKey: "PINNED_ITEMS") ?? ""
//            if (pinned.count > 0) {
//                let items = pinned.components(separatedBy: "%")
//                for i in items {
//                    let vals = i.components(separatedBy: "~")
//                    
//                    if (vals.count == 2) {
//                        let itemType = vals[0]
//                        if (itemType == PlayableItemType.song.description) {
//                            if let song = songs.first(where: { $0.getName() == vals[1] }) {
//                                pinnedItems.append(song)
//                            }
//                            else {
////                                print("Missing Pinned Item: \(vals[1])")
//                            }
//                        }
//                        else if (itemType == PlayableItemType.album.description) {
//                            if let album = albums.first(where: { $0.getAlbumTitle() == vals[1] }) {
//                                pinnedItems.append(album)
//                            }
//                            else {
////                                print("Missing Pinned Item: \(vals[1])")
//                            }
//                        }
//                        else if (itemType == PlayableItemType.artist.description) {
//                            if let artist = artists.first(where: { $0.itemArtistAM?.id.rawValue == vals[1] }) {
//                                pinnedItems.append(artist)
//                            }
//                            else {
////                                print("Missing Pinned Item: \(vals[1])")
//                            }
//                        }
//                    }
//                }
//            }
//            
//            // LOAD QUEUE
//            let queueParse = UserDefaults.standard.string(forKey: "QUEUE_ITEMS") ?? ""
//            
//            if (queueParse.count > 0) {
//                let items = queueParse.components(separatedBy: "%")
//                var newQueueIndex = -1
//                var newQueue : [PlayableItem] = []
//                var missingQueueItems : [String] = []
//                
//                for i in 0..<items.count {
//                    if (i == items.count - 1) {
//                        // Queue Index
//                        newQueueIndex = Int(items[i])!
//                    }
//                    else {
//                        // Queue Item
//                        if let song = songs.first(where: { $0.getName() + $0.getArtistName() == items[i] }) {
//                            newQueue.append(song)
//                        }
//                        else {
//                            missingQueueItems.append(items[i])
//                        }
//                    }
//                }
//                if (newQueueIndex < newQueue.count && newQueueIndex > -1) {
//                    addSongsToQueue(newQueue)
//                    queueIndex = newQueueIndex
//                    currentlyPlaying = queue[queueIndex]
//                }
//            }
//            
//            // EVERYTHING HAS BEEN LOADED
//            self.setCatalogue("Pinned", self.pinnedItems)
//            self.setCatalogue("Shuffle Sample", randNItems(10))
//            self.setCatalogue("Popular Songs", randNItems(20, [.song]))
//            self.setCatalogue("Most Played", firstNSortedItems(10, { $0.getPlayCount() > $1.getPlayCount() }, [.song]))
//            self.setCatalogue("Recently Added", firstNSortedItems(10, { $0.getAddedDate() > $1.getAddedDate() }, [.album]))
//            self.setCatalogue("Popular Artists", randNItems(10, [.artist]))
//            self.setCatalogue("Playlists", firstNSortedItems(-1, { $0.getAddedDate() > $1.getAddedDate()}, [.playlist]))
//            
//            onLibraryUpdate.trigger()
//        }
//        
//        self.generateCatalogues()
//        self.loaded = true
//        
//        print("Initialized Library")
//        self.initialized = true
//        
//        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//            Task {
//                await self.advancePlayStep()
//            }
//        }
        // _______________________________
    }
    
    // --------------- PLAYER
    public func playButton() {
        Task {
            do {
                // No song playing
                if currentlyPlaying == nil {

                }
                // Song playing
                else {
                    let stat = ApplicationMusicPlayer.shared.state.playbackStatus
                    if (stat == .paused) {
                        await playItem(currentlyPlaying!)
                        projectedPlaybackState = .playing
                    }
                    else if (stat == .stopped) { // Most likely just opened app and loaded queue
                        for i in 0..<queue.count {
                            if (i == queueIndex) {
                                await playSong(queueIndex)
                            }
                        }
                    }
                    else {
                        pauseSong()
                        projectedPlaybackState = .paused
                    }
                }
            }
        }
    }
    public func backwardButton() {
        if queueIndex <= 0 {
            return
        }
        
        Task {
            await playSong(queueIndex - 1)
        }
    }
    public func forwardButton() {
        if queueIndex > queue.count {
            return
        }
        
        Task {
            await playSong(queueIndex + 1)
        }
    }
    // --------------- PLAYER
    
    // --------------- QUEUE
    private func updateAppQueue() {
        if (queue.count <= 0) {
//            ApplicationMusicPlayer.shared.queue = ApplicationMusicPlayer.Queue([])
        }
        else {
            // Update Queue ********* AM
            let entries = getEntries(queue)
            if (queueIndex < 0 || queueIndex >= queue.count) {
                ApplicationMusicPlayer.shared.queue = ApplicationMusicPlayer.Queue(entries)
            }
            else {
                ApplicationMusicPlayer.shared.queue = ApplicationMusicPlayer.Queue(entries, startingAt: entries[queueIndex])
            }
            // Update Queue ********* AM
        }
        saveCurrentQueueValues()
    }
    public func addSongToQueue(_ item: PlayableItem, _ index: Int = -1) {
        var actlIndex = index
        if actlIndex == -1 {
            actlIndex = queue.count
        }
        queue.insert(item, at: actlIndex)
        
        updateAppQueue()
    }
    public func addSongsToQueue(_ items: [PlayableItem], _ index: Int = -1) {
        var actlIndex = index
        if actlIndex == -1 {
            actlIndex = queue.count
        }
        queue.insert(contentsOf: items, at: max(0, min(queue.count, actlIndex)))
        
        updateAppQueue()
    }
    public func clearQueue() {
        queue = Array(queue[0..<(queueIndex + 1)])
        updateAppQueue()
    }
    public func removeItemFromQueue(_ index : Int) {
        // Out of Range
        if index >= queue.count || index < 0 {
            return
        }
        
        // History
        if index < queueIndex {
            queue.remove(at: index)
            queueIndex -= 1
        }
        // CurrentlyPlaying
        else if index == queueIndex {
            queue.remove(at: queueIndex)
            Task {
                await playSong(queueIndex)
            }
        }
        // In Queue
        else {
            queue.remove(at: index)
        }
        
        updateAppQueue()
    }
    public func moveItemInQueue(_ from: Int, _ to: Int) {
        if from == to || from == queueIndex {
            return
        }
        
        // History
        if from < queueIndex {
            // from: History to History
            if to <= queueIndex {
                let fromItem = queue.remove(at: from)
                // Moving up (need to deal with insert offset)
                if from < to {
                    queue.insert(fromItem, at: to - 1)
                }
                else {
                    queue.insert(fromItem, at: to)
                }
            }
            // from: History to Queue
            else {
                let fromItem = queue.remove(at: from)
                queue.insert(fromItem, at: to - 1)
                queueIndex -= 1
            }
        }
        // In Queue
        else {
            // from: Queue to History
            if to <= queueIndex {
                let fromItem = queue.remove(at: from)
                queue.insert(fromItem, at: to)
                queueIndex += 1
            }
            // from: Queue to Queue
            else {
                let fromItem = queue.remove(at: from)
                // Moving up (need to deal with insert offset)
                if from < to {
                    queue.insert(fromItem, at: to - 1)
                }
                else {
                    queue.insert(fromItem, at: to)
                }
            }
        }
        
//        if from == queueIndex {
//            queueIndex = to
//        }
        
        updateAppQueue()
    }
    // --------------- QUEUE
    
    // --------------- PLAYING
    public func playItem(_ item: PlayableItem) async {
        await item.play(self)
    }
    public func playSong(_ song: Song) async {
        do {
            // This song is currently playing or is paused - RESUME
            if currentlyPlaying?.itemSongAM == song {
                // Play Song ********* AM
                let player = ApplicationMusicPlayer.shared
                try await player.play()
                
                currentPlayback = ApplicationMusicPlayer.shared.playbackTime
                // Play Song ********* AM
            }
            // New song
            else {
                // Other song was playing - do something with it
                if currentlyPlaying != nil {
                    
                }
                
                let addIndex = queueIndex >= queue.count ? queue.count : queueIndex + 1
                addSongToQueue(self.songs.filter({ $0.itemSongAM!.title == song.title }).first!, addIndex)
                await playSong(addIndex)
            }
        }
        catch {
            print("ERROR PLAYING SONG")
        }
    }
    public func playSong(_ index: Int) async {
        do {
            queueIndex = index
            
            // No Song
            if queueIndex >= queue.count {
                // Play Song ********* AM
                let player = ApplicationMusicPlayer.shared
                player.stop()
                // Play Song ********* AM
                return
            }
            
            // Play Song ********* AM
            let player = ApplicationMusicPlayer.shared
            let entries = getEntries(queue)
            player.queue = ApplicationMusicPlayer.Queue(entries, startingAt: entries[queueIndex])
            
            try await player.prepareToPlay()
            try await player.play()
            
            currentPlayback = ApplicationMusicPlayer.shared.playbackTime
            projectedPlaybackState = .playing
            
            currentlyPlaying = queue[queueIndex]
            onForcePlaybackUpdte.trigger((0.0, -1.0))
            // Play Song ********* AM
        }
        catch {
            print("ERROR PLAYING SONG")
        }
        
        updateAppQueue()
    }
    public func advancePlayStep() {
        let player = ApplicationMusicPlayer.shared;
        
        if (player.state.playbackStatus == .playing) {
            self.currentPlayback = ApplicationMusicPlayer.shared.playbackTime
            
            // Something is playing
            if (ApplicationMusicPlayer.shared.queue.currentEntry != nil) {
                if case let .song(currentSong) = ApplicationMusicPlayer.shared.queue.currentEntry!.item {
                    // No play is registered.. Update current song
                    if (currentlyPlaying == nil) {
                        for i in 0..<queue.count {
                            if (isEqual(queue[i].itemSongAM!, currentSong)) {
                                queueIndex = i
                                self.currentlyPlaying = queue[i]
                                onPlayingSongChanged.trigger((currentlyPlaying))
                                onForcePlaybackUpdte.trigger((0.0, -1.0))
                                break
                            }
                        }
                    }
                    else {
                        // If current != registered.. Update current song
                        if (!isEqual(currentlyPlaying!.itemSongAM!, currentSong)) {
                            // New song is playing
                            for i in 0..<queue.count {
                                if (isEqual(queue[i].itemSongAM!, currentSong)) {
                                    queueIndex = i
                                    self.currentlyPlaying = queue[i]
                                    onPlayingSongChanged.trigger((currentlyPlaying))
                                    onForcePlaybackUpdte.trigger((0.0, -1))
                                    break
                                }
                            }
                        }
                        onForcePlaybackUpdte.trigger((self.currentPlayback, self.currentlyPlaying!.getDuration()))
                    }
                }
            }
            // Nothing is playing
            else {
                if (currentlyPlaying != nil) {
                    currentlyPlaying = nil
                    onPlayingSongChanged.trigger((currentlyPlaying))
                }
                
                onForcePlaybackUpdte.trigger((0.0, -1.0))
            }
        }
        else if (player.state.playbackStatus == .paused) {
            self.currentPlayback = ApplicationMusicPlayer.shared.playbackTime
            if (currentlyPlaying == nil) {
                onForcePlaybackUpdte.trigger((0.0, -1.0))
            }
            else {
                onForcePlaybackUpdte.trigger((self.currentPlayback, self.currentlyPlaying!.getDuration()))
            }
        }
        else if (player.state.playbackStatus == .stopped) {
            self.currentPlayback = 0
            onForcePlaybackUpdte.trigger((0.0, -1.0))
            // If playing.. Stop
        }
        else {
            // Idek
        }
    }
    public func pauseSong() {
        if currentlyPlaying == nil {
            print("WARNING: trying to pause when no song is playing")
            return
        }
        
        // Play Song ********* AM
        ApplicationMusicPlayer.shared.pause()
        currentPlayback = ApplicationMusicPlayer.shared.playbackTime
        // Play Song ********* AM
    }
    public func forwardSong() async {

    }
    
    public func setRepeatMode(_ on : Bool) {
        ApplicationMusicPlayer.shared.state.repeatMode = on ? .one : MusicPlayer.RepeatMode.none
    }
    
    public func setLivePlayback0to1(_ val: CGFloat) {
        if currentlyPlaying == nil {
            print("WARNING: trying to set playback with no music playing")
            return
        }
        currentPlayback = val * currentlyPlaying!.itemSongAM!.duration!
        onForcePlaybackUpdte.trigger((self.currentPlayback, self.currentlyPlaying!.getDuration()))
        
        // Play Song ********* AM
        ApplicationMusicPlayer.shared.playbackTime = currentPlayback
        // Play Song ********* AM
    }
    // --------------- PLAYING
    
    public func setPreviewingItem(_ item: PlayableItem, _ content: ContentView) {
        if item.itemType == .song {
            Task {
                await item.play(self)
            }
        }
        else if item.itemType == .album {
            content.AddPage(PreviewAlbumInstance(self, content.appData, content, album: item))
        }
        else if item.itemType == .playlist {
            content.AddPage(PreviewPlaylistInstance(self, content.appData, content, playlist: item))
        }
        else if item.itemType == .artist {
            content.AddPage(PreviewArtistInstance(self, content.appData, content, artist: item))
        }
    }

    public func generateCatalogues() {
        addCatalogue("Pinned",[])
        addCatalogue("Recently Added", [])
        addCatalogue("Playlists", [])
        addCatalogue("Popular Songs", [])
        addCatalogue("Most Played", [])
        addCatalogue("Shuffle Sample", [])
        addCatalogue("Popular Artists", [])
    }
    public func addCatalogue(_ title : String, _ initialItems : [PlayableItem]) {
        self.catalogues.append(LineCatalogue(title: title, items: initialItems))
    }
    public func setCatalogue(_ title : String, _ newItems : [PlayableItem]) {
        for i in catalogues.indices {
            if (catalogues[i].title == title) {
                catalogues.remove(at: i)
                catalogues.insert(LineCatalogue(title: title, items: newItems), at: i)
            }
        }
    }
    public func addToCatalogue(_ title : String, _ newItem : PlayableItem) {
        for i in catalogues.indices {
            if (catalogues[i].title == title) {
                catalogues.insert(LineCatalogue(title: title, items: catalogues[i].items + [newItem]), at: i)
                catalogues.remove(at: i + 1)
            }
        }
    }
    
    func firstNSortedItems(_ n: Int, _ order: (PlayableItem, PlayableItem) -> Bool, _ allowedTypes: [PlayableItemType] = [.song, .album, .artist, .playlist]) -> [PlayableItem] {
        // Filter items based on allowed types
        let allArrays : [[PlayableItem]] = [allowedTypes.contains(.song) ? self.songs : [], allowedTypes.contains(.album) ? self.albums : [], allowedTypes.contains(.artist) ? self.artists : [], allowedTypes.contains(.playlist) ? self.playlists : []]
        if (allArrays.count == 0) { return [] }
        let allItems = allArrays.compactMap { $0 }.reduce([], +).sorted(by: order)

        return allItems.prefix(n == -1 ? allItems.count : n).map { $0 }
    }
    func randNItems(_ n: Int, _ allowedTypes: [PlayableItemType] = [.song, .album, .artist, .playlist]) -> [PlayableItem] {
        // Filter items based on allowed types
        let allArrays : [[PlayableItem]] = [allowedTypes.contains(.song) ? self.songs : [], allowedTypes.contains(.album) ? self.albums : [], allowedTypes.contains(.artist) ? Array(self.artists.shuffled().prefix(self.artists.count / 2)) : [], allowedTypes.contains(.playlist) ? self.playlists : []]
        if (allArrays.count == 0) { return [] }
        let allItems = allArrays.compactMap { $0 }.reduce([], +).shuffled()

        return allItems.prefix(n).map { $0 }
    }
    func trendingItems(_ n : Int) async -> [PlayableItem] {
//        var request = MusicCatalogChartsRequest(types: [Song.self])
//        request.limit = n
//        
//        var trendingItems: [PlayableItem] = []
        let trendingItems = randNItems(n, [.song])

//        do {
//            let response = try await request.response()
//            
//            if let songCharts = response.songCharts.first {
//                let trendingSongs = songCharts.items
//                
//                for song in trendingSongs {
//                    trendingItems.append(PlayableItem(_item: song, _itemType: .song))
//                    print(song)
//                }
//            }
//        }
//        catch {
//            print("ERROR: Couldn't recieve trending items: \(error)")
//        }
        return trendingItems
    }
    
    func savePinnedValues() {
        var pinned = ""
        for i in pinnedItems {
            pinned += i.itemType.description + "~"
            if (i.itemType == .artist) {
                pinned += i.itemArtistAM!.id.rawValue
            }
            else {
                pinned += i.getName()
            }
            pinned += "%"
        }
        UserDefaults.standard.setValue(pinned, forKey: "PINNED_ITEMS")
    }
    func saveCurrentQueueValues() {
        var queueParse = ""
        for i in queue {
            queueParse += i.getName() + i.getArtistName() + "%"
        }
        queueParse += String(queueIndex)
        UserDefaults.standard.setValue(queueParse, forKey: "QUEUE_ITEMS")
    }

    
    // Get an entry item from song ****** AM
   private func getEntries(_ items: [PlayableItem]) -> [MusicPlayer.Queue.Entry] {
        var entries: [MusicPlayer.Queue.Entry] = []
        for s in items {
            entries.append(MusicPlayer.Queue.Entry(s.itemSongAM!))
        }
        return entries
    }
    // Get an song from queue entry ****** AM
    public func getSong(entry: MusicPlayer.Queue.Entry) -> Song? {
        if case .song(let s) = entry.item {
            return s
        }
        else {
            return nil
        }
    }
    // Get array of songs from track collection
    public func getSongs(_ tracks: MusicItemCollection<Track>) -> [PlayableItem] {
        var _songs: [PlayableItem] = []
        for t in tracks {
            if case .song(let s) = t {
                _songs.append(self.songs.filter({ $0.itemSongAM!.title == s.title }).first!)
            }
        }
        return _songs
    }
    // * APPLE MUSIC *  Get array of songs from album collection
    public func getSongs(_ album: Album) async -> [PlayableItem] {
        do {
            let tracks = try await album.with([.tracks]).tracks!
            var _songs: [PlayableItem] = []
            for t in tracks {
                if case .song(let s) = t {
                    _songs.append(self.songs.filter({ $0.itemSongAM!.id == s.id }).first!)
                }
            }
            return _songs
        }
        catch {
            print("ERROR:", error)
            return []
        }
    }
    // * SPOTIFY * Get array of songs from album collection
    public func getSongs(_ album: SpotifyAlbum, completion: @escaping ([PlayableItem]) -> Void) {
        getRequest("https://api.spotify.com/v1/albums/\(album.albumID)/tracks?limit=50", authToken: self.spotifyAccessToken, onSuccess: { val in
            
            // Get all tracks from this playlist
            let albumTracks = val["items"] as! NSArray
            var _songs: [PlayableItem] = []
            for track in albumTracks {
                let trackID = (track as! NSDictionary)["id"] as! String
                if let matchingSong = self.songs.first(where: { $0.itemSongSP!.id == trackID }) {
                    _songs.append(matchingSong)
                }
                else {
                    // Not added to library yet
                }
            }
            completion(_songs)
        })
    }
    // * APPLE MUSIC *  Get array of songs from playlist collection
    public func getPlaylistSongs(_ playlist : PlayableItem) async -> [PlayableItem] {
        do {
            if playlist.itemPlaylistAM!.tracks == nil {
                let detailedPlaylist = try await playlist.itemPlaylistAM!.with([.tracks])
                playlist.itemPlaylistAM = detailedPlaylist
            }
            return getSongs(playlist.itemPlaylistAM!.tracks!)
        }
        catch {
            print("ERROR:", error)
            return []
        }
    }
    // * SPOTIFY *  Get array of songs from playlist collection
    public func getPlaylistSongs(_ playlist : SpotifyPlaylist, completion: @escaping ([PlayableItem]) -> Void) {
        getRequest("https://api.spotify.com/v1/playlists/\(playlist.id)/tracks?limit=100", authToken: self.spotifyAccessToken, onSuccess: { val in
            
            // Get all tracks from this playlist
            let playlistTracks = val["items"] as! NSArray
            var _songs: [PlayableItem] = []
            for track in playlistTracks {
                let trackJSON = (track as! NSDictionary)["track"]
                let trackID = (trackJSON as! NSDictionary)["id"] as! String
                if let matchingSong = self.songs.first(where: { $0.itemSongSP!.id == trackID }) {
                    _songs.append(matchingSong)
                }
                else {
                    // Problem
                }
            }
            completion(_songs)
        })
    }
    
    // Playback visual GETTERS
    public func getPlaybackProgress() -> CGFloat {
        if currentlyPlaying == nil || currentPlayback == 0 {
            return 0.0
        }
        return min(1, currentPlayback / currentlyPlaying!.getDuration())
    }
    public func getPlaybackString() -> String {
        return getTimeString(currentPlayback)
    }
    public func getTimeString(_ t: CGFloat) -> String {
        let minutes = Int(floor(t / 60.0))
        let seconds = Int(floor(t.truncatingRemainder(dividingBy: 60.0)))
        if seconds > 9 {
            return "\(minutes):\(seconds)"
        }
        else {
            return "\(minutes):0\(seconds)"
        }
    }
    
    public func isEqual(_ a : Song, _ b : Song) -> Bool {
        return a.title == b.title && a.artistName == b.artistName
    }
    
    // View Defaults
    public func EmptyArt(_ appData: AppData, _ wid: CGFloat, _ hei : CGFloat, artRadius : CGFloat = -1) -> some View {
        ZStack {
            MaterialBackground().colorMultiply(appData.colorScheme.mainColor)
                .frame(width: wid, height: hei)
                .cornerRadius((artRadius == -1 ? appData.appFormat.musicArtCorner : artRadius) * 2)
                .padding([.bottom], 5)
            
            Image(systemName: "music.note").resizable().aspectRatio(contentMode: .fit).opacity(0.2)
                .frame(width: wid / 3, height: wid / 3)
        }
    }
    
    // ASYNC WAIT HELPERS
    func waitUntilPropertyNonNull<T, V>(_ objectProvider: @escaping () -> T, keyPath: KeyPath<T, V?>) async {
        while objectProvider()[keyPath: keyPath] == nil {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    func waitUntilAllPropertiesNonNull<T, V>(_ arrayProvider: @escaping () -> [T], keyPath: KeyPath<T, V?>) async {
        while arrayProvider().contains(where: { $0[keyPath: keyPath] == nil }) {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    func waitUntil(_ predicate: () -> Bool) async {
        while !predicate() {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    // ASYNC WAIT HELPERS
}
