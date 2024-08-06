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
    @State var appData: AppData
    
    var content: ContentView
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    
    var body: some View {
        GeometryReader { geom in
            // Main
            ZStack {
                MaterialBackground().colorMultiply(appData.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // FAVORITES (user specified
                        VStack (alignment: .leading, spacing: 0) {
                            mainTitle(title:"Favorites") { }
                            
                            ScrollView(.horizontal, showsIndicators:false) {
                                HStack() {
                                    // Show favorite items
                                    ForEach(0..<library.favoriteItems.count, id: \.self) { i in
                                        VStack {
                                            content.gridItem(library.favoriteItems[i].artwork, title: library.favoriteItems[i].title, subTitle: library.favoriteItems[i].artistName, size: 195, action: {
                                                    Task {
                                                        await library.playSong(library.favoriteItems[i], library.workingQueue)
                                                    }
                                            })
                                        }
                                    }
                                    
                                    // Add new favorite
                                    Button(action: { }) {
                                        ZStack {
                                            MaterialBackground().colorMultiply(appData.colorScheme.mainColor)
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
                        .padding([.bottom], 30)
                        .frame(width: windowSize.width - 100, alignment: .leading)
                        .clipped()
                        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                        // FAVORITES
                        
                        // MOST PLAYED
                        VStack (alignment: .leading, spacing: 0) {
                            mainTitle(title:"Most Played") { }
                            
                            ScrollView(.horizontal, showsIndicators:false) {
                                HStack() {
                                    // Show most played items
                                    ForEach(0..<max(10, library.mostPlayed.count), id: \.self) { i in
                                        if i < library.mostPlayed.count {
                                            content.gridItem(library.mostPlayed[i].artwork, title: library.mostPlayed[i].title, subTitle: library.mostPlayed[i].artistName, size: 195, action: { () in
                                                library.setPreviewingAlbum(library.mostPlayed[i], content)
                                            })
                                        }
                                        else {
                                            VStack {
                                                appData.colorScheme.mainColor.opacity(0.1)
                                                    .frame(width: 195, height: 195)
                                                    .cornerRadius(appData.appFormat.musicArtCorner)
                                                
                                                Text("• • •")
                                                    .font(.subheadline)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.bottom], 30)
                        .frame(width: windowSize.width - 100, alignment: .leading)
                        .clipped()
                        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                        // MOST PLAYED
                        
                        // RECENTLY PLAYED
                        VStack (alignment: .leading, spacing: 0) {
                            mainTitle(title:"Recently Played") { }
                            
                            ScrollView(.horizontal, showsIndicators:false) {
                                HStack() {
                                    // Show recently played items
                                    ForEach(0..<max(10, library.recentlyPlayed.count), id: \.self) { i in
                                        if i < library.recentlyPlayed.count {
                                            content.gridItem(library.recentlyPlayed[i].artwork, title: library.recentlyPlayed[i].title, subTitle: library.recentlyPlayed[i].artistName, size: 195, action: { () in
                                                library.setPreviewingAlbum(library.recentlyPlayed[i], content)
                                            })
                                        }
                                        else {
                                            VStack {
                                                appData.colorScheme.mainColor.opacity(0.1)
                                                    .frame(width: 195, height: 195)
                                                    .cornerRadius(appData.appFormat.musicArtCorner)
                                                
                                                Text("• • •")
                                                    .font(.subheadline)
                                            }
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
                            HStack(spacing: 0) {
                                // ADD NEW PLAYLIST
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "plus").aspectRatio(contentMode: .fit).frame(width:30, height:30)
                                        .background(MaterialBackground().colorMultiply(appData.colorScheme.mainColor))
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 30, alignment: .trailing)
                                
                                // MORE OPTIONS
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "ellipsis").aspectRatio(contentMode: .fit).frame(width:30, height:30)
                                        .background(MaterialBackground().colorMultiply(appData.colorScheme.mainColor))
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 30, alignment: .trailing)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding([.trailing], 5)
                        }
                        
                        ScrollView(.horizontal, showsIndicators:false) {
                            HStack(alignment: .top) {
                                // Show all playlist items
                                ForEach(0..<max(10, library.playlists.count), id: \.self) { i in
                                    if i < library.playlists.count {
                                        Button(action: {
                                            library.setPreviewingPlaylist(library.playlists[i], content)
                                        }) {
                                            VStack {
                                                ArtworkImage(library.playlists[i].artwork!, width: 195, height: 195)
                                                    .cornerRadius(appData.appFormat.musicArtCorner)
                                                
                                                Text(library.playlists[i].name)
                                                    .font(.subheadline)
                                            }.frame(width:195)
                                        }.buttonStyle(.plain)
                                    }
                                    else {
                                        VStack {
                                            appData.colorScheme.mainColor.opacity(0.1)
                                                .frame(width: 195, height: 195)
                                                .cornerRadius(appData.appFormat.musicArtCorner)
                                            
                                            Text("• • •")
                                                .font(.subheadline)
                                        }
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
                            // Button to reshuffle list
                            Button(action: {
                                library.refreshShuffleSample()
                            }) {
                                Image(systemName: "shuffle").aspectRatio(contentMode: .fit).frame(width:20, height:20)
                                    .cornerRadius(4)
                                    .padding(5)
                                    .background(MaterialBackground().colorMultiply(appData.colorScheme.mainColor))
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding([.trailing], 5)
                        }
                        
                        ScrollView(.horizontal, showsIndicators:false) {
                            HStack() {
                                // Show each random item
                                ForEach(0..<max(10, library.shuffleSample.count), id: \.self) { i in
                                    if i < library.shuffleSample.count {
                                        content.gridItem(library.shuffleSample[i].artwork, title: library.shuffleSample[i].title, subTitle: library.shuffleSample[i].artistName, size: 195, action: {
                                                Task {
                                                    await library.playSong(library.shuffleSample[i], library.workingQueue)
                                                }
                                        })
                                    }
                                    else {
                                        VStack {
                                            appData.colorScheme.mainColor.opacity(0.1)
                                                .frame(width: 195, height: 195)
                                                .cornerRadius(appData.appFormat.musicArtCorner)
                                            
                                            Text("• • •")
                                                .font(.subheadline)
                                        }
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
