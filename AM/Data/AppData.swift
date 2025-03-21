//
//  AppData.swift
//  AM
//
//  Created by Reid Taylor on 8/6/24.
//

import Foundation
import AppKit
import SwiftUI
import MusicKit

class AppData : ObservableObject {
    var colorScheme : ColorData
    var appFormat : FormatData
    
    enum QueueState: Int {
        case side
        case hidden
        case presenter
        case isolated
    }
    @Published var queueState: QueueState = .side
    
    public init() {
        colorScheme = ColorData()
        appFormat = FormatData()
    }
}

class FormatData : ObservableObject {
    @Published var queueWidth: CGFloat
    @Published var queueRestriction: CGSize
    
    let playerHeight: CGFloat
    let musicArtCorner: CGFloat
    
    let animPlaybackInterval : Double
    
    public init(queueWidth: CGFloat = 250, queueRestriction: CGSize = CGSize(width: 175, height: 350), playerHeight: CGFloat = 65, musicArtCorner: CGFloat = 4, animPlaybackInterval: Double = 0.4) {
        self.queueWidth = queueWidth
        self.queueRestriction = queueRestriction
        self.playerHeight = playerHeight
        self.musicArtCorner = musicArtCorner
        self.animPlaybackInterval = animPlaybackInterval
    }
}
struct ColorData {
    let mainColor: Color = Color(hue: 0, saturation: 0, brightness: 0.5)
    let accentColor: Color = Color(hue: 0, saturation: 0, brightness: 0.55)
    let deepColor: Color = Color(hue: 0, saturation: 0, brightness: 0.6)
    
//    let accent: Color = Color(hue: 0, saturation: 0, brightness: 1)
    let accent: Color = Color(red: 0, green: 0.7, blue: 1)
    let nah: Color = Color(red: 1, green: 0.2, blue: 0.2)
}
