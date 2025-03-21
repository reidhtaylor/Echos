//
//  SelectMusicSource.swift
//  AM
//
//  Created by Reid Taylor on 12/19/23.
//

import SwiftUI

struct SelectMusicSource: View {
    @State var library: MusicLibrary
    @State var appData: AppData
    @State var geom: GeometryProxy
    
    static let circleSize: CGFloat = 150
    static let largeCircleSize: CGFloat = 300
    
    @State var amCs : CGFloat = largeCircleSize
    @State var spCs : CGFloat = circleSize
    
    @State var selectedSource : MusicSource = .appleMusic
    @State var shift : CGFloat = 0
    
    let amColor : Color = Color(red: 99 / 100, green: 24 / 100, blue: 27 / 100)
    let am2Color : Color = Color(red: 98 / 100, green: 30 / 100, blue: 34 / 100)
    let spColor : Color = Color(red: 11 / 100, green: 73 / 100, blue: 33 / 100)
    let sp2Color : Color = Color(red: 12 / 100, green: 84 / 100, blue: 38 / 100)
    
    @State var selected : Bool = false
    @State var selectedExpander : CGFloat = -1
    
    var body: some View {
        ZStack {
            // Only show options if selection screen isn't shrinking
            if selectedExpander != 0 {
                // Split Apple Music and Spotify Options to left and right
                HStack(spacing: 0) {
                    // Apple Music
                    ZStack(alignment: .trailing) {
                        // Background
                        MaterialBackground().colorMultiply(appData.colorScheme.accentColor)
                            .colorMultiply(selectedSource == .appleMusic ? Color(hue: 0, saturation: 0, brightness: 0.95) : .white)
                        
                        // Apple Music Slider (background low opacity)
                        ZStack {
                            amColor
                            
                            Image("Apple_Music_Icon")
                                .resizable()
                                .frame(width: SelectMusicSource.largeCircleSize * 0.75, height: SelectMusicSource.largeCircleSize * 0.75)
                                .colorMultiply(.white)
                        }
                        .frame(width: SelectMusicSource.largeCircleSize, height: SelectMusicSource.largeCircleSize)
                        .cornerRadius(2*SelectMusicSource.largeCircleSize)
                        .offset(x: (SelectMusicSource.largeCircleSize / 2) - (geom.size.width / 4), y: 0)
                        .allowsHitTesting(false)
                        .saturation(0).opacity(0.15)
                        
                        // Apple Music Slider
                        ZStack {
                            amColor
                            
                            Image("Apple_Music_Icon")
                                .resizable()
                                .frame(width: amCs * 0.75, height: amCs * 0.75)
                                .colorMultiply(.white)
                        }
                        .frame(width: amCs, height: amCs)
                        .cornerRadius(2*amCs)
                        .offset(x: amCs / 2 + shift, y: 0)
                        .animation(.bouncy, value: amCs)
                        .allowsHitTesting(false)
                    }
                    .frame(width: geom.size.width / 2, height: geom.size.height)
                    .clipped()
                    .onHover(perform: { over in
                        if over {
                            selectedSource = .appleMusic
                        }
                        spCs = SelectMusicSource.circleSize
                        amCs = SelectMusicSource.largeCircleSize
                        shift = -(geom.size.width / 4)
                    })
                    
                    // Middle Line
                    (selectedSource == .appleMusic ? amColor : spColor)
                        .frame(width: 2).opacity(1)
                    
                    // Spotify
                    ZStack(alignment: .leading) {
                        MaterialBackground().colorMultiply(appData.colorScheme.accentColor)
                            .colorMultiply(selectedSource == .spotify ? Color(hue: 0, saturation: 0, brightness: 0.95) : .white)
                        
                        // Spotify Slider (background low opacity)
                        ZStack {
                            spColor
                            
                            Image("Spotify_Music_Icon")
                                .resizable()
                                .frame(width: SelectMusicSource.largeCircleSize * 0.75, height: SelectMusicSource.largeCircleSize * 0.75)
                                .brightness(1)
                        }
                        .frame(width: SelectMusicSource.largeCircleSize, height: SelectMusicSource.largeCircleSize)
                        .cornerRadius(2*SelectMusicSource.largeCircleSize)
                        .offset(x: -(SelectMusicSource.largeCircleSize / 2) + (geom.size.width / 4), y: 0)
                        .allowsHitTesting(false)
                        .saturation(0).opacity(0.15)
                        
                        // Spotify Slider
                        ZStack {
                            spColor
                            
                            Image("Spotify_Music_Icon")
                                .resizable()
                                .frame(width: spCs * 0.9, height: spCs * 0.9)
                        }
                        .frame(width: spCs, height: spCs)
                        .cornerRadius(2*spCs)
                        .offset(x: -spCs / 2 + shift, y: 0)
                        .animation(.bouncy, value: spCs)
                        .allowsHitTesting(false)
                    }
                    .frame(width: geom.size.width / 2, height: geom.size.height)
                    .clipped()
                    .onHover(perform: { over in
                        if over {
                            selectedSource = .spotify
                        }
                        spCs = SelectMusicSource.largeCircleSize
                        amCs = SelectMusicSource.circleSize
                        shift = (geom.size.width / 4)
                    })
                    .onTapGesture {
                        
                    }
                }
                .animation(.bouncy(duration: 0.03), value: shift)
                .onAppear() {
                    selectedSource = .appleMusic
                    spCs = SelectMusicSource.circleSize
                    amCs = SelectMusicSource.largeCircleSize
                    shift = -(geom.size.width / 4)
                }
            
                Button(action: { () in
                    selected = true
                    selectedExpander = SelectMusicSource.largeCircleSize
                }) {
                    ZStack {
                        LinearGradient(gradient: Gradient(colors: [selectedSource == .appleMusic ? amColor : spColor, selectedSource == .appleMusic ? am2Color : sp2Color]), startPoint: .bottom, endPoint: .top)
                            .cornerRadius(8)
                        Text(selectedSource == .appleMusic ? "Apple Music" : "Spotify").font(.title3.bold())
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 200, height: 45)
                .offset(x: shift, y: (geom.size.height + SelectMusicSource.largeCircleSize) / 4)
            }
            
            if selected {
                if selectedExpander != 0 {
                    MaterialBackground().colorMultiply(appData.colorScheme.accentColor)
                        .onAppear() {
                            shift = 0
                            selectedExpander = geom.size.width
                            
                            Task {
                                var t = 1.5
                                
                                library.SetupSource(selectedSource)
                                
                                if (selectedSource == .appleMusic) {
                                    while (library.signing) {
                                        try? await Task.sleep(for: .seconds(0.1))
                                        t -= 0.1
                                    }
                                    
                                    library.LoadSource()
                                    while (!library.initialized) {
                                        try? await Task.sleep(for: .seconds(0.1))
                                        t -= 0.1
                                    }
                                }
                                
                                if t > 0 {
                                    try? await Task.sleep(for: .seconds(t))
                                }
                                
                                selectedExpander = 0
                                
                                if (selectedSource == .appleMusic) {
                                    try? await Task.sleep(for: .seconds(1))
                                    library.selectingSource = false;
                                }
                            }
                        }
                }
                
                ZStack {
                    selectedSource == .appleMusic ? amColor : spColor
                    
                    Image(selectedSource == .appleMusic ? "Apple_Music_Icon" : "Spotify_Music_Icon")
                        .resizable()
                        .frame(width: SelectMusicSource.largeCircleSize * 0.9, height: SelectMusicSource.largeCircleSize * 0.9)
                }
                .frame(width: selectedExpander, height: (selectedExpander / geom.size.width) * geom.size.height, alignment: .center)
                .cornerRadius((1 - (selectedExpander / geom.size.width)) * 600)
                .offset(x: shift, y: 0)
                .animation(.bouncy, value: shift)
                .animation(.easeIn(duration: 0.3), value: selectedExpander)
            }
        }
    }
}

#Preview {
    VStack {
        
    }
}
