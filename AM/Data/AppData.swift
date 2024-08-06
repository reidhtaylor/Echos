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

class AppData {
    var colorScheme : ColorData
    var appFormat : FormatData
    
    public init() {
        colorScheme = ColorData()
        appFormat = FormatData()
    }
}

struct FormatData {
    var queueWidth: CGFloat
    let queueRestriction: CGSize
    
    let playerHeight: CGFloat
    let musicArtCorner: CGFloat
    
    let animPlaybackInterval : Double
    
    public init(queueWidth: CGFloat = 250, queueRestriction: CGSize = CGSize(width: 200, height: 550), playerHeight: CGFloat = 65, musicArtCorner: CGFloat = 4, animPlaybackInterval: Double = 0.4) {
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
    
    let accent: Color = Color(hue: 0, saturation: 0, brightness: 1)
}
