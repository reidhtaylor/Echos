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

@MainActor
final class MusicLibrary : ObservableObject {
    @Published var loaded = false
    @Published var loadDescription = "Hey"
    
    var songs: MusicItemCollection<Song> = []
    var albums: MusicItemCollection<Album> = []
    var playlists: [Playlist] = []
    
    @Published var currentlyPlaying: Song?
    @Published var workingQueue: [MusicPlayer.Queue.Entry] = []
    @Published var songState: MusicPlayer.PlaybackStatus = .stopped
    
    @Published var currentPlayback = 0.0
    var playbackTimer: Timer?
    
    @Published var mostPlayed: Song?
    @Published var recentlyPlayed: [Album] = []
    @Published var randomSongs: [Song] = []
    
    @Published var previewingAlbum: Album? = nil
    @Published var previewingPlaylist: Playlist? = nil
    @Published var previewingSongs: [Song] = []
    
    public init() {
        // _______________________________
        Task {
            self.loadDescription = "Authorizing"
            let status = await MusicAuthorization.request()
            if status != .authorized { return }
            
            do {
                // Query Songs
                self.loadDescription = "Querying Media"
                let rqSongs = MusicLibraryRequest<Song>()
                let resSongs = try await rqSongs.response()
                self.songs = resSongs.items
                
                let rqAlbums = MusicLibraryRequest<Album>()
                let resAlbums = try await rqAlbums.response()
                self.albums = resAlbums.items
                
                // Query Playlists
                self.loadDescription = "Querying Collections"
                let rqPlaylists = MusicLibraryRequest<Playlist>()
                let resPlaylists = (try await rqPlaylists.response()).items
                for pl in resPlaylists {
                    self.playlists.append(pl)
                }
                
                // Generate Random Queue
                var queueItems: [Song] = []
                for _ in 0..<6 { queueItems.append(songs.randomElement()!) }
                
                // Generate Random Browsing Data
                self.refreshRecentlyPlayed()
                self.refreshRandomSongs()
                self.mostPlayed = songs[0]
                
                self.loadDescription = "Preparing Queue"
                let v = Task {
                    await playSong(songs.randomElement()!, getEntries(queueItems), begin: false)
                    self.loaded = true
                }
                
                try await Task.sleep(nanoseconds: 4_000_000_000)
                if self.loaded == false {
                    print("Didn't Load Correctly -- ••")
                    v.cancel()
                }
            }
            catch {
                print("INIT ERROR:", error)
            }
            
            // MusicSubscription.current -> MusicSubscription()
            // --- Provies data about subscriber
        }
        // _______________________________
    }
    
    // --------------- PLAYER
    public func playButton() {
        Task {
            do {
                // No song playing
                if currentlyPlaying == nil {
                    if workingQueue.count > 0 {
                        var newQueue = workingQueue
                        let song = getSong(entry: newQueue[0])
                        newQueue.remove(at: 0)
                        await playSong(song!, newQueue)
                    }
                }
                else {
                    if songState == .playing {
                        pauseSong()
                    }
                    else {
                        await playSong(currentlyPlaying!, nil)
                    }
                }
            }
        }
    }
    public func backwardButton() {

    }
    public func forwardButton() {
        Task {
            await forwardSong()
        }
    }
    // --------------- PLAYER
    
    // --------------- QUEUE
    private func updateAppQueue() {
        ApplicationMusicPlayer.shared.queue = ApplicationMusicPlayer.Queue(workingQueue, startingAt: workingQueue[0])
    }
    private func refreshWorkingQueue() {
        workingQueue = []
        for e in ApplicationMusicPlayer.shared.queue.entries {
            workingQueue.append(e)
        }
    }
    private func setQueue(_ entries: [MusicPlayer.Queue.Entry]) {
        workingQueue = entries
        updateAppQueue()
    }
    private func setQueue(_ songs: [Song]) {
        setQueue(getEntries(songs))
    }
    // --------------- QUEUE
    
    // --------------- PLAYING
    public func playSong(_ song: Song, _ queue: [MusicPlayer.Queue.Entry]?, begin: Bool = true) async {
        do {
            if currentlyPlaying != song {
                print("Trying to play:", song.title)
                print(song)
                if queue != nil {
                    var newQueue = queue!.map { $0 }
                    let songEntry = MusicPlayer.Queue.Entry(song)
                    if newQueue.count <= 0 {
                        newQueue.append(songEntry)
                    }
                    else {
                        newQueue.insert(songEntry, at: 0)
                    }
                    setQueue(newQueue)
                    
                    print("playSong:")
                    for q in newQueue {
                        print("\t", q.title)
                    }
                }
                
                songState = .stopped
                
                print("Start prep")
                try await ApplicationMusicPlayer.shared.prepareToPlay()
                print("End prep")
                
                try await Task.sleep(nanoseconds: 1_000)
                while ApplicationMusicPlayer.shared.queue.currentEntry == nil || ApplicationMusicPlayer.shared.queue.currentEntry!.item == nil {
                    await playSong(song, queue, begin: begin)
                    return
                }
                print("Prepped -", ApplicationMusicPlayer.shared.queue.currentEntry ?? "NIL")
                currentlyPlaying = getSong(entry: ApplicationMusicPlayer.shared.queue.currentEntry!)
            }
            
            if begin {
                try await ApplicationMusicPlayer.shared.play()
                songState = .playing
            }
            
            print("Currently:", currentlyPlaying!.title)
            currentPlayback = ApplicationMusicPlayer.shared.playbackTime
            
            if playbackTimer != nil { playbackTimer!.invalidate() }
            
            if begin {
                playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    self.currentPlayback += timer.timeInterval
                    
                    if self.currentlyPlaying != nil {
                        if self.currentPlayback > self.currentlyPlaying!.duration! {
                            self.currentPlayback = self.currentlyPlaying!.duration!
                        }
                    }
                    
                    if ApplicationMusicPlayer.shared.state.playbackStatus == .paused && self.currentPlayback >= self.currentlyPlaying!.duration! {
                        self.playbackTimer!.invalidate()
                        Task {
                            await self.forwardSong()
                        }
                    }
                }
            }
        }
        catch {
            print("ERROR: playing song -", error)
        }
    }
    public func pauseSong() {
        if ApplicationMusicPlayer.shared.isPreparedToPlay == false {
            print("WARNING: trying to pause when song is not prepared")
            return
        }
        else if currentlyPlaying == nil {
            print("WARNING: trying to pause when no song is playing")
            return
        }
        
        ApplicationMusicPlayer.shared.pause()
        songState = .paused

        currentPlayback = ApplicationMusicPlayer.shared.playbackTime
        let timer = playbackTimer
        timer!.invalidate()
        playbackTimer = nil
    }
    public func forwardSong() async {
        if ApplicationMusicPlayer.shared.queue.entries.count <= 1 {
            print("WARNING: trying to play next song with no songs in queue")
            emptyQueue()
            return
        }
        
        var newQueue = workingQueue.map { $0 }
        newQueue.remove(at:0)
        let song = newQueue.remove(at:0)
    
        await playSong(getSong(entry: song)!, newQueue)
    }
    
    public func setLivePlayback0to1(_ val: CGFloat) {
        if currentlyPlaying == nil {
            print("WARNING: trying to set playback with no music playing")
            return
        }
        print("Val:", val, "- Dur:", currentlyPlaying!.duration!)
        currentPlayback = val * currentlyPlaying!.duration!
        ApplicationMusicPlayer.shared.playbackTime = currentPlayback
    }
    
    public func changeRepState() {
        
    }
    
    public func emptyQueue() {
        ApplicationMusicPlayer.shared.queue = ApplicationMusicPlayer.Queue([])
        workingQueue = []
        currentlyPlaying = nil
        currentPlayback = 0
        if playbackTimer != nil {
            let timer = playbackTimer
            timer!.invalidate()
            playbackTimer = nil
        }
        songState = .stopped
    }
    // --------------- PLAYING
    
    public func setPreviewingAlbum(_ album: Album, _ content: ContentView) {
        content.page = .songGroupPreview
        self.previewingAlbum = album
        self.previewingSongs = []
        Task {
            self.previewingSongs = (await getSongs(album)).sorted(by: { $0.trackNumber ?? 0 < $1.trackNumber ?? 0 })
        }
    }
    public func setPreviewingPlaylist(_ pl: Playlist, _ content: ContentView) {
        content.page = .songGroupPreview
        self.previewingPlaylist = pl
        if pl.tracks == nil {
            self.previewingSongs = []
            Task {
                let detailedPlaylist = try await pl.with([.tracks])
                self.previewingSongs = getSongs(detailedPlaylist.tracks!).sorted(by: { $0.artistName.lowercased() < $1.artistName.lowercased() })
                
                let index = self.playlists.firstIndex(of: pl)!
                self.playlists.remove(at: index)
                self.playlists.insert(detailedPlaylist, at: index)
            }
        }
        else {
            self.previewingSongs = getSongs(pl.tracks!).sorted(by: { $0.artistName.lowercased() < $1.artistName.lowercased() })
        }
    }
    
    public func refreshRecentlyPlayed() {
        self.recentlyPlayed = []
        self.recentlyPlayed = Array<Album>(self.albums[..<10])
    }
    public func refreshRandomSongs() {
        self.randomSongs = []
        while self.randomSongs.count < 10 {
            let item = songs[Int.random(in: 0..<songs.count)]
            self.randomSongs.append(item)
        }
    }
    
    private func getEntries(_ songs: [Song]) -> [MusicPlayer.Queue.Entry] {
        var entries: [MusicPlayer.Queue.Entry] = []
        for s in songs {
            entries.append(MusicPlayer.Queue.Entry(s))
        }
        return entries
    }
    
    public func getSong(entry: MusicPlayer.Queue.Entry) -> Song? {
        if case .song(let s) = entry.item {
            return s
        }
        else {
            return nil
        }
    }
    
    public func getSongs(_ tracks: MusicItemCollection<Track>) -> [Song] {
        var songs: [Song] = []
        for t in tracks {
            if case .song(let s) = t {
                songs.append(s)
            }
        }
        return songs
    }
    public func getSongs(_ album: Album) async -> [Song] {
        do {
            let tracks = try await album.with([.tracks]).tracks!
            var songs: [Song] = []
            for t in tracks {
                if case .song(let s) = t {
                    songs.append(s)
                }
            }
            return songs
        }
        catch {
            print("ERROR:", error)
            return []
        }
    }
    
    public func getPlaybackProgress() -> CGFloat {
        if currentlyPlaying == nil {
            return 0.0
        }
        return min(1, currentPlayback / currentlyPlaying!.duration!)
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
}
