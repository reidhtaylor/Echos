//
//  FilexApp.swift
//  Filex
//
//  Created by Reid Taylor on 6/22/24.
//

import SwiftUI

@main
struct AMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @ObservedObject var musicLibrary : MusicLibrary = MusicLibrary()
    @ObservedObject var appData = AppData()

    var body: some Scene {
        WindowGroup {
            ZStack() {
                ContentView(library: musicLibrary, appData: appData)
            }
            .frame(minWidth: appData.queueState == .isolated ? appData.appFormat.queueRestriction.width : 1000, maxWidth: appData.queueState == .isolated ? appData.appFormat.queueRestriction.height : .infinity, minHeight: (appData.queueState == .isolated ? NSApplication.shared.windows.first?.frame.width : 400)! + 65)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(before: .toolbar) {
                Divider()
                
                Picker(selection: $appData.queueState, label: Text("Queue")) {
                    Text("Visible").tag(AppData.QueueState.side)
                        .keyboardShortcut("V")
                    Text("Hide").tag(AppData.QueueState.hidden)
                        .keyboardShortcut("U")
                    Text("Presenter").tag(AppData.QueueState.presenter)
                        .keyboardShortcut("P")
                    Text("Isolated").tag(AppData.QueueState.isolated)
                        .keyboardShortcut("I")
                }
                
                Button("Search") {
//                    content.miniSearcher = ContentSearcher(musicLibrary)
//                    content.miniSearcher!.defaultSearchBar = true
//                    content.miniSearcher!.onItemSelected = { item in
//                        musicLibrary.pinnedItems.append(item)
//                        musicLibrary.setCatalogue("Pinned", musicLibrary.pinnedItems)
//                        
//                        musicLibrary.savePinnedValues()
//                        musicLibrary.onLibraryUpdate.trigger()
//                    }
                }
                    .keyboardShortcut("S")
                
                Divider()
             }
       }
        .onChange(of: appData.queueState) { oldValue, newValue in
            
            if let window = NSApplication.shared.windows.first, let screen = NSScreen.main {
                if oldValue != .isolated && newValue == .isolated {
                    let screenFrame = screen.visibleFrame
                    let windowSize = NSSize(width: appData.appFormat.queueWidth, height: screenFrame.maxY * 0.65)
                    
                    window.setContentSize(windowSize) // Set the window size
                    
                    // Set the window position
                    window.setFrameOrigin(NSPoint(x: screenFrame.maxX - windowSize.width, y: screenFrame.maxY - windowSize.height))
                }
                else if oldValue == .isolated && (newValue == .side || newValue == .hidden) {
                    let screenFrame = screen.visibleFrame
                    let windowSize = NSSize(width: screenFrame.maxX * 0.85, height: screenFrame.maxY * 0.85)
                    
                    window.setContentSize(windowSize)
                    window.center()
                }
                
                window.level = newValue == .isolated ? .floating : .normal
            }
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first, let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = NSSize(width: screenFrame.maxX * 0.85, height: screenFrame.maxY * 0.85)
            
            window.setContentSize(windowSize)
            window.center()
        }
    }
}
