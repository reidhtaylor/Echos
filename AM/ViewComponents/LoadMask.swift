//
//  LoadMask.swift
//  AM
//
//  Created by Reid Taylor on 12/19/23.
//

import SwiftUI

struct LoadMask: View {
    @ObservedObject var library: MusicLibrary
    @State var appData : AppData
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(hue: 0, saturation: 0, brightness: 1).opacity(0.015)
                    .ignoresSafeArea()
                    .cornerRadius(10)
                
                Text(library.loadDescription).shadow(color:.black, radius: 5)
                    .font(.footnote.bold())
            }
            .frame(width: 250, height: 50)
            
            Color.black.opacity(0).frame(height: 400)
        }
    }
}

#Preview {
    VStack {
        
    }
}
