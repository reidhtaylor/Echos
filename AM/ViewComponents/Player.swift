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

struct Player: View {
    @ObservedObject var library: MusicLibrary
    @State var appData: AppData
    
    var content: ContentView
    var windowSize: CGSize
    
    @StateObject var musicProgressTracker: MusicProgressTracker
    
    var body: some View {
        ZStack {
            MaterialBackground().colorMultiply(appData.colorScheme.deepColor).ignoresSafeArea()
            
            VStack(spacing:0) {
                HStack(spacing:0) {
                    appData.colorScheme.mainColor.colorInvert()
                        .frame(width: windowSize.width * musicProgressTracker.progress)
                    appData.colorScheme.mainColor.colorInvert().opacity(0.2)
                }
                .frame(width: windowSize.width, height: 2)
                .contentShape(Rectangle().inset(by: -8))
                .animation(.linear(duration: musicProgressTracker.progressDuration), value: musicProgressTracker.progress)
                .onTapGesture { location in
                    library.setLivePlayback0to1(location.x / (windowSize.width))
                }
                
                // Playing, Interactives, Next
                HStack(alignment: .center, spacing: 0) {
                    // Currently Playing
                    if library.currentlyPlaying != nil {
                        content.listItem(height: appData.appFormat.playerHeight, artwork: library.currentlyPlaying!.getArtwork(), mainTitle: library.currentlyPlaying!.getName(), subTitle: library.currentlyPlaying!.getArtistName(), artRadius: 0)
                            .frame(maxWidth: windowSize.width / 3.0, alignment: .leading)
                    }
                    else {
                        content.listItem(height: appData.appFormat.playerHeight, artwork: nil, mainTitle: "Unknown Song", subTitle: "...", artRadius: 0)
                            .frame(maxWidth: windowSize.width / 3.0, alignment: .leading)
                    }
                        
                    // Interactives
                    let buttonSize = 60.0
                    let iconSize = 25.0
                    HStack(alignment: .center, spacing: 0) {
                        Button(action: {
                            library.setRepeatMode(ApplicationMusicPlayer.shared.state.repeatMode != .one)
                        }) {
                            ZStack {
                                Color.clear
                                    .contentShape(Rectangle())
                                Image(systemName: "repeat").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize * 0.6, height: iconSize * 0.6).colorMultiply(ApplicationMusicPlayer.shared.state.repeatMode == .one ? appData.colorScheme.accent : .white)
                            }
                        }
                        .frame(width: buttonSize / 1.5, height: buttonSize)
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            library.backwardButton()
                        }) {
                            ZStack {
                                Color.clear
                                    .contentShape(Rectangle())
                                Image(systemName: "backward.fill").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize, height: iconSize)
                            }
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .buttonStyle(.plain)
                        .disabled(library.queue.count <= 0 || library.queueIndex <= 0)
                        
                        Button(action: {
                            library.playButton()
                        }) {
                            ZStack {
                                Color.clear
                                    .contentShape(Rectangle())
                                Image(systemName: library.projectedPlaybackState == .playing ? "pause.fill" : "play.fill").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize * 0.75, height: iconSize * 0.75)
                            }
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            library.forwardButton()
                        }) {
                            ZStack {
                                Color.clear
                                    .contentShape(Rectangle())
                                Image(systemName: "forward.fill").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize, height: iconSize)
                            }
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .buttonStyle(.plain)
                        .disabled(library.queue.count <= 0 || library.queueIndex >= library.queue.count)
                        
                        ZStack { }
                        .frame(width: buttonSize, height: buttonSize)
                    }
                    .frame(width: windowSize.width / 3.0)
                    
                    // Playing next
                    let next : PlayableItem? = library.queueIndex + 1 < library.queue.count ? library.queue[library.queueIndex + 1] : nil
                    content.listItem(height: appData.appFormat.playerHeight, artwork: next?.getArtwork() ?? nil, mainTitle: "NEXT", subTitle: next?.getName() ?? "Unknown Title", fontSize: 12, subFontRatio: 1, subFontOpac: 0.4, artRadius: 0)
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: windowSize.width / 3.0, alignment: .trailing)
                }
            }
        }
        .frame(height: appData.appFormat.playerHeight)
        .onAppear() {
            musicProgressTracker.assign("PLAYER")
        }
    }
}

#Preview {
    VStack {
        
    }
}
