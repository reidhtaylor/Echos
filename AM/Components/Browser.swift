//
//  Browser.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit

struct Browser: View {
    
    @ObservedObject var library: MusicLibrary
    @State var appFormat: FormatData
    
    var content: ContentView
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    
    var body: some View {
        GeometryReader { geom in
            // Main
            ZStack {
                MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // MOST PLAYED
                        HStack(spacing: 0) {
                            mainTitle(title: "Most Played") { }
                                .frame(maxWidth: .infinity)
                            
                            Text("Custom").font(.largeTitle).bold()
                                .frame(width: 200, alignment: .topTrailing)
                                .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                                .lineLimit(1)
                                .padding([.trailing], 25).opacity(0.25)
                            
                        }
                        .frame(width: windowSize.width - 100)
                        
                        ScrollView(.horizontal, showsIndicators:false) {
                            HStack(alignment:.top) {
                                VStack {
                                    if library.mostPlayed == nil {
                                        appFormat.colorScheme.mainColor.opacity(0.1)
                                            .frame(width: 195, height: 195)
                                            .cornerRadius(appFormat.musicArtCorner)
                                        
                                        Text("• • •")
                                            .font(.subheadline)
                                    }
                                    else {
                                        content.gridItem(library.mostPlayed!.artwork!, title: library.mostPlayed!.title, subTitle: library.mostPlayed!.albumTitle!, size: 195, action: { () in
                                            Task {
                                                await library.playSong(library.mostPlayed!, library.workingQueue)
                                            }
                                        })
                                    }
                                }
                                .frame(width:195)
                                
                                ForEach(0..<10, id: \.self) { i in
                                    Button(action: {}) {
                                        ZStack {
                                            MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor)
                                                .frame(width:175, height:175)
                                            
                                            Image(systemName: "plus").resizable()
                                                .aspectRatio(1, contentMode: .fit)
                                                .frame(width:60, height:60)
                                                .opacity(0.2).fontWeight(.thin)
                                        }
                                        .frame(width: 195, height: 195)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(width: windowSize.width - 100, alignment: .leading)
                        .clipped()
                        .padding([.bottom], 30)
                        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                        // MOST PLAYED
                        
                        // RECENTLY PLAYED
                        VStack (alignment: .leading, spacing: 0) {
                            mainTitle(title:"Recently Played") { }
                            
                            ScrollView(.horizontal, showsIndicators:false) {
                                HStack() {
                                    if library.recentlyPlayed.count == 0 {
                                        ForEach(0..<10, id: \.self) { i in
                                            VStack {
                                                appFormat.colorScheme.mainColor.opacity(0.1)
                                                    .frame(width: 195, height: 195)
                                                    .cornerRadius(appFormat.musicArtCorner)
                                                
                                                Text("• • •")
                                                    .font(.subheadline)
                                            }
                                        }
                                    }
                                    else {
                                        ForEach(library.recentlyPlayed) { album in
                                            content.gridItem(album.artwork, title: album.title, subTitle: album.artistName, size: 195, action: { () in
                                                library.setPreviewingAlbum(album, content)
                                            })
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.bottom], 30)
                        .frame(width: windowSize.width - 100, alignment: .leading)
                        .clipped()
                        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                        // RECENTLY PLAYED

                        // PLAYLISTS
                        mainTitle(title:"Playlists") {
                            Button(action: {
                                
                            }) {
                                Image(systemName: "ellipsis").aspectRatio(contentMode: .fit).frame(width:30, height:30)
                                    .background(MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding([.trailing], 5)
                        }
                        
                        ScrollView(.horizontal, showsIndicators:false) {
                            HStack(alignment: .top) {
                                Button(action: {}) {
                                    ZStack {
                                        MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor)
                                            .frame(width:175, height:175)
                                        
                                        Image(systemName: "plus").resizable()
                                            .aspectRatio(1, contentMode: .fit)
                                            .frame(width:60, height:60)
                                            .opacity(0.2).fontWeight(.thin)
                                    }
                                    .frame(width: 195, height: 195)
                                }.buttonStyle(.plain)
                                
                                if library.playlists.count == 0 {
                                    ForEach(0..<9, id: \.self) { i in
                                        VStack {
                                            appFormat.colorScheme.mainColor.opacity(0.1)
                                                .frame(width: 195, height: 195)
                                                .cornerRadius(appFormat.musicArtCorner)
                                            
                                            Text("• • •")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                else {
                                    ForEach(library.playlists) { pl in
                                        Button(action: {
                                            library.setPreviewingPlaylist(pl, content)
                                        }) {
                                            VStack {
                                                ArtworkImage(pl.artwork!, width: 195, height: 195)
                                                    .cornerRadius(appFormat.musicArtCorner)
                                                
                                                Text(pl.name)
                                                    .font(.subheadline)
                                            }.frame(width:195)
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding([.bottom], 30)
                        .frame(width: windowSize.width - 100, alignment: .leading)
                        .clipped()
                        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                        // PLAYLISTS
                        
                        // SAMPLE
                        mainTitle(title:"Shuffle Sample") {
                            Button(action: {
                                library.refreshRandomSongs()
                            }) {
                                Image(systemName: "shuffle").aspectRatio(contentMode: .fit).frame(width:20, height:20)
                                    .cornerRadius(4)
                                    .padding(5)
                                    .background(MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor))
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding([.trailing], 5)
                        }
                        
                        ScrollView(.horizontal, showsIndicators:false) {
                            HStack () {
                                if library.randomSongs.count == 0 {
                                    ForEach(0..<9, id: \.self) { i in
                                        VStack {
                                            appFormat.colorScheme.mainColor.opacity(0.1)
                                                .frame(width: 195, height: 195)
                                                .cornerRadius(appFormat.musicArtCorner)
                                            
                                            Text("• • •")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                else {
                                    ForEach(library.randomSongs) { song in
                                        content.gridItem(song.artwork, title: song.title, subTitle: song.albumTitle!, size: 195, action: { () in
                                            Task {
                                                let albRq = MusicLibraryRequest<Album>()
                                                let album = (try await albRq.response()).items.first(where: { $0.title == song.albumTitle! })
                                                if album != nil {
                                                    library.setPreviewingAlbum(album!, content)
                                                }
                                            }
                                        })
                                    }
                                }
                            }
                        }
                        .padding([.bottom], 30)
                        .frame(width: windowSize.width - 100, alignment: .leading)
                        .clipped()
                        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                        // SAMPLE
                    }
                    .frame(width: windowSize.width)
                    .padding(50)
                }
                .frame(maxWidth: windowSize.width)
            }
            .onAppear() { windowSize = geom.size }
            .onChange(of: geom.size) { windowSize = geom.size }
        }
    }
    
    private func mainTitle(title: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 0) {
            Text(title).font(.largeTitle).bold()
                .frame(maxHeight: .infinity, alignment: .topTrailing)
                .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                .lineLimit(1)
            
            ZStack {
                Color.clear
                content()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 45)
//            .border(.blue)
        }
        .frame(height:45)
        .frame(maxWidth: windowSize.width - 100)
    }
}

#Preview {
    VStack {
        
    }
}
