//
//  SwiftUIView.swift
//  AM
//
//  Created by Reid Taylor on 12/23/23.
//

import SwiftUI
//import iTunesLibrary
import MusicKit
import Combine


struct Queue: View {
    @ObservedObject var library: MusicLibrary
    @ObservedObject var appData: AppData
    
    var content: ContentView
    
    @StateObject var musicProgressTracker: MusicProgressTracker
    
    @State var clearOn : CGFloat = 0.0
    @State private var showAlert = false
    
    @State var dragWindowInitial = -1.0
    var dragHideCap : CGFloat = 30
    @State var queueWidth = 30.0
    @State var unhide : Bool = false
    var dragQueueWindow: some Gesture {
        DragGesture()
            .onChanged() { gesture in
                if self.dragWindowInitial == -1.0 {
                    self.dragWindowInitial = queueWidth
                    if NSCursor.current != NSCursor.resizeLeftRight {
                        NSCursor.resizeLeftRight.push()
                    }
                }
                
                queueWidth = dragWindowInitial - gesture.translation.width
                if queueWidth > self.appData.appFormat.queueRestriction.height + 10 {
                    queueWidth = self.appData.appFormat.queueRestriction.height + 10
                }
                else if self.queueWidth < self.appData.appFormat.queueRestriction.width - 10 {
                    queueWidth = self.appData.appFormat.queueRestriction.width - 10
                }
            }
            .onEnded() { gesture in
                self.dragWindowInitial = -1.0
                NSCursor.pop()
                
                if (queueWidth < self.appData.appFormat.queueRestriction.width) {
                    self.appData.queueState = .hidden
                }
                else if (queueWidth > self.appData.appFormat.queueRestriction.height) {
                    self.appData.queueState = .presenter
                }
            }
    }
    let dragWidth = 4.0
    
    @State var itemDragging: PlayableItem? = nil
    @State var itemDropIndex = -1
    
    @State var horizontalDragVal = 0.0
    let horizontalDragStep : Double = 25
    @State var itemDragRemoveReady = false
    @State var itemDragNextReady = false
    
    @State var verticalDragVal = 0.0
    @State var itemDragMoving = false
    @State var initialMoveIndex = -1
    
    @State var lastMouseLocation = CGPoint(x: 0.0, y: 0.0)
    var mouseLocation: NSPoint { NSEvent.mouseLocation }
    @State var mouseDelta = CGPoint(x: 0.0, y: 0.0)

    var body: some View {
        if (self.appData.queueState == .side || self.appData.queueState == .isolated) {
            ZStack (alignment: .top) {
                MaterialBackground().colorMultiply(appData.colorScheme.accentColor).ignoresSafeArea()
                
                // Queue Stack
                VStack(alignment: .center, spacing:0) {

                    // Queue Title
                    VStack(alignment: .center) {
                        if library.currentlyPlaying == nil {
                            library.EmptyArt(appData, queueWidth - 30, queueWidth - 30)
                            
                            Text("Nothing Playing").font(.system(size: 15)).lineLimit(1)
                                .frame(maxWidth: queueWidth - 30, alignment:.leading).opacity(0.4)
                        }
                        else {
                            if library.currentlyPlaying!.getArtwork() != nil {
                                ArtworkImage(library.currentlyPlaying!.getArtwork()!, width: queueWidth - 30, height: queueWidth - 30)
                                    .cornerRadius(appData.appFormat.musicArtCorner)
                                    .padding([.bottom], 5)
                            }
                            else if library.currentlyPlaying!.getArtworkURL().count > 0 {
                                AsyncImage(url: URL(string: library.currentlyPlaying!.getArtworkURL()))
                                    .frame(width: queueWidth - 30, height: queueWidth - 30)
                                    .cornerRadius(appData.appFormat.musicArtCorner)
                                    .padding([.bottom], 5)
                            }
                            else {
                                library.EmptyArt(appData, queueWidth - 30, queueWidth - 30)
                                    .cornerRadius(appData.appFormat.musicArtCorner)
                                    .padding([.bottom], 5)
                            }
                            
                            Text(library.currentlyPlaying!.getName()).font(.system(size: 15)).lineLimit(1)
                                .frame(maxWidth: queueWidth - 30, alignment:.leading)
                            Text(library.currentlyPlaying!.getArtistName()).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                                .frame(maxWidth: queueWidth - 30, alignment:.leading)
                        }
                        
 
                        HStack (spacing: 0) {
                            appData.colorScheme.mainColor.colorInvert()
                                .frame(width: (queueWidth - 30) * musicProgressTracker.progress)
                            appData.colorScheme.mainColor.colorInvert().opacity(0.2)
                        }
                        .frame(width: queueWidth - 30, height: 3)
                        .contentShape(Rectangle().inset(by: -5))
                        .onChange(of: musicProgressTracker.progress, { oldValue, newValue in
                            musicProgressTracker.progressDuration = newValue
                        })
                        .animation(.linear(duration: musicProgressTracker.progressDuration), value: musicProgressTracker.progress)
                        .onTapGesture { location in
                            library.setLivePlayback0to1(location.x / (queueWidth - 30))
                        }
                        
                        Text(library.getTimeString(CGFloat(musicProgressTracker.timerCounter))).font(.system(size: 12)).opacity(0.5).lineLimit(1)
                            .frame(maxWidth: queueWidth - 30, alignment:.leading)
                        
                        if self.appData.queueState != .isolated {
                            HStack(alignment: .bottom) {
                                Text("Queue").font(.system(size: 20).bold())
                                    .padding([.leading], 15)
                                    .padding([.bottom], 10)
                                    .padding([.top], 20)
                                
                                Spacer()
                                
                                if (library.queue.count > library.queueIndex + 1) {
                                    Button(action: {
                                        showAlert = true
                                    }) {
                                        ZStack(alignment: .center) {
                                            MaterialBackground().colorMultiply(self.appData.colorScheme.mainColor).colorInvert().opacity(0.05)
                                                .cornerRadius(4)
                                            
                                            Text("Clear").font(.system(size: 10)).opacity(0.5)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 65, height: 18)
                                    .padding(.bottom, 12)
                                    .padding(.trailing, 12)
                                    .opacity(clearOn)
                                    .disabled(clearOn == 0)
                                    .animation(.linear(duration: 0.07), value: clearOn)
                                    .confirmationDialog("Clear Queue: Are you sure?", isPresented: $showAlert) {
                                        Button("Cancel", role: .cancel) { }
                                        Button("Clear", role: .destructive) {
                                            library.clearQueue()
                                        }
                                        .foregroundColor(.red)
                                    } message: {
                                        Text("This action cannot be undone.")
                                    }
                                }
                            }
                            .onHover() { over in
                                clearOn = over ? 1 : 0
                            }
                        }
                        else {
                            Rectangle().fill(.clear)
                                .frame(height: 10)
                        }
                    }
                    .padding([.top], 15)
                    
                    appData.colorScheme.mainColor.colorInvert().opacity(0.2).frame(height: 1)
                    
                    // Queue Items
                    ZStack {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                // Case for no previous item to display dragging item after
                                if itemDropIndex == 0 && itemDragging != nil {
                                    queueItem(item: itemDragging!, queueWidth: queueWidth)
                                        .opacity(1)
                                }
                                
                                ForEach(0..<library.queue.count, id: \.self) { i in
                                    ZStack(alignment: horizontalDragVal > 0 ? .leading : .trailing) {
                                        let q = library.queue[i]
                                        if (i == initialMoveIndex && itemDragging != nil) && !itemDragMoving && abs(horizontalDragVal) > horizontalDragStep {
                                            if horizontalDragVal > 0 {
                                                ZStack(alignment: .leading) {
                                                    MaterialBackground().colorMultiply(.black).opacity(0.7)
                                                    ZStack {
                                                        appData.colorScheme.nah
                                                            .opacity(itemDragRemoveReady ? 0.3 : 0)
                                                        
                                                        Image(systemName: "trash.fill")
                                                    }
                                                    .frame(maxWidth: itemDragRemoveReady ? .infinity : 60)
                                                    .animation(.easeInOut(duration: 0.1), value: itemDragRemoveReady)
                                                }.frame(width: (itemDragRemoveReady ? queueWidth : horizontalDragVal), height: 60)
                                            }
                                            else {
                                                ZStack(alignment: .trailing) {
                                                    MaterialBackground().colorMultiply(.black).opacity(0.7)
                                                    ZStack {
                                                        appData.colorScheme.accent
                                                            .opacity(itemDragNextReady ? 0.3 : 0)
                                                        
                                                        // Item is currently playing (display restart)
                                                        if (initialMoveIndex == library.queueIndex) {
                                                            Image(systemName: "gobackward")
                                                        }
                                                        else {
                                                            Image(systemName: "text.line.first.and.arrowtriangle.forward")
                                                        }
                                                    }
                                                    .frame(maxWidth: itemDragNextReady ? .infinity : 60)
                                                    .animation(.easeInOut(duration: 0.1), value: itemDragNextReady)
                                                }.frame(width: (itemDragNextReady ? queueWidth : -horizontalDragVal), height: 60)
                                            }
                                        }
                                        
                                        queueItem(item: q, queueWidth: queueWidth, visible: (!itemDragMoving || initialMoveIndex != i))
                                            .background(MaterialBackground().colorMultiply(library.currentlyPlaying != nil && i == library.queueIndex ? appData.colorScheme.accent : .clear))
                                            .opacity(itemDropIndex == -1 ? i >= library.queueIndex ? 1 : 0.45 : 0.15)
                                            .offset(x: (i == initialMoveIndex && itemDragging != nil) && !itemDragMoving && abs(horizontalDragVal) > horizontalDragStep ?
                                                    (itemDragNextReady ? queueWidth : (itemDragRemoveReady ? -queueWidth : horizontalDragVal))
                                                    : 0, y: 0)
                                            .modifier(PressActions(
                                                onPress: {
                                                    if itemDragging != nil && itemDragging != q { return }
                                                    
                                                    print("Press: " + q.getName())
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
                                                    if itemDragging == q {
                                                        print("Release: " + q.getName())
                                                        if itemDragMoving && itemDropIndex != -1 {
                                                            library.moveItemInQueue(initialMoveIndex, itemDropIndex)
                                                        }
                                                        else if itemDragRemoveReady {
                                                            library.removeItemFromQueue(initialMoveIndex)
                                                        }
                                                        else if itemDragNextReady {
                                                            // Restart song
                                                            if initialMoveIndex == library.queueIndex {
                                                                library.setLivePlayback0to1(0)
                                                            }
                                                            else {
                                                                library.moveItemInQueue(initialMoveIndex, library.queueIndex + 1)
                                                            }
                                                            
                                                        }
                                                        else if initialMoveIndex != library.queueIndex || (abs(horizontalDragVal) < horizontalDragStep) {
                                                            Task {
                                                                await library.playSong(initialMoveIndex)
                                                            }
                                                        }
                                                    }
                                                    else {
                                                        print("Release Canceled on " + q.getName())
                                                    }
                                                    
                                                    itemDragging = nil
                                                    itemDropIndex = -1
                                                    itemDragMoving = false
                                                    itemDragRemoveReady = false
                                                    itemDragNextReady = false
                                                }
                                            ))
                                            .contextMenu {
                                                DefaultDraws.ContextMenuPlayable(q, library, content)
                                            }
                                    }
                                    .frame(width: queueWidth)
                                    
                                    // Display new position for dragging item
                                    if itemDropIndex == i + 1 && itemDragging != nil {
                                        queueItem(item: itemDragging!, queueWidth: queueWidth)
                                            .opacity(1)
                                    }
                                    
                                    if (i == library.queueIndex - 1) {
                                        HStack(alignment: .bottom, spacing: 0) {
                                            Text(i + 1 >= library.queue.count ? "Complete" : "Playing").font(.title2).bold()
                                                .shadow(color:.black.opacity(0.5), radius:5, x:4, y:4)
                                                .lineLimit(1)
                                                .frame(height: 40)
                                            Spacer()
                                        }
                                        .padding(.leading, 15)
                                    }
                                }
                                
                                Text(library.queue.count == 0 ? "Empty" : "End of Queue").font(.callout)
                                    .frame(maxWidth: .infinity)
                                    .opacity(0.3)
                                    .padding(10)
                                    .padding([.bottom], 200)
                            }
                        }
                        .padding([.top], 3)
                    }
                }
                .padding(.top, self.appData.queueState == .isolated ? 20 : 0)
                
                Color.white.opacity(0.001)
                    .frame(width: dragWidth)
                    .ignoresSafeArea()
                    .offset(x:-queueWidth / 2, y:0)
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
            .frame(width: queueWidth)
            .onChange(of: NSApplication.shared.windows.first?.frame, { oldSize, newSize in
                if self.appData.queueState == .isolated {
                    queueWidth = newSize!.width
                }
            })
            .opacity(queueWidth < self.appData.appFormat.queueRestriction.width || queueWidth > self.appData.appFormat.queueRestriction.height ? 0.3 : 1)
            .onAppear() {
                NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) {
                    if itemDragging != nil {
                        mouseDelta.x = self.mouseLocation.x - lastMouseLocation.x
                        mouseDelta.y = self.mouseLocation.y - lastMouseLocation.y
                    }
                    lastMouseLocation = self.mouseLocation
                    mouseDeltaChanged()
                    return $0
                }
                
                musicProgressTracker.assign("QUEUE")
                
                queueWidth = self.appData.appFormat.queueWidth
            }
        }
    }
    
    private func queueItem(item: PlayableItem, queueWidth: CGFloat, visible: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if visible {
                content.listItem(height: 40, artwork: item.getArtwork(), mainTitle: item.getName(), subTitle: item.getArtistName())
                    .padding(10)
                
                appData.colorScheme.mainColor.colorInvert().opacity(0.15)
                    .frame(height: 1)
                    .padding([.leading], 60)
            }
        }.frame(width: queueWidth, alignment: .leading)
    }
    
    private func mouseDeltaChanged() {
        if !itemDragMoving {
            horizontalDragVal += mouseDelta.x * 2
            if horizontalDragVal > queueWidth { horizontalDragVal = queueWidth }
            else if horizontalDragVal < -queueWidth { horizontalDragVal = -queueWidth }
            
            if horizontalDragVal > (queueWidth / 5) * CGFloat(3) {
                itemDragRemoveReady = true
            }
            else if itemDragRemoveReady {
                itemDragRemoveReady = false
            }
            
            if horizontalDragVal < -(queueWidth / 5) * 3 {
                itemDragNextReady = true
            }
            else if itemDragNextReady {
                itemDragNextReady = false
            }
        }
        
        if !itemDragRemoveReady && !itemDragNextReady && abs(horizontalDragVal) < horizontalDragStep {
            verticalDragVal += mouseDelta.y
            
            if itemDragMoving {
                itemDropIndex = min(library.queue.count, max(0, initialMoveIndex - Int(floor(verticalDragVal / 60.0))))
            }
            
            if !itemDragMoving && abs(verticalDragVal) > 20 {
                itemDragMoving = true
                itemDropIndex = initialMoveIndex
            }
        }
    }
}

struct PressActions: ViewModifier {
    @State var pressed = false
    var onPress: () -> Void
    var onDrag: () -> Void = {}
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
                        onDrag()
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
