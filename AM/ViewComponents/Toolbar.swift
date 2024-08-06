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
    var appData: AppData
    
    @State var searchText: String = ""
    @FocusState var searchFocused: Bool
    
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
//                        appFormat.colorScheme.mainColor.opacity(0.1)
                    
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
                                Task {
                                    do {
                                        let req = MusicCatalogSearchRequest(term: "weeknd", types: [Album.self, Song.self])
                                        let res = try await req.response()
                                        print("Res:", res)
                                    }
                                    catch {
                                        let nsError = error as NSError
                                        print(error)
                                        print("Error Description:", nsError.localizedDescription)
                                    }
                                }
                            }
                            .onHover() { over in
                                if !over { self.searchFocused = false }
                            }
                            .task {
                                self.searchFocused = false
                            }
                            .font(.callout)
                    }
                    .padding([.leading], 10)
                }
                .frame(width:270, height:26)
            }
            .padding([.leading], 100)
        }
        .frame(height: 55)
    }
}

#Preview {
    VStack {
        
    }
}
