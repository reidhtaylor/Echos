//
//  Toolbar.swift
//  AM
//
//  Created by Reid Taylor on 12/25/23.
//

import SwiftUI
import MusicKit

struct ContentSearcherMiniView: View {
    
    var library: MusicLibrary
    var appData: AppData
    var contentView: ContentView
    @ObservedObject var searcher: ContentSearcher
    
    @State var searchString: String
    @FocusState var searchFocused: Bool
    
    @State private var isAtBottom = false

    public init(_ library : MusicLibrary, _ appData: AppData, _ contentView : ContentView, _ searcher: ContentSearcher) {
        self.library = library
        self.appData = appData
        self.contentView = contentView
        self.searcher = searcher
        self.searchString = ""
    }
    
    var body: some View {
        ZStack { // Back Tap
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    contentView.miniSearcher = nil
                }
            
            VStack (spacing: 0) { // Shift down
                HStack (spacing: 0) { // Shift right
                    // Panel
                    ZStack(alignment: .leading) {
                        MaterialBackground().colorMultiply(appData.colorScheme.accentColor).ignoresSafeArea()
                            .cornerRadius(10)
                        
                        VStack(spacing: 0) {
                            if self.searcher.defaultSearchBar {
                                ZStack(alignment: .leading) {
                                    MaterialBackground().colorMultiply(appData.colorScheme.accent.opacity(0.07)).ignoresSafeArea()
                                        .cornerRadius(5)
                                    
                                    Image(systemName: "magnifyingglass")
                                        .padding(.leading, 10)
                                    
                                    TextField("Search", text: $searchString)
                                        .frame(maxWidth: .infinity)
                                        .padding([.leading], 35)
                                        .textFieldStyle(.plain)
                                        .focused($searchFocused)
                                        .onChange(of: searchString) {
                                            self.searcher.refreshSearchResults(searchString)
                                        }
                                        .onChange(of: searchFocused) {
                                            if !searchFocused {
                                                searchFocused = true // Refocus if it loses focus
                                            }
                                        }
                                        .font(.callout)
                                }
                                .frame(width: 440, height: 40)
                            }
                            
                            VStack {
                                ScrollView(.vertical) {
                                    LazyVStack(spacing: 2) {
                                        ForEach(searcher.results) { res in
                                            itemListing(item: res)
                                                .frame(width: 450, height: 60)
                                                .contextMenu {
                                                    DefaultDraws.ContextMenuPlayable(res, library, contentView)
                                                }
                                        }
                                        
                                        GeometryReader { geometry in
                                            Color.clear
                                                .onAppear { isAtBottom = true }
                                                .onDisappear { isAtBottom = false }
                                        }
                                        .frame(height: 1) // Small frame for minimal impact on layout
                                    }
                                }
                                .scrollIndicators(.hidden) // WHYYYYYYYYYY
                                .frame(maxHeight: .infinity)
                                .onChange(of: isAtBottom) {
                                    if isAtBottom {
                                        self.searcher.maxRESULTS += 10;
                                        self.searcher.refreshSearchResults(searchString)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                        .padding(5)
                        
                        if searcher.results.count == 0 {
                            ZStack(alignment: .center) {
                                Text("No results found").font(.callout).opacity(0.5)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 40)
                        }
                    }
                    .frame(width: 450, height: 300 - (self.searcher.defaultSearchBar ? 40 : 0))
                    .onAppear() {
                        self.searchFocused = true
                    }
                    
                    if !self.searcher.defaultSearchBar { Spacer() }
                }
                if !self.searcher.defaultSearchBar { Spacer() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, self.searcher.defaultSearchBar ? 0 : 40)
            .padding(.leading, self.searcher.defaultSearchBar ? 0 : 125)
        }
    }
    
    private func itemListing(item: PlayableItem) -> some View {
        Button(action: {
            contentView.miniSearcher!.onItemSelected?(item)
            contentView.miniSearcher = nil
        }) {
            ZStack(alignment: .leading) {
                MaterialBackground().colorMultiply(appData.colorScheme.accentColor)
                
                HStack(spacing: 0) {
                    if (item.getArtwork() != nil) {
                        ArtworkImage(item.getArtwork()!, width: 45, height: 45)
                            .cornerRadius(appData.appFormat.musicArtCorner)
                            .padding([.trailing], 15)
                    }
                    else {
                        library.EmptyArt(appData, 45, 45)
                            .cornerRadius(appData.appFormat.musicArtCorner)
                            .padding([.trailing], 15)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(item.getName()).font(.callout).lineLimit(1)
                        Text(item.itemType.description).font(.caption2).lineLimit(1).opacity(0.5)
                    }
                    Spacer()
                    
//                    ZStack(alignment: .center) {
//                        MaterialBackground().colorMultiply(appData.colorScheme.accent).cornerRadius(100)
//                        Text(item.itemType.description).font(.caption2).lineLimit(1)
//                    }
//                    .frame(width: 60, height: 20)
//                    .opacity(0.25)
                    
                    if item.itemType != .song {
                        Image(systemName: "chevron.right")
                            .frame(width: 70)
                    }
//                    else {
//                        Image(systemName: "play.fill")
//                            .resizable()
//                            .scaleEffect(0.4)
//                            .frame(width: 40)
//                    }
                }
                .padding([.leading], 15)
            }
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
    }
}

struct ScrollHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

#Preview {
    VStack {
        
    }
}
