//
//  PlayableItem.swift
//  AM
//
//  Created by Reid Taylor on 8/6/24.
//

import Foundation
import AppKit
import SwiftUI
import MusicKit

struct LineCatalogue : Hashable {
    var title : String
    var items: [PlayableItem]
}

class DefaultDraws {
    // Draw Horizontal Line of Items
    static func DrawLineCatalogue(_ catalogue: LineCatalogue, width: CGFloat, height: CGFloat, content: ContentView, library: MusicLibrary, appData: AppData, subTitle: @escaping (PlayableItem) -> String = { $0.getSubtitle() }, artRadius: CGFloat = 5, textAlignment: HorizontalAlignment = .leading, horizontalSpacing: CGFloat = 25, titleSize: Int = 1, hoverStates: HoverStateManager, extraContent: AnyView = AnyView(ZStack {}), rightmostTitle: AnyView = AnyView(ZStack {}), extraOptions : [(String, (PlayableItem) -> Void, Color)] = [], drawPreload : Bool = true) -> some View {
        // General view
        VStack(alignment: .leading, spacing: 0) {
            HStack() {
                // Catalogue Title
                Text(catalogue.title).font(titleSize == 1 ? .title2 : titleSize == 2 ? .largeTitle : .title2).bold()
                    .lineLimit(1)
                
//                Button(action: {
//                    
//                }) {
//                    ZStack(alignment: .center) {
//                        MaterialBackground().colorMultiply(appData.colorScheme.mainColor).colorInvert().opacity(0.05)
//                            .cornerRadius(4)
//                        
//                        Text("See all").font(.system(size: 10)).opacity(0.5)
//                    }
//                    .frame(height: 18)
//                }
//                .buttonStyle(.plain)
//                .frame(width: 65, height: titleSize == 1 ? 40 : titleSize == 2 ? 70 : 40)
//                .padding(.leading, 10)
////                .opacity(clearOn)
////                .disabled(clearOn == 0)
////                .animation(.linear(duration: 0.07), value: clearOn)
                
                Spacer()
                
                rightmostTitle
            }
            .frame(height: titleSize == 1 ? 40 : titleSize == 2 ? 70 : 40)
            .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
            .padding(.trailing, 10)
            
            // Horizontal Scroll view to hold items
            let itemHeight = height - (titleSize == 1 ? 40 : titleSize == 2 ? 70 : 40);
            ScrollView(.horizontal, showsIndicators:false) {
                // Space Horizontal Items
                HStack(alignment: .center, spacing: horizontalSpacing) {
                    // Loop through each item in catalogue
                    ForEach(0..<(catalogue.items.count == 0 ? (drawPreload ? 10 : 0) : catalogue.items.count), id: \.self) { i in
                        let item = (i >= catalogue.items.count) ? nil : catalogue.items[i]
                        DrawItem(item, height: itemHeight, content: content, library: library, appData: appData, title: item == nil ? "" : item!.getName(), subTitle: item == nil ? "" : subTitle(item!), artRadius: artRadius, textAlignment: textAlignment, hovering: hoverStates.isHovering(item), extraOptions: extraOptions)
                            .onHover() { over in
                                if over && item != nil {
                                    hoverStates.setHoverItem(item!)
                                }
                                else if item != nil && hoverStates.isHovering(item!) {
                                    hoverStates.setHoverItem(nil)
                                }
                            }
                    }
                    extraContent
                }
                .padding(.trailing, 50)
            }.frame(height: itemHeight)
        }
        .frame(width: width, height: height)
        .clipped()
    }
    
    static func DrawGridCatalogue(_ catalogue: LineCatalogue, itemSize: CGFloat, content: ContentView, library: MusicLibrary, appData: AppData, spacing: CGFloat = 25, hoverStates: HoverStateManager) -> some View {
        // General view
        VStack(alignment: .leading, spacing: 0) {
            HStack() {
                // Catalogue Title
                Text(catalogue.title).font(.largeTitle).bold()
                    .lineLimit(1)
            }
            .frame(height: 70)
            .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
            .padding(.trailing, 10)
            
            // Horizontal Scroll view to hold items
            ScrollView(.vertical, showsIndicators:false) {
                // Space Horizontal Items
                VStack(alignment: .center, spacing: spacing) {
                    // Loop through each item in catalogue
                    ForEach(0..<catalogue.items.count, id: \.self) { i in
                        let item = catalogue.items[i]
                        DrawItem(item, height: itemSize, content: content, library: library, appData: appData, title: item.getName(), subTitle: item.getSubtitle(), artRadius: appData.appFormat.musicArtCorner, textAlignment: .leading, hovering: hoverStates.isHovering(item))
                            .onHover() { over in
                                if over {
                                    hoverStates.setHoverItem(item)
                                }
                                else if hoverStates.isHovering(item) {
                                    hoverStates.setHoverItem(nil)
                                }
                            }
                    }
                }
                .padding(.trailing, 50)
            }.frame(height: itemSize)
        }
    }
    
    // Draw Clickable Item
    static func DrawItem(_ item: PlayableItem?, height: CGFloat, content: ContentView, library: MusicLibrary, appData: AppData, title: String, subTitle: String, artRadius: CGFloat = 5, textAlignment: HorizontalAlignment = .leading, hovering : Bool = false, extraOptions : [(String, (PlayableItem) -> Void, Color)] = []) -> some View {
        Button(action: {
            if (item != nil) {
                library.setPreviewingItem(item!, content)
            }
        }) {
            let isArtist = item?.itemType == .artist
            let actlHeight = (isArtist ? height - 20 : height) - 35
            
            // Stack art, title, sub title
            VStack(alignment: isArtist ? .center : textAlignment, spacing: 0) {
                // Show valid info if artwork isn't null
                if item != nil {
                    // Item art
                    ZStack(alignment: .bottomLeading) {
                        DrawArtwork(item!, height: actlHeight, cornerRadius: artRadius, appData: appData)
                        
                        if hovering {
                            ZStack(alignment: item!.itemType == .song ? .center : .bottomLeading) {
                                Color.black.opacity(0.15)
                                    .cornerRadius(isArtist ? 200 : artRadius)
                                
                                if (item!.itemType == .album || item!.itemType == .playlist) {
                                    Button(action: { () in
                                        Task { await item!.play(library) }
                                    }) {
                                        ZStack {
                                            MaterialBackground().colorMultiply(appData.colorScheme.mainColor)
                                                .cornerRadius(200)
                                            Image(systemName: "play.fill").scaleEffect(0.7)
                                        }
                                    }
                                    .frame(width: 25, height: 25)
                                    .buttonStyle(.plain)
                                    .offset(x: 10, y: -10)
                                    
                                    Spacer()
                                }
                                else if (item!.itemType == .song) {
                                    Button(action: { () in
                                        Task { await item!.play(library) }
                                    }) {
                                        ZStack {
                                            MaterialBackground().colorMultiply(appData.colorScheme.mainColor)
//                                            appData.colorScheme.accent.colorMultiply(Color(hue: 0, saturation: 0, brightness: 0.7))
                                                .cornerRadius(200).opacity(0.6)
                                            Image(systemName: "play.fill").scaleEffect(1.5)
                                        }
                                    }
                                    .frame(width: 60, height: 60)
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(width: actlHeight, height: actlHeight)
                        }
                    }
                    
                    // Line text elements
                    VStack (alignment: textAlignment, spacing: 0) {
                        // Only show text items that exist
                        if title != "" {
                            Text(title).font(.subheadline.bold()).lineLimit(1)
                                .frame(height: 20)
                        }
                        
                        if subTitle != "" {
                            Text(subTitle).font(.subheadline).lineLimit(1).opacity(0.5)
                                .frame(height: 10)
                        }
                    }
                    .padding(.top, 5)
                    .frame(height: 30)
                }
                else {
                    // Show fake example
                    VStack {
                        ZStack {
                            MaterialBackground().colorMultiply(appData.colorScheme.deepColor)
                                .frame(width: height - 20, height: height - 20)
                                .cornerRadius(isArtist ? 200 : artRadius)
//                            Image(systemName: "music.note").resizable().scaledToFit().scaleEffect(0.3).opacity(0.5)
                        }
                        
                        Text("• • •")
                            .font(.subheadline)
                            .frame(height: 20)
                    }
                }
            }.frame(width: height - 35, height: height)
            .contextMenu {
                if (item != nil) {
                    ContextMenuPlayable(item!, library, content, extraOptions: extraOptions)
                }
            }
        }.buttonStyle(.plain)
        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
    }
    
    // Draw Artwork
    static func DrawArtwork(_ item : PlayableItem, height : CGFloat, cornerRadius : CGFloat, appData : AppData) -> some View {
        ZStack {
            if (item.getArtwork() != nil) {
                ArtworkImage(item.getArtwork()!, width: height, height: height)
                    .cornerRadius(item.itemType == .artist ? 200 : cornerRadius)
                
//                AsyncImage(url: item.getArtwork()!.url(width: Int(height), height: Int(height))) { image in
//                    if image.image != nil {
//                        image.image!
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: height, height: height)
//                            .cornerRadius(item.itemType == .artist ? 200 : cornerRadius)
//                    }
//                    else {
//                        ZStack {
//                            LinearGradient(gradient: Gradient(colors: [appData.colorScheme.deepColor.opacity(0.2), appData.colorScheme.accentColor.opacity(0.06)]), startPoint: .top, endPoint: .bottom)
//                            
//                            let names = item.getName().split(separator: " ").map(String.init)
//                            if names.count > 1 {
//                                Text(String(names.first!.first!) + String(names.last!.first!)).font(.system(size: 60).bold()).lineLimit(1)
//                            }
//                            else {
//                                Text(String(names.first!.first!)).font(.system(size: 60).bold()).lineLimit(1)
//                            }
//                        }
//                        .frame(width: height, height: height)
//                        .cornerRadius(item.itemType == .artist ? 200 : cornerRadius)
//                    }
//                }
            }
            else if (item.getArtworkURL().count > 0) {
                AsyncImage(url: URL(string: item.getArtworkURL())) { image in
                    if image.image != nil {
                        image.image!
                            .resizable()
                            .scaledToFill()
                            .frame(width: height, height: height)
                            .cornerRadius(item.itemType == .artist ? 200 : cornerRadius)
                    }
                }
            }
            else {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [appData.colorScheme.deepColor.opacity(0.2), appData.colorScheme.accentColor.opacity(0.06)]), startPoint: .top, endPoint: .bottom)
                    
                    let names = item.getName().split(separator: " ").map(String.init)
                    if names.count > 1 {
                        Text(String(names.first!.first!) + String(names.last!.first!)).font(.system(size: 60).bold()).lineLimit(1)
                    }
                    else {
                        Text(String(names.first!.first!)).font(.system(size: 60).bold()).lineLimit(1)
                    }
                }
                .frame(width: height, height: height)
                .cornerRadius(item.itemType == .artist ? 200 : cornerRadius)
            }
        }
    }
    
    // Draw Grid of Small Items
    static func DrawLineCatalogueSongs(_ catalogue: LineCatalogue, width: CGFloat, height: CGFloat, content: ContentView, library: MusicLibrary, appData: AppData, subTitle: @escaping (PlayableItem) -> String = { $0.getSubtitle() }, artRadius: CGFloat = 5, textAlignment: HorizontalAlignment = .leading, horizontalSpacing: CGFloat = 10, titleSize: Int = 1, hoverStates: HoverStateManager) -> some View {
        VStack(alignment: .leading, spacing: 0) {
//            if (catalogue.title[catalogue.title.index(catalogue.title.endIndex, offsetBy: -1)] != "*") {
                Text(catalogue.title).font(titleSize == 1 ? .title2 : titleSize == 2 ? .largeTitle : .title2).bold()
                    .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                    .lineLimit(1)
                    .frame(height: titleSize == 1 ? 40 : titleSize == 2 ? 70 : 40)
//            }
            
            let divider : CGFloat = floor(height / 70)
            let itemHeight = (height - 40) / divider
            let cols = catalogue.items.count == 0 ? 4 : Int(ceil(CGFloat(catalogue.items.count) / divider))
            let rows = Int(divider)
            ScrollView(.horizontal, showsIndicators:false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(0..<cols, id: \.self) { j in
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<rows, id: \.self) { index in
                                let i = j * rows + index
                                
                                if (i < catalogue.items.count || catalogue.items.count == 0) {
                                    DrawHorizontalItem((i < catalogue.items.count ? catalogue.items[i] : nil), height: itemHeight, content: content, library: library, appData: appData, title: (i < catalogue.items.count ? catalogue.items[i].getName() : ""), subTitle: (i < catalogue.items.count ? subTitle(catalogue.items[i]) : ""), artRadius: artRadius, textAlignment: textAlignment, hovering: (i < catalogue.items.count ? hoverStates.isHovering(catalogue.items[i]) : false))
                                        .onHover() { over in
                                            if i < catalogue.items.count {
                                                if over {
                                                    hoverStates.setHoverItem(catalogue.items[i])
                                                }
                                                else if hoverStates.isHovering(catalogue.items[i]) {
                                                    
                                                    hoverStates.setHoverItem(nil)
                                                }
                                            }
                                        }
                                }
                            }
                            Spacer()
                        }
                        .frame(width: itemHeight * 4)
                    }
                }
            }
        }
        .frame(width: width)
        .clipped()
    }
    // Draw Clickable Item
    static func DrawHorizontalItem(_ item: PlayableItem?, height: CGFloat, content: ContentView, library: MusicLibrary, appData: AppData, title: String, subTitle: String, artRadius: CGFloat = 5, textAlignment: HorizontalAlignment = .leading, hovering : Bool = false) -> some View {
        Button(action: {
            if item != nil {
                library.setPreviewingItem(item!, content)
            }
        }) {
            ZStack {
                Rectangle().colorMultiply(.clear)
                
                if item != nil {
                    HStack(spacing: 10) {
                        DrawArtwork(item!, height: height - 10, cornerRadius: artRadius, appData: appData)
                            .padding(.leading, 5)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item!.getName()).font(.subheadline.bold()).lineLimit(1)
                                .frame(height: 20)
                                .padding(.top, 5)
                            
                            Text(item!.getAlbumTitle() + " • " + item!.getYear()).font(.subheadline).lineLimit(1).opacity(0.5)
                                .frame(height: 15)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.trailing, 10)
                }
                else {
                    HStack(spacing: 10) {
                        MaterialBackground().colorMultiply(appData.colorScheme.deepColor)
                            .frame(width: height - 10, height: height - 10)
                            .cornerRadius(artRadius)
                            .padding(.leading, 5)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("• • •").font(.subheadline.bold()).lineLimit(1)
                                .frame(height: 20)
                                .padding(.top, 5)
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.trailing, 10)
                }
            }
        }
        .buttonStyle(.plain)
        .background(hovering ? .white.opacity(0.04) : .clear)
        .cornerRadius(5)
        .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
        .frame(height: height)
        .contextMenu {
            if item != nil {
                ContextMenuPlayable(item!, library, content)
            }
        }
    }
    
    
    // Context menu for playable item
    static func ContextMenuPlayable(_ item: PlayableItem, _ library: MusicLibrary, _ content: ContentView, extraOptions : [(String, (PlayableItem) -> Void, Color)] = []) -> some View {
        ZStack {
            if (item.itemType != .artist) {
                Button(action: {
                    Task { await item.queueNext(library) }
                }) {
                    Text("Play Next")
                    Image(systemName: "text.line.first.and.arrowtriangle.forward")
                }
                
                Button(action: {
                    Task { await item.queueAfter(library) }
                }) {
                    Text("Play After")
                    Image(systemName: "text.line.last.and.arrowtriangle.forward")
                }
                
                if (item.itemType == .album || item.itemType == .playlist) {
                    Menu("Shuffle", systemImage: "shuffle") {
                        Button(action: {
                            Task { await item.shuffleNext(library) }
                        }) {
                            Text("Next")
                            Image(systemName: "text.insert")
                        }
                        
                        Button(action: {
                            Task { await item.shuffle(library) }
                        }) {
                            Text("Mix")
                            Image(systemName: "text.redaction")
                        }
                        
                        Button(action: {
                            Task { await item.shuffleAfter(library) }
                        }) {
                            Text("After")
                            Image(systemName: "text.append")
                        }
                    }
                }
                
                if (item.itemType == .song) {
                    Button(action: {
                        // GO TO ALBUM
                        Task {
                            let detailedSong = try await item.itemSongAM!.with([.albums])
                            if let album = detailedSong.albums?.first {
                                library.setPreviewingItem(PlayableItem(_item: album, _itemType: .album), content)
                            }
                        }
                    }) {
                        Text("View Album")
                        Image(systemName: "square.stack")
                    }
                    
                    Button(action: {
                        // ADD SONG TO PLAYLIST
                        Task {
//                            try await MusicKit.MusicLibrary.shared.add(item.itemSongAM!, to: library.playlists[0].itemPlaylistAM!)
                        }
                    }) {
                        Text("Add to Playlist")
                        Image(systemName: "plus")
                    }
                }
                
                if (item.itemType == .song || item.itemType == .album) {
                    Button(action: {
                        // GO TO ARTIST
                        Task {
                            if (item.itemType == .song) {
                                let detailedSong = try await item.itemSongAM!.with([.artists])
                                if let artist = detailedSong.artists?.first {
                                    for a in library.artists {
                                        if a.getName() == artist.name {
                                            library.setPreviewingItem(a, content)
                                            break
                                        }
                                    }
                                }
                            }
                            else if (item.itemType == .album) {
                                let detailedAlbum = try await item.itemAlbumAM!.with([.artists])
                                if let artist = detailedAlbum.artists?.first {
                                    for a in library.artists {
                                        if a.getName() == artist.name {
                                            library.setPreviewingItem(a, content)
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        Text("View Artist")
                        Image(systemName: "arrow.forward.square")
                    }
                }
            }
            
            ForEach(0..<extraOptions.count) { i in
                Button(action: {
                    extraOptions[i].1(item)
                }) {
                    Text(extraOptions[i].0).foregroundColor(extraOptions[i].2)
                }
            }
        }
    }
}
