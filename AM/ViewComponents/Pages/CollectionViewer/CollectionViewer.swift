//
//  Browser.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
import MusicKit

struct CollectionViewer: View {
    
    var inst : CollectionViewerInstance
    
    @StateObject var hoverStatesManager: HoverStateManager = HoverStateManager()
    
    var body: some View {
        GeometryReader { geom in
            // Main
            ZStack {
                MaterialBackground().colorMultiply(inst.appData.colorScheme.mainColor).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    DefaultDraws.DrawGridCatalogue(inst.catalogue, itemSize: 100, content: inst.content, library: inst.library, appData: inst.appData, hoverStates: hoverStatesManager)
                }
            }
            .onAppear() {
                inst.library.onLibraryUpdate.subscribe("COLLECTION_VIEWER") {
                    hoverStatesManager.setHoverItem(nil)
                }
            }
        }
    }
}

#Preview {
    VStack {
        
    }
}
