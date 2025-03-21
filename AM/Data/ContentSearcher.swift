//
//  ContentSearcher.swift
//  AM
//
//  Created by Reid Taylor on 12/19/23.
//

import Foundation
import AppKit
import SwiftUI
import MusicKit

class ContentSearcher : ObservableObject {
    
    @ObservedObject var library: MusicLibrary
    
    @Published var results: [PlayableItem] = []
    @Published var onItemSelected: ((PlayableItem) -> Void)?
    
    var weights : [PlayableItem : Double] = [:]
    @Published var maxRESULTS : Int = 10
    @Published var defaultSearchBar : Bool = true
    
    public init(_ library : MusicLibrary) {
        self.library = library
        
        refreshSearchResults("");
    }
    
    public func refreshSearchResults(_ search : String) {
        // Source weight dict
        weights = [:];
        results = [];
        var s = 0, a = 0, art = 0;
        while s < self.library.songs.count || a < self.library.albums.count || art < self.library.artists.count {
            // Songs
            if s < self.library.songs.count {
                let w = getCompareWeight(self.library.songs[s].getName().lowercased(), search.lowercased());
                
                if (w >= 1) {
                    weights[self.library.songs[s]] = w;
                }
                s += 1;
            }
            
            // Albums
            if a < self.library.albums.count {
                let w = getCompareWeight(self.library.albums[a].getName().lowercased(), search.lowercased());
                
                if (w >= 1) {
                    weights[self.library.albums[a]] = w;
                }
                a += 1;
            }
            // Artists
            if art < self.library.artists.count {
                let w = getCompareWeight(self.library.artists[art].getName().lowercased(), search.lowercased());
                
                if (w >= 1) {
                    weights[self.library.artists[art]] = w;
                }
                art += 1;
            }
        }
        
        // Sort by keyword weight
        for d in weights.sorted(by: { $0.value < $1.value }) {
            results.insert(d.key, at: 0)
        }
        
        // Cap results
        while maxRESULTS < results.count {
            results.removeLast()
        }
    }
    
    func getCompareWeight(_ a : String, _ b : String) -> Double {
        var w = 0.0;
        if a.contains(b) { w += 10; }
        
        if a.count > 1 && b.count > 1 && a[a.index(a.startIndex, offsetBy: 0)] == b[b.index(b.startIndex, offsetBy: 0)] {
            if a[a.index(a.startIndex, offsetBy: 1)] == b[b.index(b.startIndex, offsetBy: 1)] {
                w += 5;
            }
        }
        
        return w;
    }
}
