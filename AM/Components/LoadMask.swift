//
//  LoadMask.swift
//  AM
//
//  Created by Reid Taylor on 12/19/23.
//

import SwiftUI

struct LoadMask: View {
    @ObservedObject var library: MusicLibrary
    
    var body: some View {
        Color.black.opacity(0.9)
            .ignoresSafeArea()
        
        Text(library.loadDescription).shadow(color:.black, radius: 5)
            .font(.callout)
    }
}

#Preview {
    VStack {
        
    }
}
