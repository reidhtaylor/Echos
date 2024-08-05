//
//  ContentView.swift
//  AM
//
//  Created by Reid Taylor on 12/16/23.
//

import SwiftUI
import AppKit
//import iTunesLibrary
import MusicKit

struct FormatData {
    let colorScheme: ColorData
    
    var queueWidth: CGFloat
    let queueRestriction: CGSize = CGSize(width: 200, height: 550)
    
    let playerHeight: CGFloat
    
    let musicArtCorner: CGFloat
    
    let animPlaybackInterval = 0.4
    
    public init(colorScheme: ColorData, queueWidth: CGFloat, playerHeight: CGFloat, musicArtCorner: CGFloat) {
        self.colorScheme = colorScheme
        self.queueWidth = queueWidth
        self.playerHeight = playerHeight
        self.musicArtCorner = musicArtCorner
    }
}
struct ColorData {
    let mainColor: Color
    let accentColor: Color
    let deepColor: Color
    
    let accent: Color
}

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
    @State var appFormat: FormatData
    
    enum Page : Int {
        case browser
        case songGroupPreview
    }
    @State var page: Page = .browser
    
    var body: some View {
        GeometryReader { geom in
            // Split Player and Main/Queue
            VStack(spacing: 0) {
                // Split Queue and Main
                HStack(spacing: 2) {
                    VStack(spacing:0) {
                        // Toolbar
                        Toolbar(library:library, appFormat: appFormat)
                        
                        switch page {
                            case .browser:
                                Browser(library: library, appFormat: appFormat, content: self)
                            case .songGroupPreview:
                                PreviewAlbum(library: library, appFormat: appFormat, content: self)
                        }
                    }
                    
                    // Queue
                    Queue(library:library, appFormat: appFormat, content:self)
                }
                
                // Player
                Player(library: library, appFormat: appFormat, content: self, windowSize: geom.size)
            }
            .ignoresSafeArea()
        }
    }
    
    public func songItem(item: Song?, height: CGFloat) -> some View {
        if item == nil {
            listItem(height: height, artwork: nil, mainTitle: "Unknown Title", subTitle: "Unknown Artist")
        }
        else {
            listItem(height: height, artwork: item!.artwork, mainTitle: item!.title, subTitle: item!.artistName)
        }
    }
    
    public func listItem(height: CGFloat, artwork: Artwork?, mainTitle: String, subTitle: String?, fontSize: CGFloat = 16, subFontRatio: CGFloat = 5.5/7, subFontOpac: CGFloat = 0.5) -> some View {
        HStack(alignment: .center, spacing: 15) {
            // Item Image
            if artwork == nil {
                Image(nsImage: NSImage(imageLiteralResourceName: "UnknownAlbum"))
                    .resizable()
                    .frame(width: height, height:height)
                    .cornerRadius(appFormat.musicArtCorner)
            }
            else {
                ArtworkImage(artwork!, width: height, height: height)
                    .cornerRadius(appFormat.musicArtCorner)
            }
            
            // Item Title (& subtitle)
            VStack(alignment: .leading, spacing: 3) {
                Text(mainTitle).font(.system(size: fontSize)).lineLimit(1)
                Text(subTitle == nil ? "• • •" : subTitle!).font(.system(size: fontSize * subFontRatio)).opacity(subFontOpac).lineLimit(1)
            }
        }
    }
    
    public func gridItem(_ art: Artwork?, title: String, subTitle: String, size: CGFloat, action: @escaping () -> Void, radius: CGFloat = 4, centered: Bool = false) -> some View {
        Button(action: action) {
            VStack(alignment:.leading, spacing: 0) {                
                if art == nil {
                    Image("UnknownAlbum")
                        .resizable()
                        .frame(width: size, height:size)
                        .cornerRadius(radius)
                }
                else {
                    ArtworkImage(art!, width: size, height: size)
                        .cornerRadius(radius)
                }

                Text(title).font(.system(size: 12)).lineLimit(1)
                    .padding([.top], 3)
                Text(subTitle).font(.system(size: 10)).opacity(0.7).lineLimit(1)
            }
            .frame(width: size)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        
    }
}
