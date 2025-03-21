//
//  PreviewSongGroup.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit

struct PreviewArtist: View {
    
    @ObservedObject var inst : PreviewArtistInstance

    @State private var image: NSImage? = nil
    @State private var imageResolution: CGSize? = nil
    
    @State var catalogues: [LineCatalogue] = []
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    
    @StateObject var hoverStatesManager: HoverStateManager = HoverStateManager()
    
    var body: some View {
        GeometryReader { geom in
            ZStack {
                MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(.vertical) {
                    VStack (spacing: 0) {
                        ZStack(alignment: .center) {
                            if image != nil {
                                Image(nsImage: image!).resizable().aspectRatio(contentMode: .fill).frame(width: geom.size.width, height: geom.size.width)
                                    .blur(radius: 150)
                                    .opacity(0.3)
                            }
                            if image != nil {
                                Image(nsImage: image!).resizable().aspectRatio(contentMode: .fill).frame(width: 180, height: 180)
                                    .cornerRadius(150)
                                    .shadow(radius: 30)
                            }
                            
                            VStack {
                                Spacer()
                                
                                HStack(spacing: 10) {
                                    Button(action: { () in
                                        Task {
                                            var allSongs : [PlayableItem] = []
                                            for a in inst.library.songs {
                                                if a.getArtistName() == inst.artist.getArtistName() { allSongs.append(a) }
                                            }
                                            await allSongs[0].playSet(allSongs, inst.library)
                                        }
                                    }) {
                                        ZStack {
                                            MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor)
                                                .cornerRadius(100)
                                            Image(systemName: "play.fill")
                                        }
                                    }
                                    .frame(width: 40, height: 40)
                                    .buttonStyle(.plain)
                                    
                                    Text(inst.artist.getName()).font(.title.bold()).lineLimit(1)
                                    
                                    Spacer()
                                }
                                .padding(.bottom, 20)
                                .padding(.leading, 40)
                            }.frame(width: geom.size.width, height: 400)
                        }
                        .frame(width: geom.size.width, height: 400)
                        .clipped()
                        
                        Color.clear
                            .frame(height: 1)
                            .shadow(radius: 20)
                        
                        VStack (spacing: 10) {
                            if catalogues.count > 0 {
                                if catalogues[0].items.count > 0 {
                                    DefaultDraws.DrawLineCatalogueSongs(catalogues[0], width: geom.size.width - 60, height: 240, content: inst.content, library: inst.library, appData: inst.appData, hoverStates: hoverStatesManager)
                                }
                                
                                ForEach(1..<catalogues.count, id: \.self) { c in
                                    if catalogues[c].items.count > 0 {
                                        DefaultDraws.DrawLineCatalogue(catalogues[c], width: geom.size.width - 60, height: 240, content: inst.content, library: inst.library, appData: inst.appData, subTitle: { $0.getYear() }, hoverStates: hoverStatesManager)
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
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
            .onAppear() {
                self.windowSize = geom.size
                
                let artworkURL = inst.artist.itemArtistAM?.artwork?.url(width: 1000, height: 1000) ?? URL(string: inst.artist.getArtworkURL())
                
                if let url = artworkURL {
                    URLSession.shared.dataTask(with: url) { data, response, error in
                        guard let data = data, error == nil, let loadedImage = NSImage(data: data) else {
                            print("Failed to load image")
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.image = loadedImage
                            self.imageResolution = loadedImage.size
                        }
                    }.resume()
                }
                
                SetupCatalogue()
            }
            .onChange(of: geom.size) { self.windowSize = geom.size }
        }
    }
    
    func SetupCatalogue() {
        Task {
            var topSongs : [PlayableItem] = []
            for a in inst.library.songs {
                if a.getArtistName() == inst.artist.getArtistName() {
                    topSongs.append(a)
                }
                if topSongs.count > 20 { break }
            }
            catalogues.append(LineCatalogue(title: "Top Songs", items: topSongs))
        }
        
        Task {
            var albums : [PlayableItem] = []
            for a in inst.library.albums {
                if a.getArtistName() == inst.artist.getArtistName() && !isSingle(a) {
                    albums.append(a)
                }
            }
            catalogues.append(LineCatalogue(title: "Albums", items: albums))
        }
        
        Task {
            var singles : [PlayableItem] = []
            for a in inst.library.albums {
                if a.getArtistName() == inst.artist.getArtistName() && isSingle(a) {
                    singles.append(a)
                }
            }
            catalogues.append(LineCatalogue(title: "Singles & EPs", items: singles))
        }
    }
    
    func isSingle(_ item : PlayableItem) -> Bool {
        if item.itemType == .song {
            return (item.getAlbumTitle().lowercased().contains("single"))
        }
        else if item.itemType == .album {
            return (item.getName().lowercased().contains("single"))
        }
        return false
    }
}

#Preview {
//    var lib : MusicLibrary = MusicLibrary()
//    let ad = AppData()
//    PreviewAlbum(library: lib, appData: ad, content: ContentView(library: lib, appData: ad))
}
