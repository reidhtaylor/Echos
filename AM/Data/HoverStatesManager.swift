//
//  HoverStatesManager.swift
//  AM
//
//  Created by Reid Taylor on 10/30/24.
//

import SwiftUI
import MusicKit

class HoverStateManager: ObservableObject {
    @Published var hoveredItem: PlayableItem? = nil
    
    func setHoverItem(_ item : PlayableItem?) {
        self.hoveredItem = item
    }
    func isHovering(_ item : PlayableItem?) -> Bool {
        return item == hoveredItem
    }
}
