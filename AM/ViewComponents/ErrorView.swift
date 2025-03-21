
//
//  LoadMask.swift
//  AM
//
//  Created by Reid Taylor on 12/19/23.
//

import SwiftUI

struct ErrorView: View {
    @ObservedObject var library: MusicLibrary
    @State var appData : AppData
    
    static let ERROR_DATA : [Int: [String: String]] = [
        -1 : [ // DEFAULT
            "icon" : "exclamationmark.triangle",
            "msg" : "Looks like an error occurred! Please contact support if this issue persists",
            "buttonMsg" : "Try Again"
        ],
         
        401 : [ // Invalid Access Token
            "icon" : "accessibility",
            "msg" : "Looks like your access token is invalid! Please contact support if this issue persists",
            "buttonMsg" : "Try Again"
        ],
        404 : [ // Not found
            "icon" : "questionmark.circle",
            "msg" : "Resource not found. Try restarting the application",
            "buttonMsg" : "Try Again"
        ],
        429 : [ // Too many requests
            "icon" : "exclamationmark.circle",
            "msg" : "Too many API calls made! Please wait a few minutes and try again",
            "buttonMsg" : "Try Again"
        ],
         
        600 : [ // Network issue
            "icon" : "wifi.slash",
            "msg" : "Looks like there was an issue with your network! Please check connection",
            "buttonMsg" : "Try Again"
        ],
        601 : [ // No internet
            "icon" : "wifi.slash",
            "msg" : "Looks like you are offline! Please check connection",
            "buttonMsg" : "Try Again"
        ],
        602 : [ // Bad connection
            "icon" : "wifi.slash",
            "msg" : "Looks like our request timed-out! Please check connection",
            "buttonMsg" : "Try Again"
        ],
        603 : [ // Check Wifi Connection
            "icon" : "wifi.slash",
            "msg" : "Having trouble finding a connection! Please verify your internet connection",
            "buttonMsg" : "Try Again"
        ],
    ]
    @State var currentData : [String: String] = ERROR_DATA[-1]!
    
    var tryAgain : () -> Void
    
    var body: some View {
        GeometryReader() { geometry in
            ZStack {
                MaterialBackground().colorMultiply(appData.colorScheme.deepColor)
                
                VStack(spacing: 15) {
                    Image(systemName: currentData["icon"]!).resizable().scaledToFit().frame(width: 50, height: 50)
                    Text(currentData["msg"]!).font(.title3.bold())
                }
                
                Button(action: { () in
                    tryAgain()
                }) {
                    ZStack {
                        LinearGradient(gradient: Gradient(colors: [appData.colorScheme.deepColor, appData.colorScheme.accentColor]), startPoint: .top, endPoint: .bottom)
                            .cornerRadius(8)
                            .opacity(0.15)
                            .shadow(color: .black, radius: 10)
                        
                        Text(currentData["buttonMsg"]!).font(.title3.bold())
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 250, height: 50, alignment: .bottom)
                .padding(.bottom, 10)
                .offset(x: 0, y: geometry.size.height / 2 - 100)
            }
            .onChange(of: library.ERROR) { oldValue, newValue in
                self.updateCurrentData()
            }
            .onAppear() {
                self.updateCurrentData()
            }
        }
    }
    
    private func updateCurrentData() {
        currentData = ErrorView.ERROR_DATA[-1]!
        if ErrorView.ERROR_DATA.keys.contains(where: { $0 == library.ERROR }) {
            currentData = ErrorView.ERROR_DATA[library.ERROR]!
        }
    }
}

#Preview {
    VStack {
        
    }
}
