//
//  FilexApp.swift
//  Filex
//
//  Created by Reid Taylor on 6/22/24.
//

import SwiftUI

@main
struct AMApp: App {
    let musicLibrary : MusicLibrary = MusicLibrary()
    let appFormat : FormatData = FormatData(colorScheme: ColorData(mainColor: Color(hue: 0, saturation: 0, brightness: 0.5), accentColor: Color(hue: 0, saturation: 0, brightness: 0.55), deepColor: Color(hue: 0, saturation: 0, brightness: 0.6), accent: Color(hue: 0, saturation: 0, brightness: 1)), queueWidth: 250, playerHeight: 65, musicArtCorner: 4)
    
    var body: some Scene {
        WindowGroup {
            ContentView(library: musicLibrary, appFormat: appFormat)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
