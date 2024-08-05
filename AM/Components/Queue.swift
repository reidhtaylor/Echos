//
//  SwiftUIView.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit


struct Queue: View {
    @ObservedObject var library: MusicLibrary
    @State var appFormat: FormatData
    
    var content: ContentView
    
    @State var dragWindowInitial = -1.0
    var dragQueueWindow: some Gesture {
        DragGesture()
            .onChanged() { gesture in
                if self.dragWindowInitial == -1.0 {
                    self.dragWindowInitial = appFormat.queueWidth
                    if NSCursor.current != NSCursor.resizeLeftRight {
                        NSCursor.resizeLeftRight.push()
                    }
                }
                
                self.appFormat.queueWidth = dragWindowInitial - gesture.translation.width
                if self.appFormat.queueWidth > self.appFormat.queueRestriction.height {
                    self.appFormat.queueWidth = self.appFormat.queueRestriction.height
                }
                else if self.appFormat.queueWidth < self.appFormat.queueRestriction.width {
                    self.appFormat.queueWidth = self.appFormat.queueRestriction.width
                }
            }
            .onEnded() { gesture in
                self.dragWindowInitial = -1.0
                NSCursor.pop()
            }
    }
    let dragWidth = 4.0
    
    @State var itemDragging: MusicPlayer.Queue.Entry? = nil
    @State var itemDropIndex = -1
    
    @State var horizontalDragVal = 0.0
    @State var itemDragRemoveReady = false
    @State var itemDragNextReady = false
    
    @State var verticalDragVal = 0.0
    @State var itemDragMoving = false
    @State var initialMoveIndex = -1
    
    @State var lastMouseLocation = CGPoint(x: 0.0, y: 0.0)
    var mouseLocation: NSPoint { NSEvent.mouseLocation }
    @State var mouseDelta = CGPoint(x: 0.0, y: 0.0)

    var body: some View {
        ZStack {
            MaterialBackground().colorMultiply(appFormat.colorScheme.accentColor).ignoresSafeArea()
            
            // Queue Stack
            VStack(alignment: .leading, spacing:0) {
                // Queue Title
                VStack(alignment: .leading) {
                    if library.currentlyPlaying == nil {
//                        Image(nsImage: NSImage(imageLiteralResourceName: "UnknownAlbum"))
                        ZStack {
                            MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor)
                                .frame(width: appFormat.queueWidth - 30, height: appFormat.queueWidth - 30)
                                .cornerRadius(appFormat.musicArtCorner * 2)
                                .padding([.bottom], 5)
                            
                            Image(systemName: "music.note").resizable().aspectRatio(contentMode: .fit).opacity(0.2)
                                .frame(width:70, height:70)
                        }
                        
                        Text("No Songs in Queue").font(.system(size: 15)).lineLimit(1)
                            .frame(maxWidth: appFormat.queueWidth - 30, alignment:.leading).opacity(0.4)
                    }
                    else {
                        ArtworkImage(library.currentlyPlaying!.artwork!, width: appFormat.queueWidth - 30, height: appFormat.queueWidth - 30)
                            .cornerRadius(appFormat.musicArtCorner)
                            .padding([.bottom], 5)
                        
                        Text(library.currentlyPlaying!.title).font(.system(size: 15)).lineLimit(1)
                            .frame(maxWidth: appFormat.queueWidth - 30, alignment:.leading)
                        Text(library.currentlyPlaying!.artistName).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                            .frame(maxWidth: appFormat.queueWidth - 30, alignment:.leading)
                    }
                    
                    HStack(spacing:2) {
                        appFormat.colorScheme.mainColor.colorInvert()
                            .frame(width: (appFormat.queueWidth - 30) * library.getPlaybackProgress())
                        appFormat.colorScheme.mainColor.colorInvert().opacity(0.2)
                    }
                    .frame(width: appFormat.queueWidth - 30, height: 3)
                    .animation(.linear(duration: 0.01), value: library.getPlaybackProgress())
                    .onTapGesture { location in
                        library.setLivePlayback0to1(location.x / (appFormat.queueWidth - 30))
                    }
                    
                    Text(library.getPlaybackString()).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                        .frame(maxWidth: appFormat.queueWidth - 30, alignment:.leading)
                  
                    Text("Queue").font(.system(size: 20).bold())
                        .padding([.leading], 15)
                        .padding([.bottom], 10)
                        .padding([.top], 20)
                }
                .padding([.leading, .top], 15)
                
                appFormat.colorScheme.mainColor.colorInvert().opacity(0.2).frame(height: 1)
                
                // Queue Items
                ZStack {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(0..<library.workingQueue.count, id: \.self) { i in
                                let q = library.workingQueue[i]
                                ZStack(alignment: horizontalDragVal > 0 ? .leading : .trailing) {
                                    if q == itemDragging && !itemDragMoving {
                                        if horizontalDragVal > 0 {
                                            ZStack(alignment: .leading) {
                                                MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor)
                                                
                                                ZStack {
                                                    Color.black
                                                        .opacity(itemDragRemoveReady ? 0.4 : 0)
                                                    
                                                    Image(systemName: "trash.fill")
                                                }
                                                    .frame(maxWidth: itemDragRemoveReady ? .infinity : 60)
                                                    .animation(.easeInOut(duration: 0.1), value: itemDragRemoveReady)
                                            }.frame(width: horizontalDragVal, height: 60)
                                        }
                                        else {
                                            ZStack(alignment: .trailing) {
                                                MaterialBackground().colorMultiply(appFormat.colorScheme.mainColor)
                                                
                                                ZStack {
                                                    Color.white
                                                        .opacity(itemDragNextReady ? 0.13 : 0)
                                                    
                                                    Image(systemName: "text.insert")
                                                }
                                                    .frame(maxWidth: itemDragNextReady ? .infinity : 60)
                                                    .animation(.easeInOut(duration: 0.1), value: itemDragNextReady)
                                            }.frame(width: -horizontalDragVal, height: 60)
                                        }
                                    }
                                    
                                    queueItem(item: q, queueWidth: appFormat.queueWidth, visible: (!itemDragMoving || initialMoveIndex != i) && library.workingQueue.firstIndex(where: {$0 == q}) != 0)
                                        .background(MaterialBackground().colorMultiply(library.currentlyPlaying != nil && q.title == library.currentlyPlaying!.title ? appFormat.colorScheme.accent : .clear))
                                        .opacity(itemDropIndex == -1 ? 1 : 0.15)
                                        .offset(x: q == itemDragging && !itemDragMoving ? horizontalDragVal : 0, y: 0)
                                        .modifier(PressActions(
                                            onPress: {
                                                itemDragging = q
                                                initialMoveIndex = i
                                                lastMouseLocation = self.mouseLocation
                                                horizontalDragVal = 0
                                                verticalDragVal = 0
                                                itemDragRemoveReady = false
                                                itemDragNextReady = false
                                                itemDragMoving = false
                                            },
                                            onRelease: {
                                                if itemDragMoving && itemDropIndex != -1 {
                                                    library.workingQueue.remove(at: initialMoveIndex)
                                                    
                                                    let index = itemDropIndex >= initialMoveIndex + 1 ? itemDropIndex - 1 : itemDropIndex
                                                    if index >= library.workingQueue.count {
                                                        library.workingQueue.append(itemDragging!)
                                                    }
                                                    else {
                                                        library.workingQueue.insert(itemDragging!, at: index)
                                                    }
                                                }
                                                else if itemDragRemoveReady {
                                                    let ind = library.workingQueue.firstIndex(where: {$0 == itemDragging})
                                                    if ind != nil {
                                                        library.workingQueue.remove(at: ind!)
                                                    }
                                                }
                                                else if itemDragNextReady {
                                                    library.workingQueue.remove(at: library.workingQueue.firstIndex(where: {$0 == itemDragging})!)
                                                    library.workingQueue.insert(itemDragging!, at: 1)
                                                }
                                                
                                                itemDragging = nil
                                                itemDropIndex = -1
                                                itemDragMoving = false
                                                itemDragRemoveReady = false
                                                itemDragNextReady = false
                                            }
                                        ))
                                }
                                .frame(width: appFormat.queueWidth)
                                
                                if itemDropIndex != -1 && itemDropIndex == i + 1 {
                                    queueItem(item: itemDragging!, queueWidth: appFormat.queueWidth)
                                        .opacity(1)
                                }
                            }
                            
                            Text(library.workingQueue.count == 0 ? "Queue is Empty" : "End of Queue").font(.callout)
                                .frame(maxWidth: .infinity)
                                .opacity(0.3)
                                .padding(10)
                                .padding([.bottom], 200)
                        }
                    }
                    .padding([.top], 3)
//                    .animation(.linear(duration: 0.2), value: library.workingQueue)
//                    .transition(.scale)
                }
            }
            
            Color.white.opacity(0.001)
                .frame(width: dragWidth)
                .ignoresSafeArea()
                .offset(x:-appFormat.queueWidth / 2, y:0)
                .gesture(dragQueueWindow)
                .onHover { inside in
                            if inside {
                                if NSCursor.current != NSCursor.resizeLeftRight {
                                    NSCursor.resizeLeftRight.push()
                                }
                            } else if dragWindowInitial == -1.0 {
                                NSCursor.pop()
                            }
                        }
        }
        .frame(width: appFormat.queueWidth)
        .onAppear() {
            NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) {
                if itemDragging != nil {
                    mouseDelta.x = self.mouseLocation.x - lastMouseLocation.x
                    mouseDelta.y = self.mouseLocation.y - lastMouseLocation.y
                }
                lastMouseLocation = self.mouseLocation
                return $0
            }
        }
        .onChange(of: mouseDelta) {
            if !itemDragMoving {
                horizontalDragVal += mouseDelta.x * 2
                if horizontalDragVal > appFormat.queueWidth { horizontalDragVal = appFormat.queueWidth }
                else if horizontalDragVal < -appFormat.queueWidth { horizontalDragVal = -appFormat.queueWidth }
                
                if horizontalDragVal > (appFormat.queueWidth / 5) * CGFloat(3) {
                    itemDragRemoveReady = true
                }
                else if itemDragRemoveReady {
                    itemDragRemoveReady = false
                }
                
                if horizontalDragVal < -(appFormat.queueWidth / 5) * 3 {
                    itemDragNextReady = true
                }
                else if itemDragNextReady {
                    itemDragNextReady = false
                }
            }
            
            if !itemDragRemoveReady && !itemDragNextReady && abs(horizontalDragVal) < 10 {
                verticalDragVal += mouseDelta.y
                
                if itemDragMoving {
                    itemDropIndex = min(library.workingQueue.count, max(1, initialMoveIndex - Int(floor(verticalDragVal / 60.0))))
                }
                
                if !itemDragMoving && abs(verticalDragVal) > 20 {
                    itemDragMoving = true
                    itemDropIndex = initialMoveIndex
                }
            }
        }
    }
    
    private func queueItem(item: ApplicationMusicPlayer.Queue.Entry, queueWidth: CGFloat, visible: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if visible {
                content.listItem(height: 40, artwork: item.artwork, mainTitle: item.title, subTitle: item.subtitle)
                    .padding(10)
                
                appFormat.colorScheme.mainColor.colorInvert().opacity(0.15)
                    .frame(height: 1)
                    .padding([.leading], 60)
            }
        }.frame(width: queueWidth, alignment: .leading)
    }
    
    private func getItem(_ id: String) -> MusicPlayer.Queue.Entry! {
        for q in library.workingQueue {
            if q.id == id {
                return q
            }
        }
        return nil
    }
}

struct PressActions: ViewModifier {
    @State var pressed = false
    var onPress: () -> Void
    var onRelease: () -> Void
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        if !pressed {
                            onPress()
                            pressed = true
                        }
                    })
                    .onEnded({ _ in
                        onRelease()
                        pressed = false
                    })
            )
    }
}

#Preview {
    VStack {
        
    }
}
