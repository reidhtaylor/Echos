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

enum PlayableItemType {
    case unknown
    case song
    case album
    case playlist
}

class PlayableItem {
    let itemType : PlayableItemType
    let itemAM : MusicItem?
    
    public init(_item : MusicItem, _itemType : PlayableItemType) {
        itemType = _itemType
        itemAM = _item
    }
}
