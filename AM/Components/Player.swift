//
//  SwiftUIView.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit

struct Player: View {
    @ObservedObject var library: MusicLibrary
    @State var appFormat: FormatData
    
    var content: ContentView
    var windowSize: CGSize
    
    var body: some View {
        ZStack {
            MaterialBackground().colorMultiply(appFormat.colorScheme.deepColor).ignoresSafeArea()
            
            VStack(spacing:0) {
                HStack(spacing:0) {
                    appFormat.colorScheme.mainColor.colorInvert()
                        .frame(width: windowSize.width * library.getPlaybackProgress())
                    appFormat.colorScheme.mainColor.colorInvert().opacity(0.2)
                }
                .frame(width: windowSize.width, height: 2)
                .animation(.linear(duration: 0.01), value: library.getPlaybackProgress())
                .onTapGesture { location in
                    library.setLivePlayback0to1(location.x / (windowSize.width))
                }
                
                // Playing, Interactives, Next
                HStack(alignment: .center, spacing: 0) {
                    // Currently Playing
                    if library.currentlyPlaying != nil {
                        content.listItem(height: appFormat.playerHeight, artwork: library.currentlyPlaying!.artwork!, mainTitle: library.currentlyPlaying!.title, subTitle: library.currentlyPlaying!.artistName)
                            .frame(maxWidth: windowSize.width / 3.0, alignment: .leading)
                    }
                    else {
                        content.listItem(height: appFormat.playerHeight, artwork: nil, mainTitle: "Unknown Song", subTitle: "...")
                            .frame(maxWidth: windowSize.width / 3.0, alignment: .leading)
                    }
                    
                    // Interactives
                    let buttonSize = 60.0
                    let iconSize = 25.0
                    HStack(alignment: .center, spacing: 0) {
                        Button(action: {}) {
                            ZStack {
                                Color.black.opacity(0.001)
                                Image(systemName: "repeat").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize * 0.6, height: iconSize * 0.6)
                            }
                            .opacity(0.4)
                        }
                        .frame(width: buttonSize / 1.5, height: buttonSize)
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            library.backwardButton()
                        }) {
                            ZStack {
                                Color.black.opacity(0.001)
                                Image(systemName: "backward.fill").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize, height: iconSize)
                            }
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            library.playButton()
                        }) {
                            ZStack {
                                Color.black.opacity(0.001)
                                Image(systemName: library.songState == .playing ? "pause.fill" : "play.fill").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize * 0.75, height: iconSize * 0.75)
                            }
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            library.forwardButton()
                        }) {
                            ZStack {
                                Color.black.opacity(0.001)
                                Image(systemName: "forward.fill").resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: iconSize, height: iconSize)
                            }
                        }
                        .frame(width: buttonSize, height: buttonSize)
                        .buttonStyle(.plain)
                        .disabled(library.workingQueue.count <= 0)
                        
                        ZStack { }
                        .frame(width: buttonSize, height: buttonSize)
                    }
                    .frame(width: windowSize.width / 3.0)
//                    .shadow(color:.black.opacity(0.5), radius:5, x:2, y:3)
                    
                    // Playing next
                    let next = library.workingQueue.count > 1 ? library.workingQueue[1] : nil
                    content.listItem(height: appFormat.playerHeight, artwork: next != nil ? next!.artwork : nil, mainTitle: "NEXT", subTitle: next != nil ? next!.title : "Unknown Title", fontSize: 12, subFontRatio: 1, subFontOpac: 0.4)
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: windowSize.width / 3.0, alignment: .trailing)
                }
            }
        }
        .frame(height: appFormat.playerHeight)
    }
}

#Preview {
    VStack {
        
    }
}
