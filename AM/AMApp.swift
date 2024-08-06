//
//  FilexApp.swift
//  Filex
//
//  Created by Reid Taylor on 6/22/24.
//

import SwiftUI

@main
struct AMApp: App {
    @ObservedObject var musicLibrary : MusicLibrary = MusicLibrary()
    
    var appData = AppData()

    var body: some Scene {
        WindowGroup {
            ZStack() {
                ContentView(library: musicLibrary, appData: appData)
                
                if !musicLibrary.loaded {
                    LoadMask(library: musicLibrary, appData: appData)
                }
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
