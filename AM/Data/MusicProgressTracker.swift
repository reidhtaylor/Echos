//
//  SwiftUIView.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit
import Combine

class MusicProgressTracker : ObservableObject {
    @ObservedObject var library : MusicLibrary
    
    @Published var progress : CGFloat = 0.0
    @Published var progressDuration : CGFloat = 0.01
    @Published var timerCounter : Int = 0
    private var timer: AnyCancellable?
    
    public init(library: MusicLibrary) {
        self.library = library
    }
    
    public func assign(_ id: String) {
        self.library.onForcePlaybackUpdte.subscribe(id) { (currentTime, maxTime) in
            // EVERY SECOND
            let state = ApplicationMusicPlayer.shared.state.playbackStatus
            
            // IF NULL SONG or NOT PLAYING OR PAUSED
            if (self.library.currentlyPlaying == nil || (state != .playing && state != .paused)) {
                self.setPlaybackView(1, 0, -1.0)
            }
            else {
                // IF PAUSED
                if (state == .paused) {
                    self.setPlaybackView(self.library.currentlyPlaying!.getDuration(), self.library.currentPlayback, -1.0)
                }
                // IF PLAYING AND UPDATING TIME
                else if (abs(currentTime - Double(self.timerCounter)) > 2) {
                    self.setPlaybackView(maxTime, currentTime, maxTime)
                }
            }
        }
        self.library.onPlayingSongChanged.subscribe(id) { _ in
            // ON SONG CHANGED
            if (self.library.currentlyPlaying != nil) {
             // Song just started -> animate
                self.setPlaybackView(self.library.currentlyPlaying!.getDuration(), 0, self.library.currentlyPlaying!.getDuration())
            }
            // IF NOTHING PLAYING NOW
            else {
                self.setPlaybackView(1, 0, -1.0)
            }
        }
    }
    
    public func setPlaybackView(_ max : Double, _ setTo : Double, _ animateTo : Double = -1.0) {
        self.timerCounter = Int(setTo)
   
        self.progressDuration = 0.001
        self.progress = setTo / max
        
        timer?.cancel()
        timer = nil
        timer = Timer.publish(every: 1, on: .main, in: .common) // Add offset if song is in the middle of a second like 12.43s
            .autoconnect()
            .sink { _ in
                self.timerCounter += 1
                if self.timerCounter >= Int(self.library.currentlyPlaying?.getDuration() ?? 0) {
                    self.timer?.cancel()
                    self.timer = nil
                }
            }
        
        if (animateTo != -1.0) {
            // Start animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.progressDuration = animateTo - setTo
                self.progress = animateTo / max
            }
        }
        else {
            timer?.cancel()
            timer = nil
        }
    }
}

#Preview {
    VStack {
        
    }
}
