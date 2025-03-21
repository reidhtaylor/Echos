//
//  PreviewSongGroup.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit

struct PreviewAlbum: View {
    
    @ObservedObject var inst : PreviewAlbumInstance
    
    @State var titleOpac = 0.0
    
    @State var showButtons: PlayableItem? = nil // Will be song
    @State var previewArt: [PlayableItem] = [] // Will be songs
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    
    var body: some View {
        GeometryReader { geom in
            ZStack {
                MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(.vertical) {
                    VStack (spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            
                            // Top View (Banner)
                            HStack(alignment: .bottom, spacing: 20) {
                                if inst.album.getArtwork() != nil {
                                    ArtworkImage(inst.album.getArtwork()!, width: 200, height: 200)
                                        .cornerRadius(inst.appData.appFormat.musicArtCorner * 2)
                                }
                                else if (inst.album.getArtworkURL().count > 0) {
                                    AsyncImage(url: URL(string: inst.album.getArtworkURL())) { image in
                                        if image.image != nil {
                                            image.image!
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200, height: 200)
                                                .cornerRadius(inst.appData.appFormat.musicArtCorner * 2)
                                        }
                                    }
                                }
                                else {
                                    inst.library.EmptyArt(inst.appData, 200, 200)
                                        .cornerRadius(inst.appData.appFormat.musicArtCorner * 2)
                                }
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Spacer()
                                    
                                    Text(inst.album.getName()).font(.largeTitle.bold()).lineLimit(1)
                                    Text(inst.album.getArtistName()).font(.title2).opacity(0.5).lineLimit(1)
                                    
                                    HStack {
                                        Button(action: { () in
                                            Task {
                                                await inst.album.play(inst.library)
                                            }
                                        }) {
                                            ZStack {
                                                MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor)
                                                    .cornerRadius(5)
                                                Text("Play").font(.title3.bold())
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .frame(width: 175, height: 40, alignment: .bottom)
                                        
                                        Button(action: { () in
                                            Task {
                                                await inst.album.shuffle(inst.library)
                                            }
                                        }) {
                                            ZStack {
                                                MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor)
                                                    .cornerRadius(5)
                                                Text("Shuffle").font(.title3.bold())
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .frame(width: 175, height: 40, alignment: .bottom)
                                    }
                                }
                                .frame(height:200)
                            }
                            .frame(maxWidth: .infinity, alignment: .bottomLeading)
                        }
                        .frame(height: 350)
                        .padding(.top, 5)
                        .padding(.bottom, 30)
                        .padding([.leading], 30)
                        .background(content: {
                            if inst.album.getArtwork() != nil {
                                ArtworkImage(inst.album.getArtwork()!, width: geom.size.width)
                                    .blur(radius: 250)
                            }
                            else {
                                inst.library.EmptyArt(inst.appData, geom.size.width, geom.size.width)
                                    .blur(radius: 250)
                            }
                        })
                        .clipped()
                        
                        Color.white.opacity(0.15)
                            .frame(height: 1)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 0) {
                                Text("#").font(.headline).opacity(0.1)
                                    .frame(width: 35)
                                    .padding([.trailing], 15)
                                //                                .border(.red)
                                
                                Text("Title").font(.callout).opacity(0.1).lineLimit(1)
                                    .frame(width: (geom.size.width / 4.5), alignment: .leading)
                                    .padding([.trailing], 50)
                                //                                .border(.red)
                                
                                Text("Artists").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                    .frame(width: 250, alignment: .leading)
                                    .padding([.trailing], 100)
                                //                                .border(.red)
                                
                                Text("Listens").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                    .frame(minWidth: 25, maxWidth: 250, alignment: .center)
                                //                                .border(.red)
                                
                                Text("Duration").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                    .frame(minWidth: 25, maxWidth: .infinity, alignment: .trailing)
                                //                                .border(.red)
                            }
                            .padding([.horizontal], 20)
                            .padding([.vertical], 15)
                            
                            inst.appData.colorScheme.mainColor.colorInvert().opacity(0.2)
                                .frame(height: 1)
                        }
                        
                        if inst.songs.count > 0 {
                            LazyVStack() {
                                ForEach(0..<inst.songs.count, id: \.self) { i in
                                    itemListing(item: inst.songs[i], itemOwner: inst.album)
                                }
                            }
                            .frame(maxHeight: .infinity)
                            .padding(.bottom, self.windowSize.height * 0.4)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .scrollContentBackground(.hidden)
                }
                .frame(maxHeight: .infinity)
                .scrollIndicators(.hidden)
                
                VStack {
                    ZStack(alignment: .leading) {
                        MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).opacity(0.9)
                        
                        Button(action: { () in
                            inst.content.PopPage()
                        }) {
                            ZStack(alignment: .leading) {
                                Rectangle().colorMultiply(.clear)
                                Image(systemName: "arrow.backward")
                            }
                        }
                        .frame(width: 60, height: 40)
                        .padding(.leading, 20)
                        .buttonStyle(.plain)
                        .shadow(color: .black, radius: 5, x: 0, y: 0)
                    }
                    .frame(width: geom.size.width, height: 40)
                    
                    Spacer()
                }
            }
            .onAppear() { self.windowSize = geom.size }
            .onChange(of: geom.size) { self.windowSize = geom.size }
        }
    }
    
    enum ItemStyle: Int {
        case albumItem
        case playlistItem
    }
    private func itemListing(item: PlayableItem, itemOwner : PlayableItem) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: {
                Task {
                    // ******* AM ONLY
                    await inst.library.playSong(item.itemSongAM!)
                }
            }) {
                ZStack {
                    MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text(String(item.getTrackNumber())).font(.headline).lineLimit(1)
                                .frame(width: 35)
                                .padding([.trailing], 15)
                            
                            if itemOwner.itemType == .playlist {
                                if (item.getArtwork() != nil) {
                                    ArtworkImage(item.getArtwork()!, width: 35, height: 35)
                                        .cornerRadius(inst.appData.appFormat.musicArtCorner)
                                        .padding([.trailing], 15)
                                }
                                else {
                                    inst.library.EmptyArt(inst.appData, 35, 35)
                                        .cornerRadius(inst.appData.appFormat.musicArtCorner)
                                        .padding([.trailing], 15)
                                }
                            }
                            
                            Text(item.getName()).font(.callout).lineLimit(1)
                                .frame(width: (windowSize.width / 4.5), alignment: .leading)
                                .padding([.trailing], 50)
                            
                             Text(item.getArtistName()).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(width: 250, alignment: .leading)
                                .padding([.trailing], 100)
                            
                             Text(String(item.getPlayCount())).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(minWidth: 25, maxWidth: 250, alignment: .center)
                            
                            Text(inst.library.getTimeString(item.getDuration())).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(minWidth: 25, maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding([.horizontal], 15)
                        .frame(height: 60)
                        
                        inst.appData.colorScheme.mainColor.colorInvert().opacity(0.2)
                            .frame(height: 1)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if self.showButtons == item {
                itemOptions(item)
            }
        }
        .listRowSeparator(.hidden)
        .onHover() { over in
            if over {
                self.showButtons = item
            }
            else if self.showButtons == item {
                self.showButtons = nil
            }
        }
        .contextMenu {
            DefaultDraws.ContextMenuPlayable(item, inst.library, inst.content)
        }
    }
    private func itemOptions(_ item: PlayableItem) -> some View {
        HStack(spacing: 0) {
            let buttonSize = 33.0
            let iconSize = 15.0
            
            Button(action: {} ) {
                ZStack {
                    MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).cornerRadius(inst.appData.appFormat.musicArtCorner)
                    Image(systemName: "ellipsis").resizable().aspectRatio(contentMode: .fit).frame(width: iconSize, height: iconSize).fontWeight(.bold)
                }.frame(width: buttonSize, height: buttonSize)
            }.buttonStyle(.plain)
        }
        .padding([.trailing], 50 + 30)
    }
}

#Preview {
//    var lib : MusicLibrary = MusicLibrary()
//    let ad = AppData()
//    PreviewAlbum(library: lib, appData: ad, content: ContentView(library: lib, appData: ad))
}
