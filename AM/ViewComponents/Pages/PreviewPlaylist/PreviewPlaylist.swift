
//
//  PreviewSongGroup.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit

struct PreviewPlaylist: View {
    
    @ObservedObject var inst : PreviewPlaylistInstance
    
    @State var titleOpac = 0.0
    
    @State var showButtons: PlayableItem? = nil // Will be song
    @State var previewArt: [PlayableItem] = [] // Will be songs
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    
    var body: some View {
        GeometryReader { geom in
            ZStack {
                MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(.vertical) {
                    LazyVStack (spacing: 0) {
                        ZStack() {
                            HStack(alignment: .top, spacing: 0) {
                                if previewArt.count > 0 {
                                    ForEach(previewArt, id: \.self) { prev in
                                        // ******* AM ONLY
                                        if prev.getArtwork() != nil {
                                            ArtworkImage(prev.getArtwork()!, width: 250, height: 250)
                                                .blur(radius: 12)
                                        }
                                        else if prev.getArtworkURL().count > 0 {
                                            AsyncImage(url: URL(string: prev.getArtworkURL())) { image in
                                                if image.image != nil {
                                                    image.image!
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 250, height: 250)
                                                        .blur(radius: 12)
                                                }
                                            }
                                        }
                                        else {
                                            inst.library.EmptyArt(inst.appData, 250, 250)
                                        }
                                    }
                                }
                            }
                            .opacity(0.8)
                            .frame(width: geom.size.width)
                            .clipped()
                            .onAppear(perform: refreshPreviewArt)
                            .onChange(of: inst.songs, refreshPreviewArt)
                            
                            Text(inst.playlist.getName()).font(.system(size: 65, weight: .semibold, design: .default))
                                .opacity(5)
                                .shadow(color: .black, radius: 10, x: -3, y: 3)
                                .opacity(titleOpac)
                            
                            VStack() {
                                Spacer()
                                HStack {
                                    Button(action: { () in
                                        Task {
                                            await inst.playlist.play(inst.library)
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
                                    .padding(.bottom, 10)
                                    
                                    Button(action: { () in
                                        Task {
                                            await inst.playlist.shuffle(inst.library)
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
                                    .padding(.bottom, 10)
                                    
                                    Spacer()
                                    
                                    Button(action: { () in
                                        switch inst.sortMode {
                                            case .dateReleased:
                                                inst.sortMode = .dateAdded
                                            case .dateAdded:
                                                inst.sortMode = .artistName
                                            case .artistName:
                                                inst.sortMode = .albumName
                                            case .albumName:
                                                inst.sortMode = .songName
                                            case .songName:
                                                inst.sortMode = .popularity
                                            case .popularity:
                                                inst.sortMode = .dateAdded
                                        }
                                        inst.sort()
                                    }) {
                                        ZStack {
                                            MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor)
                                                .cornerRadius(100)
                                            
                                            HStack(spacing: 0) {
                                                Text("Sort by: ").font(.subheadline.bold()).opacity(0.5)
                                                Text("#" + inst.sortMode.description.lowercased().replacing(" ", with: "-")).font(.subheadline.bold()).colorMultiply(.accentColor)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 140, height: 25, alignment: .bottom)
                                    .padding(.bottom, 10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                        }
                        .frame(height:250)
                        
                        Color.white.opacity(0.15)
                            .frame(height: 1)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 0) {
                                Text("Title").font(.callout).opacity(0.1).lineLimit(1)
                                    .frame(width: (geom.size.width / 4.5) - (50), alignment: .leading)
                                    .padding([.trailing], 50)
                                
                                Text("Artists").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                    .frame(width: 250, alignment: .leading)
                                    .padding([.trailing], 100)
                                
                                Text("Album").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                    .frame(minWidth: 25, maxWidth: 250, alignment: .leading)
                                
                                Text("Duration").font(.system(size: 12)).opacity(0.1).lineLimit(1)
                                    .frame(minWidth: 25, maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding([.horizontal], 20)
                            .padding([.vertical], 15)
                            
                            inst.appData.colorScheme.mainColor.colorInvert().opacity(0.2)
                                .frame(height: 1)
                        }
                        
                        if inst.songs.count > 0 {
                            LazyVStack() {
                                ForEach(0..<inst.songs.count, id: \.self) { i in
                                    itemListing(item: inst.songs[i], itemOwner: inst.playlist)
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
                            inst.songs = []
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
                            if itemOwner.itemType == .playlist {
                                if (item.getArtwork() != nil) {
                                    ArtworkImage(item.getArtwork()!, width: 35, height: 35)
                                        .cornerRadius(inst.appData.appFormat.musicArtCorner)
                                        .padding([.trailing], 15)
                                }
                                else if (item.getArtworkURL().count > 0) {
                                    AsyncImage(url: URL(string: item.getArtworkURL())) { image in
                                        if image.image != nil {
                                            image.image!
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 35, height: 35)
                                                .cornerRadius(inst.appData.appFormat.musicArtCorner)
                                                .padding([.trailing], 15)
                                        }
                                    }
                                }
                                else {
                                    inst.library.EmptyArt(inst.appData, 35, 35)
                                        .cornerRadius(inst.appData.appFormat.musicArtCorner)
                                        .padding([.trailing], 15)
                                }
                            }
                            
                            Text(item.getName()).font(.callout).lineLimit(1)
                                .frame(width: (windowSize.width / 4.5) - (50 + 50), alignment: .leading)
                                .padding([.trailing], 50)
                            
                             Text(item.getArtistName()).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(width: 250, alignment: .leading)
                                .padding([.trailing], 100)
                            
                             Text(item.getAlbumTitle()).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(minWidth: 25, maxWidth: 250, alignment: .leading)
                            
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
            
//            if self.showButtons == item {
//                itemOptions(item)
//            }
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
            DefaultDraws.ContextMenuPlayable(item, inst.library, inst.content, extraOptions: [("Remove from Playlist", {
                item in
            }, Color.red)])
        }
    }
//    private func itemOptions(_ item: PlayableItem) -> some View {
//        HStack(spacing: 0) {
//            let buttonSize = 33.0
//            let iconSize = 15.0
//            
//            Button(action: {} ) {
//                ZStack {
//                    MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).cornerRadius(inst.appData.appFormat.musicArtCorner)
//                    Image(systemName: "ellipsis").resizable().aspectRatio(contentMode: .fit).frame(width: iconSize, height: iconSize).fontWeight(.bold)
//                }.frame(width: buttonSize, height: buttonSize)
//            }.buttonStyle(.plain)
//        }
//        .padding([.trailing], 50 + 30)
//    }

    public func refreshPreviewArt() {
        self.previewArt = []
        
        for i in 0..<inst.songs.count {
            if previewArt.count >= 8 { break }
            
            let item = inst.songs[i]
            if self.previewArt.filter( { $0.getAlbumTitle() == item.getAlbumTitle() } ).count == 0 {
                self.previewArt.append(item)
            }
        }
        
        withAnimation(.linear(duration: 0.2).delay(0.1)) {
            titleOpac = 1
        }
    }
}

#Preview {
//    var lib : MusicLibrary = MusicLibrary()
//    let ad = inst.appData()
//    PreviewPlaylist(library: lib, inst.appData: ad, content: ContentView(library: lib, inst.appData: ad))
}
