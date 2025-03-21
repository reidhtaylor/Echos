//
//  Browser.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
import MusicKit

struct Browser: View {
    
    var inst : BrowserInstance
    
    @State var windowSize: CGSize = CGSize(width: 2000, height: 2000)
    @State var dragAmount : CGFloat = 0
    
    @StateObject var hoverStatesManager: HoverStateManager = HoverStateManager()
    
    var body: some View {
        GeometryReader { geom in
            // Main
            ZStack {
                MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // CATALOGUES
                        ForEach(0..<inst.library.catalogues.count, id: \.self) { i in
                            if (inst.library.catalogues[i].title == "Pinned") { // Pinned
                                DefaultDraws.DrawLineCatalogue(inst.library.catalogues[i], width: geom.size.width - 60, height: 280, content: inst.content, library: inst.library, appData: inst.appData, titleSize: 2, hoverStates: hoverStatesManager, extraContent: AnyView(HStack {
                                    Button(action: {
                                        inst.content.miniSearcher = ContentSearcher(inst.library)
                                        inst.content.miniSearcher!.defaultSearchBar = true
                                        inst.content.miniSearcher!.onItemSelected = { item in
                                            inst.library.pinnedItems.append(item)
                                            inst.library.setCatalogue("Pinned", inst.library.pinnedItems)
                                            
                                            inst.library.savePinnedValues()
                                            inst.library.onLibraryUpdate.trigger()
                                        }
                                    }) {
                                        VStack {
                                            ZStack(alignment: .center) {
                                                MaterialBackground().colorMultiply(inst.appData.colorScheme.accentColor)
                                                    .cornerRadius(10)
                                                
                                                Image(systemName: "plus").resizable().scaledToFit().scaleEffect(0.2)
                                            }
                                            .frame(width: 175, height: 175)
                                            .padding(.top, 2.5)
                                            
                                            Spacer()
                                        }
                                    }.buttonStyle(.plain)
                                    .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                                }), extraOptions: [
                                    ("Unpin", { item in
                                        inst.library.pinnedItems.remove(at: inst.library.pinnedItems.firstIndex(of: item)!)
                                        inst.library.setCatalogue("Pinned", inst.library.pinnedItems)
                                        
                                        inst.library.savePinnedValues()
                                        inst.library.onLibraryUpdate.trigger()
                                    }, .red)
                                ], drawPreload: false)
                                    .padding(.bottom, 20)
                            }
                            else if (inst.library.catalogues[i].title == "Playlists")  { // Playlists
                                DefaultDraws.DrawLineCatalogue(inst.library.catalogues[i], width: geom.size.width - 60, height: 280, content: inst.content, library: inst.library, appData: inst.appData, textAlignment: .center, horizontalSpacing: 25, titleSize: 2, hoverStates: hoverStatesManager)
                                    .padding(.bottom, 30)
                            }
                            else if (inst.library.catalogues[i].title == "Shuffle Sample") { // Shuffle
                                DefaultDraws.DrawLineCatalogue(inst.library.catalogues[i], width: geom.size.width - 60, height: 280, content: inst.content, library: inst.library, appData: inst.appData, horizontalSpacing: 25, titleSize: 2, hoverStates: hoverStatesManager, rightmostTitle: AnyView(HStack {
                                    
                                    Button(action: { () in
                                        inst.library.setCatalogue("Shuffle Sample", inst.library.randNItems(10))
                                        inst.library.onLibraryUpdate.trigger()
                                    }) {
                                        Image(systemName: "shuffle").scaleEffect(1)
                                    }
                                    .frame(width: 60, height: 60)
                                    .buttonStyle(.plain)
                                }))
                                    .padding(.bottom, 30)
                            }
                            else if (inst.library.catalogues[i].title == "Popular Songs") { // Shuffle
//                                DefaultDraws.DrawLineCatalogue(inst.library.catalogues[i], width: geom.size.width - 60, height: 280, content: inst.content, library: inst.library, appData: inst.appData, horizontalSpacing: 25, titleSize: 2, hoverStates: hoverStatesManager)
                                DefaultDraws.DrawLineCatalogueSongs(inst.library.catalogues[i], width: geom.size.width - 60, height: 230, content: inst.content, library: inst.library, appData: inst.appData, titleSize: 2, hoverStates: hoverStatesManager)
                                    .padding(.bottom, 20)
                            }
                            else { // Other
                                DefaultDraws.DrawLineCatalogue(inst.library.catalogues[i], width: geom.size.width - 60, height: 280, content: inst.content, library: inst.library, appData: inst.appData, horizontalSpacing: 25, titleSize: 2, hoverStates: hoverStatesManager)
                                    .padding(.bottom, 30)
                            }
                        }
                        // CATALOGUES
                    }
                    .frame(width: windowSize.width - 75, alignment: .leading)
                    .padding(.leading, 25)
                    .padding(.vertical, 35)
                }
                .frame(maxWidth: windowSize.width)
//                List() {
//                    ForEach(0..<inst.library.catalogues.count, id: \.self) { i in
//                        Color.red
//                            .frame(width: 100, height: 100)
//                            .padding(.bottom, 300)
//                    }
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
//                }
//                .listStyle(PlainListStyle())
//                .scrollContentBackground(.hidden)
//                .scrollIndicators(.hidden)
            }
            .onAppear() {
                windowSize = geom.size
                inst.library.onLibraryUpdate.subscribe("BROWSER") {
                    hoverStatesManager.setHoverItem(nil)
                }
            }
            .onChange(of: geom.size) { windowSize = geom.size }
        }
    }
}

#Preview {
    VStack {
        
    }
}
