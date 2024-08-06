//
//  Browser.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit

struct PreviewAlbum: View {
    
    @ObservedObject var library: MusicLibrary
    @State var appData: AppData
    
    let content: ContentView
    
    @State var titleOpac = 0.0
    
    @State var showButtons: Song? = nil
    @State var previewArt: [Song] = []
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    
    var body: some View {
        GeometryReader { geom in
            ZStack {
                MaterialBackground().colorMultiply(appData.colorScheme.mainColor).ignoresSafeArea()
                
                VStack (spacing: 0) {
                    if library.previewingPlaylist != nil {
                        ZStack() {
                            HStack(alignment: .top, spacing: 0) {
                                if previewArt.count > 0 {
                                    ForEach(previewArt) { prev in
                                        ArtworkImage(prev.artwork!, width: 200, height: 200)
                                    }
                                }
                            }
                            .opacity(0.8)
                            .frame(width: geom.size.width)
                            .clipped()
                            .onAppear(perform: refreshPreviewArt)
                            .onChange(of: library.previewingSongs, refreshPreviewArt)
                            
                            Text(library.previewingPlaylist!.name).font(.system(size: 100, weight: .semibold, design: .default))
                                .opacity(5)
                                .shadow(color: .black, radius: 10, x: -3, y: 3)
                                .opacity(titleOpac)
                            
                            Button(action: { () in
                                library.previewingAlbum = nil
                                library.previewingPlaylist = nil
                                content.page = .browser
                            }) {
                                Image(systemName: "arrow.backward")
                            }
                            .frame(maxWidth: geom.size.width - 40, maxHeight: 200 - 40, alignment: .topLeading)
                            .padding(20)
                            .buttonStyle(.plain)
                            .shadow(color: .black, radius: 5, x: 0, y: 0)
                        }
                    }
                    else if library.previewingAlbum != nil {
                        VStack(alignment: .leading, spacing: 50) {
                            Button(action: { () in
                                library.previewingAlbum = nil
                                library.previewingPlaylist = nil
                                content.page = .browser
                            }) {
                                Image(systemName: "arrow.backward")
                            }
                            .frame(height:50)
                            .padding([.leading], 20)
                            .buttonStyle(.plain)
                            
                            HStack(alignment: .center, spacing: 20) {
                                ArtworkImage(library.previewingAlbum!.artwork!, width: 200, height: 200)
                                    .cornerRadius(appData.appFormat.musicArtCorner * 2)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(library.previewingAlbum != nil ? library.previewingAlbum!.title : library.previewingPlaylist != nil ? library.previewingPlaylist!.name : "Title").font(.largeTitle.bold()).lineLimit(1)
                                    Text(library.previewingAlbum != nil ? library.previewingAlbum!.artistName : library.previewingPlaylist != nil ? library.previewingPlaylist!.shortDescription ?? "None" : "Artist").font(.title2).opacity(0.5).lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .bottomLeading)
                            .padding(20)
                        }
                        .background(content: {
                            ArtworkImage(library.previewingAlbum!.artwork!, width: geom.size.width)
                                .blur(radius: 250)
                        })
                        .clipped()
                    }
                    
                    Color.white.opacity(0.15)
                        .frame(height: 1)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text("#").font(.headline).opacity(0.1)
                                .frame(width: 35)
                                .padding([.trailing], 15)
//                                .border(.red)

                            Text("Title").font(.callout).opacity(0.1).lineLimit(1)
                                .frame(width: (geom.size.width / 4.5) - (library.previewingPlaylist == nil ? 0 : 50), alignment: .leading)
                                .padding([.trailing], 50)
//                                .border(.red)
                            
                            Text("Artists").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                .frame(width: 250, alignment: .leading)
                                .padding([.trailing], 100)
//                                .border(.red)
                            
                            Text(library.previewingPlaylist == nil ? "Listens" : "Album").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                .frame(minWidth: 25, maxWidth: 250, alignment: library.previewingPlaylist == nil ? .center : .leading)
//                                .border(.red)
                            
                            Text("Duration").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                .frame(minWidth: 25, maxWidth: .infinity, alignment: .trailing)
//                                .border(.red)
                        }
                        .padding([.horizontal], 20)
                        .padding([.vertical], 15)
                        
                        appData.colorScheme.mainColor.colorInvert().opacity(0.2)
                            .frame(height: 1)
                    }

                    List() {
                        ForEach(library.previewingSongs) { s in
                            itemListing(s, style: (library.previewingAlbum != nil ? .albumItem : .playlistItem))
                        }
                        .listRowInsets(.init(top: 0, leading: -5, bottom: 0, trailing: -5))
                    }
                    .frame(maxHeight: .infinity)
                    .listStyle(.plain)
                    .scrollIndicators(.hidden) // WHYYYYYYYYYY
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .scrollContentBackground(.hidden)
            }
            .onAppear() { self.windowSize = geom.size }
            .onChange(of: geom.size) { self.windowSize = geom.size }
        }
    }
    
    enum ItemStyle: Int {
        case albumItem
        case playlistItem
    }
    private func itemListing(_ song: Song, style: ItemStyle) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: {
                Task {
                    await library.playSong(song, library.workingQueue)
                }
            }) {
                ZStack {
                    MaterialBackground().colorMultiply(appData.colorScheme.mainColor)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text(style == .albumItem ? String(song.trackNumber ?? -1) : String(library.previewingSongs.firstIndex(where: { $0 == song })! + 1)).font(.headline).lineLimit(1)
                                .frame(width: 35)
                                .padding([.trailing], 15)
                            
                            if style == .playlistItem {
                                ArtworkImage(song.artwork!, width: 35, height: 35)
                                    .cornerRadius(appData.appFormat.musicArtCorner)
                                    .padding([.trailing], 15)
                            }
                            
                            Text(song.title).font(.callout).lineLimit(1)
                                .frame(width: (windowSize.width / 4.5) - (style == .albumItem ? 0 : 50 + 50), alignment: .leading)
                                .padding([.trailing], 50)
                            
                            Text(song.artistName).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(width: 250, alignment: .leading)
                                .padding([.trailing], 100)
                            
                            Text(style == .albumItem ? String(song.playCount ?? 0) : song.albumTitle!).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(minWidth: 25, maxWidth: 250, alignment: style == .albumItem ? .center : .leading)
                            
                            Text(library.getTimeString((song.duration ?? 0) / 1000.0)).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(minWidth: 25, maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding([.horizontal], 15)
                        .frame(height: 60)
                        
                        appData.colorScheme.mainColor.colorInvert().opacity(0.2)
                            .frame(height: 1)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if self.showButtons == song {
                itemOptions(song)
            }
        }
        .listRowSeparator(.hidden)
        .onHover() { over in
            if over {
                self.showButtons = song
            }
            else if self.showButtons == song {
                self.showButtons = nil
            }
        }
    }
    private func itemOptions(_ song: Song) -> some View {
        HStack(spacing: 0) {
            let buttonSize = 33.0
            let iconSize = 15.0
            
            Button(action: {} ) {
                ZStack {
                    MaterialBackground().colorMultiply(appData.colorScheme.mainColor).cornerRadius(appData.appFormat.musicArtCorner)
                    Image(systemName: "ellipsis").resizable().aspectRatio(contentMode: .fit).frame(width: iconSize, height: iconSize).fontWeight(.bold)
                }.frame(width: buttonSize, height: buttonSize)
            }.buttonStyle(.plain)
            
            Button(action: {
                library.workingQueue.append(MusicPlayer.Queue.Entry(song))
            } ) {
                ZStack {
                    MaterialBackground().colorMultiply(appData.colorScheme.mainColor).cornerRadius(appData.appFormat.musicArtCorner)
                    Image(systemName: "text.append").resizable().aspectRatio(contentMode: .fit).frame(width: iconSize, height: iconSize)
                }.frame(width: buttonSize, height: buttonSize)
            }.buttonStyle(.plain)
            
            Button(action: {
                library.workingQueue.insert(MusicPlayer.Queue.Entry(song), at: library.currentlyPlaying != nil ? 1 : 0)
            } ) {
                ZStack {
                    MaterialBackground().colorMultiply(appData.colorScheme.mainColor).cornerRadius(appData.appFormat.musicArtCorner)
                    Image(systemName: "text.insert").resizable().aspectRatio(contentMode: .fit).frame(width: iconSize, height: iconSize)
                }.frame(width: buttonSize, height: buttonSize)
            }.buttonStyle(.plain)
        }
        .padding([.trailing], 50 + 30)
    }

    public func refreshPreviewArt() {
        self.previewArt = []
        
        if library.previewingSongs.count == 0 {
            return
        }
        
        while self.previewArt.count < 10 {
            let rand = library.previewingSongs.randomElement()!
            if self.previewArt.filter( { $0.albumTitle == rand.albumTitle } ).count == 0 || library.previewingSongs.count <= self.previewArt.count {
                self.previewArt.append(rand)
            }
        }
        
        withAnimation(.linear(duration: 0.2).delay(0.1)) {
            titleOpac = 1
        }
    }
}

#Preview {
    var lib : MusicLibrary = MusicLibrary()
    let ad = AppData()
    PreviewAlbum(library: lib, appData: ad, content: ContentView(library: lib, appData: ad))
}
