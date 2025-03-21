//
//  Browser.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
import MusicKit

struct ViewAllLibrary: View {
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    
    @ObservedObject var library: MusicLibrary
    @State var appData: AppData
    
    var content: ContentView
    
    var body: some View {
        GeometryReader { geom in
            // Main
            ZStack {
                MaterialBackground().colorMultiply(appData.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        if (content.selectedPageGroup == 1) {
                            ForEach(0..<min(100, library.songs.count), id: \.self) { i in
                                DefaultDraws.DrawHorizontalItem(library.songs[i], height: 70, content: content, library: library, appData: appData, title: library.songs[i].getName(), subTitle: library.songs[i].getArtistName())
                            }
                        }
                        else if (content.selectedPageGroup == 2) {
                            ForEach(0..<min(100, library.albums.count), id: \.self) { i in
                                if (library.albums[i].getArtwork() != nil) {
                                    ArtworkImage(library.albums[i].getArtwork()!, width: 120, height: 120)
                                        .cornerRadius(5)
                                        .padding(.bottom, 5)
                                }
                            }
                        }
                        else if (content.selectedPageGroup == 3) {
                            ForEach(0..<min(100, library.artists.count), id: \.self) { i in
                                if (library.artists[i].getArtwork() != nil) {
                                    ArtworkImage(library.artists[i].getArtwork()!, width: 120, height: 120)
                                        .cornerRadius(5)
                                        .padding(.bottom, 5)
                                }
                            }
                        }
                    }
                    .frame(width: windowSize.width - 20, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.vertical, 10)
                }
                .frame(maxWidth: windowSize.width)
            }
            .onAppear() { windowSize = geom.size }
            .onChange(of: geom.size) { windowSize = geom.size }
        }
    }
}

#Preview {
    VStack {
        
    }
}
