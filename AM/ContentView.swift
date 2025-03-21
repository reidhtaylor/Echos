//
//  ContentView.swift
//  AM
//
//  Created by Reid Taylor on 12/16/23.
//

import SwiftUI
import AppKit
import MusicKit

struct MaterialBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground

        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}

struct ContentView: View {
    @ObservedObject var library: MusicLibrary
    @ObservedObject var appData: AppData
    
    @State var unhideQueueWidth : CGFloat = 0
    
    @State var navStack: [PageInstance] = []
    @State var selectedPageGroup : Int = 0
    
    @State var miniSearcher: ContentSearcher? = nil
    
    var body: some View {
        GeometryReader { geom in
            if (self.appData.queueState == .isolated) {
                // Isolated Queue
                Queue(library:library, appData: appData, content: self, musicProgressTracker: MusicProgressTracker(library: library))
            }
            else if (self.appData.queueState != .presenter) {
                // Split Player and Main/Queue
                ZStack {
                    VStack(spacing: 0) {
                        // Split Queue and Main
                        HStack(spacing: 2) {
                            VStack(spacing:0) {
                                // Toolbar
                                Toolbar(library:library, content: self, appData: appData, selectedOption: $selectedPageGroup)
                                
                                ZStack {
                                    if (selectedPageGroup == 0) {
                                        if (navStack.count > 0) {
                                            navStack[navStack.count - 1].draw()
                                        }
                                    }
                                    else {
                                        ViewAllLibrary(library: library, appData: appData, content: self)
                                    }
                                    
                                    if library.musicSource == .spotify && library.spotifyAuthResponse.count == 0 {
                                        SpotifyAuthView(library: library, onCompletion: {
                                            Task {
                                                while (library.signing) {
                                                    try? await Task.sleep(for: .seconds(0.1))
                                                }
                                                
                                                library.LoadSource()
                                                while (!library.initialized) {
                                                    try? await Task.sleep(for: .seconds(0.1))
                                                }
                                                
                                                try? await Task.sleep(for: .seconds(1))
                                                
                                                library.selectingSource = false;
                                            }
                                        })
//                                        .frame(width: 1000, height: 600)
//                                        .cornerRadius(20)
                                    }
                                    
                                    HStack {
                                        Spacer()
                                        
                                        if self.appData.queueState == .hidden {
                                            ZStack(alignment: .trailing) {
                                                Rectangle().fill(Color.clear)
                                                
                                                ZStack {
                                                    MaterialBackground().colorMultiply(self.appData.colorScheme.accentColor)
                                                    
                                                    Image(systemName: "arrow.right.to.line.compact").scaleEffect(unhideQueueWidth / 50)
                                                }
                                                .frame(width: unhideQueueWidth)
                                                .animation(.linear(duration: 0.05), value: unhideQueueWidth)
                                            }
                                            .frame(width:40)
                                            .frame(maxHeight: .infinity)
                                            .onHover() { over in
                                                if (over) {
                                                    unhideQueueWidth = 40
                                                }
                                                else {
                                                    unhideQueueWidth = 0
                                                }
                                            }
                                            .onTapGesture {
                                                self.appData.queueState = .side
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Queue
                            Queue(library:library, appData: appData, content: self, musicProgressTracker: MusicProgressTracker(library: library))
                        }
                        
                        // Player
                        Player(library: library, appData: appData, content: self, windowSize: geom.size, musicProgressTracker: MusicProgressTracker(library: library))
                    }
                    .ignoresSafeArea()
                    
                    if !library.loaded {
                        LoadMask(library: library, appData: appData)
                    }
                    
                    // Overlays Apple Music / Spotify Selection
                    if library.selectingSource {
                        SelectMusicSource(library: library, appData: appData, geom: geom)
                    }
                    
                    // Show search bar for items
                    if miniSearcher != nil {
                        ContentSearcherMiniView(library, appData, self, miniSearcher!)
                    }
                    
                    // USER IS OFFLINE
                    if library.ERROR != 777 {
                        ErrorView(library: library, appData: appData, tryAgain: {
                            if library.musicSource == .spotify {
                                if library.ERROR == 401 { // Invalid Access Token
                                    
                                }
                                else { // Restart spotify select
                                    library.musicSource = .none
                                    library.selectingSource = true
                                    library.signing = false
                                    library.loaded = false
                                    library.initialized = false
                                }
                            }
                            
                            library.ERROR = 777
                        })
                    }
                }
                .onAppear() {
                    navStack.append(BrowserInstance(library, appData, self))
                }
            }
            else {
                // Presenter Queue
                PresenterQueue(library:library, appData: appData, content:self, musicProgressTracker: MusicProgressTracker(library: library))
            }
        }
        .ignoresSafeArea()
    }
    
    public func AddPage(_ page : PageInstance) {
        navStack.append(page)
    }
    public func PopPage() {
        let _ = navStack.popLast()
    }
    
//    public func songItem(item: Song?, height: CGFloat) -> some View {
//        if item == nil {
//            listItem(height: height, artwork: nil, mainTitle: "Unknown Title", subTitle: "Unknown Artist")
//        }
//        else {
//            listItem(height: height, artwork: item!.artwork, mainTitle: item!.title, subTitle: item!.artistName)
//        }
//    }
////    
    public func listItem(height: CGFloat, artwork: Artwork?, mainTitle: String, subTitle: String?, fontSize: CGFloat = 16, subFontRatio: CGFloat = 5.5/7, subFontOpac: CGFloat = 0.5, artRadius : CGFloat = -1) -> some View {
        HStack(alignment: .center, spacing: 15) {
            // Item Image
            if artwork == nil {
                library.EmptyArt(appData, height, height, artRadius: artRadius)
            }
            else {
                ArtworkImage(artwork!, width: height, height: height)
                    .cornerRadius(artRadius == -1 ? appData.appFormat.musicArtCorner : artRadius)
            }
            
            // Item Title (& subtitle)
            VStack(alignment: .leading, spacing: 3) {
                Text(mainTitle).font(.system(size: fontSize)).lineLimit(1)
                Text(subTitle == nil ? "• • •" : subTitle!).font(.system(size: fontSize * subFontRatio)).opacity(subFontOpac).lineLimit(1)
            }
        }
    }
    
//    public func gridItem(_ item : PlayableItem, size: CGFloat, action: @escaping () -> Void, radius: CGFloat = 4, centered: Bool = false) -> some View {
//        // Actual grid item
//        return Button(action: {
//            action()
//        }) {
//            VStack(alignment:.leading, spacing: 0) {
//                let dragReady : CGFloat = size / 3
//                let dragAmount : CGFloat = 0
//                
//                ZStack(alignment: dragAmount < 0 ? .top : .bottom) {
//                    // Background
//                    MaterialBackground().colorMultiply(appData.colorScheme.mainColor)
//                        .frame(width: size, height: size)
//                    
//                    // Slide visual
//                    ZStack() {
//                        if abs(dragAmount) > dragReady {
//                            Color.white.opacity(0.13)
//                        }
//                        
//                        Image(systemName: dragAmount < 0 ? "text.append" : "text.insert")
//                    }
//                    .frame(width: size, height: abs(dragAmount) > dragReady ? size : abs(dragAmount))
//                    
//                    // Art
//                    if item.getArtwork() != nil {
//                        ArtworkImage(item.getArtwork()!, width: size, height: size)
//                            .offset(x: 0, y: -(abs(dragAmount) > dragReady ? size : dragAmount))
//                    }
//                    else if item.getArtworkURL().count > 0 {
//                        AsyncImage(url: URL(string: item.getArtworkURL()), content: { phase in
//                            if let image = phase.image { image.resizable() }
//                            else { library.EmptyArt(appData, size, size) }
//                        })
//                            .frame(width: size, height: size)
//                            .cornerRadius(appData.appFormat.musicArtCorner)
//                    }
//                    else {
//                        library.EmptyArt(appData, size, size)
//                    }
//                    
//                }
//                .cornerRadius(radius)
//                
//                Text(item.getName()).font(.system(size: 12)).lineLimit(1)
//                    .padding([.top], 3)
//                Text(item.getSubtitle()).font(.system(size: 10)).opacity(0.7).lineLimit(1)
//            }
//            .frame(width: size)
//        }.buttonStyle(.plain)
//    }
}

#Preview {
    VStack {
        
    }
}
