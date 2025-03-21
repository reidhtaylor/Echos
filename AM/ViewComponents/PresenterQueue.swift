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

struct PresenterQueue: View {
    @ObservedObject var library: MusicLibrary
    @ObservedObject var appData: AppData
    
    var content: ContentView
    
    @StateObject var musicProgressTracker: MusicProgressTracker
    @State var controlsOn : CGFloat = -1
    @State var turnOffFromDate : Date = .init()
    
    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .center) {
                if (library.queueIndex >= 0 && library.queueIndex < library.queue.count && library.queue[library.queueIndex].getArtwork() != nil) {
                    ArtworkImage(library.queue[library.queueIndex].getArtwork()!, width: geom.size.width, height: geom.size.height).blur(radius: 125)
                }
                else {
                    MaterialBackground().colorMultiply(appData.colorScheme.mainColor).ignoresSafeArea().frame(width: geom.size.width, height: geom.size.height)
                }
                
                VStack(spacing: 30) {
                    if (library.queueIndex >= 0 && library.queueIndex < library.queue.count && library.queue[library.queueIndex].getArtwork() != nil) {
                        ArtworkImage(library.queue[library.queueIndex].getArtwork()!, width: 500, height: 500).cornerRadius(10)
                            .shadow(color:.black.opacity(0.3), radius:10, x:4, y:4)
                    }
                    else {
                        MaterialBackground().colorMultiply(appData.colorScheme.mainColor).ignoresSafeArea()
                            .frame(width: 500, height: 500)
                            .shadow(color:.black.opacity(0.3), radius:10, x:4, y:4)
                    }
                    
                    
                    VStack(spacing: 0) {
                        HStack(spacing:0) {
                            Color.white
                                .frame(width: 500.0 * musicProgressTracker.progress)
                            Color.white
                                .opacity(0.5)
                        }
                        .frame(width: 500.0, height: 5)
                        .contentShape(Rectangle().inset(by: -5))
                        .animation(.linear(duration: musicProgressTracker.progressDuration), value: musicProgressTracker.progress)
                        .onTapGesture { location in
                            library.setLivePlayback0to1(location.x / 500)
                        }
                        .cornerRadius(100)
                        
                        ZStack {
                            HStack(alignment: .center, spacing: 0) {
                                Button(action: {
                                    library.setRepeatMode(ApplicationMusicPlayer.shared.state.repeatMode != .one)
                                }) {
                                    ZStack {
                                        Color.clear
                                            .contentShape(Rectangle())
                                        Image(systemName: "repeat").resizable().aspectRatio(contentMode: .fit).scaleEffect(0.4).colorMultiply(ApplicationMusicPlayer.shared.state.repeatMode == .one ? appData.colorScheme.accent : .white)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(width: 50)
                                
                                Spacer()
                                
                                Button(action: {
                                    library.backwardButton()
                                }) {
                                    ZStack {
                                        Color.clear
                                            .contentShape(Rectangle())
                                        Image(systemName: "backward.fill").resizable().aspectRatio(contentMode: .fit).scaleEffect(0.5)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(library.queue.count <= 0 || library.queueIndex <= 0)
                                .frame(width: 60)
                                
                                Button(action: {
                                    library.playButton()
                                }) {
                                    ZStack {
                                        Color.clear
                                            .contentShape(Rectangle())
                                        Image(systemName: library.projectedPlaybackState == .playing ? "pause.fill" : "play.fill").resizable().aspectRatio(contentMode: .fit).scaleEffect(0.4)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(width: 75)
                                
                                Button(action: {
                                    library.forwardButton()
                                }) {
                                    ZStack {
                                        Color.clear
                                            .contentShape(Rectangle())
                                        Image(systemName: "forward.fill").resizable().aspectRatio(contentMode: .fit).scaleEffect(0.5)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(library.queue.count <= 0 || library.queueIndex >= library.queue.count)
                                .frame(width: 60)
                                
                                Spacer()
                                
                                Button(action: {
                                    self.appData.queueState = .side
                                }) {
                                    ZStack {
                                        Color.clear
                                            .contentShape(Rectangle())
                                        Image(systemName: "arrow.up.left.and.arrow.down.right").resizable().aspectRatio(contentMode: .fit).scaleEffect(0.4).colorMultiply(appData.colorScheme.accent)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(width: 50)
                            }
                            .opacity(controlsOn)
                            .disabled(controlsOn <= 0)
                            .frame(width: 500, height: 70)
                            
                            VStack(alignment: .center, spacing: 0) {
                                if (library.queueIndex >= 0 && library.queueIndex < library.queue.count) {
                                    Text(library.queue[library.queueIndex].getName()).font(.largeTitle.bold()).lineLimit(1)
                                        .shadow(color:.black.opacity(0.3), radius:10, x:4, y:4)
                                    Text(library.queue[library.queueIndex].getArtistName() + " - " + library.queue[library.queueIndex].getAlbumTitle()).font(.title.bold()).lineLimit(1).opacity(0.5)
                                        .shadow(color:.black.opacity(0.3), radius:10, x:4, y:4)
                                }
                                else {
                                    Text("...").font(.largeTitle.bold()).lineLimit(1)
                                }
                            }
                            .opacity(1 - controlsOn)
                            .frame(width: 500, height: 70)
                        }
                        .frame(width: 500, height: 70)
                        .animation(.linear(duration: 0.2), value: controlsOn)
                        .padding(.top, 15)
                    }
                    .frame(width: 500, height: 90)
                    .clipped()
                    .onHover() { over in
                        if over {
                            controlsOn = 1
                            
                            turnOffFromDate = Date.now
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                if (Date.now > turnOffFromDate + 3) {
                                    controlsOn = 0
                                }
                            }
                        }
                        else {
                            controlsOn = 0
                        }
                    }
                    .onAppear() {
                        controlsOn = 0
                        
                        library.onPlayingSongChanged.subscribe("PRESENTER") { _ in
                            controlsOn = controlsOn == 0 ? 0.01 : 0
                        }
                    }
                }
                .offset(x: 0, y: 90 / 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear() {
            if library.currentlyPlaying != nil {
                musicProgressTracker.setPlaybackView(library.currentlyPlaying!.getDuration(), 0, library.currentlyPlaying!.getDuration())
                
                musicProgressTracker.assign("QUEUE")
            }
        }
    }
}

#Preview {
    VStack {
        
    }
}
