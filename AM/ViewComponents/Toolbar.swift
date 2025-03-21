//
//  Toolbar.swift
//  AM
//
//  Created by Reid Taylor on 12/25/23.
//

import SwiftUI
import MusicKit

struct Toolbar: View {
    
    var library: MusicLibrary
    var content: ContentView
    var appData: AppData
    
    @State var searchText: String = ""
    @FocusState var searchFocused: Bool
    
    let options : [String] = ["Home", "Songs", "Albums", "Artists"]
    
    @Binding var selectedOption : Int
    
    var body: some View {
        ZStack(alignment: .leading) {
            MaterialBackground().colorMultiply(appData.colorScheme.deepColor).ignoresSafeArea()
            
            HStack(spacing: 10) {
                Button(action: {}) {
                    Image(systemName: "gearshape.fill").resizable().fontWeight(.ultraLight)
                        .frame(width: 15, height: 15)
                }
                .buttonStyle(.plain)

                ZStack {
                    Rectangle().fill(LinearGradient(colors: [Color.clear, appData.colorScheme.mainColor.opacity(0.025)], startPoint: .leading, endPoint: .trailing))
                    
                    ZStack(alignment: .leading) {
                        Image(systemName: "magnifyingglass")
                        
                        TextField("Search", text: $searchText)
                            .frame(maxWidth: .infinity)
                            .padding([.leading], 25)
                            .textFieldStyle(.plain)
                            .focused($searchFocused)
                            .onSubmit {
                                self.searchFocused = false
                            }
                            .onChange(of: searchText) {
                                if content.miniSearcher != nil {
                                    content.miniSearcher!.refreshSearchResults(searchText)
                                }
                            }
                            .onHover() { over in
                                if !over { self.searchFocused = false }
                            }
                            .task {
                                self.searchFocused = false
                            }
                            .font(.callout)
                            .onChange(of: searchFocused) {
                                if searchFocused {
                                    // Initialize searcher
                                    if (library.loaded && content.miniSearcher == nil) {
                                        content.miniSearcher = ContentSearcher(library)
                                        content.miniSearcher!.defaultSearchBar = false
                                        content.miniSearcher!.onItemSelected = { item in
                                            library.setPreviewingItem(item, content)
                                            
                                            searchFocused = false
                                            searchText = ""
                                        }
                                        content.miniSearcher!.refreshSearchResults(searchText)
                                    }
                                }
                                else if (content.miniSearcher != nil && content.miniSearcher!.defaultSearchBar == false) {
                                    searchFocused = true
                                }
                            }
                    }
                    .padding([.leading], 10)
                }
                .frame(width:270, height:26)
//                
//                Spacer()
//                HStack(alignment: .center, spacing: 0) {
//                    ForEach(0..<options.count, id: \.self) { i in
//                        Button(action: {
//                            selectedOption = i
//                        }) {
//                            ZStack {
//                                MaterialBackground().colorMultiply(appData.colorScheme.deepColor)
////                                    .cornerRadius(100)
//                                    .frame(width: 150)
//                                
//                                Text(options[i]).font(.subheadline.bold()).lineLimit(1).opacity(i == selectedOption ? 1 : 0.4)
//                                    .shadow(color:.black.opacity(0.2), radius:5, x:0, y:0)
//                            }
//                        }
//                        .buttonStyle(.plain)
//                    }
//                }
//                .frame(height: 40)
//                
//                Spacer()
            }
            .padding([.leading], 100)
//            .padding(.trailing, 285)
        }
        .frame(height: 55)
    }
}

#Preview {
    VStack {
        
    }
}
