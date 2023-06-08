//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Pierre-Hugues Oger on 14/05/2023.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0 ) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay {
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(documentZoomScale)
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                }
                .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: tapToDeselectAllEmojis()))
                .overlay(alignment: .top) {
                    if !document.selectedEmojis.isEmpty {
                        trash
                    }
                }
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        ZStack {
                            Text(emoji.text)
                                .animatableSystemFont(size: fontSize(for: emoji) * documentZoomScale * (isSelected(emoji) ? gestureZoomScale : 1))
//                                .font(.system(size: fontSize(for: emoji) * documentZoomScale * (isSelected(emoji) ? gestureZoomScale : 1)))
                                .highlight(if: isSelected(emoji))
//                                .scaleEffect(documentZoomScale * (isSelected(emoji) ? gestureZoomScale : 1))
                                .position(position(for: emoji, in: geometry))
                                .gesture(tapToToggleSelection(of: emoji))
                        }
                        .gesture(selectionPanGesture(on: emoji))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
        }
    }
    
    var trash: some View {
        HStack {
            Spacer()
            Image(systemName: "trash")
                .foregroundColor(Color.red)
                .font(.system(size: 50))
                .gesture(tapToRemoveSelectedEmojis())
        }
        .padding()
    }
    
    private func tapToDeselectAllEmojis() -> some Gesture {
        TapGesture()
            .onEnded {
                document.deselectAllEmojis()
            }
    }
    
    private func tapToRemoveSelectedEmojis() -> some Gesture {
        TapGesture()
            .onEnded {
                document.removeSelectedEmojis()
            }
    }
    
    private func tapToToggleSelection(of emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture()
            .onEnded {
                document.toggleSelection(of: emoji)
            }
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
            
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / documentZoomScale
                    )
                }
            }
        }
        return found
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        var coordinates = convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
        if (isSelected(emoji) && unselectedEmojiBeingDragged == nil) || emoji == unselectedEmojiBeingDragged {
            coordinates += selectionGesturePanOffset
        }
        return coordinates
    }
    
    private func isSelected(_ emoji: EmojiArtModel.Emoji) -> Bool { document.selectedEmojis.contains(emoji) }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - documentPanOffset.width - center.x) / documentZoomScale,
            y: (location.y - documentPanOffset.height - center.y) / documentZoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * documentZoomScale + documentPanOffset.width,
            y: center.y + CGFloat(location.y) * documentZoomScale + documentPanOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    @State private var documentSteadyStatePanOffset = CGSize.zero
    @GestureState private var documentGesturePanOffset = CGSize.zero
    @GestureState private var selectionGesturePanOffset = CGSize.zero
    
    private var documentPanOffset: CGSize {
        (documentSteadyStatePanOffset + documentGesturePanOffset) * documentZoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($documentGesturePanOffset) { latestDragGestureValue, documentGesturePanOffset, _ in
                documentGesturePanOffset = latestDragGestureValue.translation / documentZoomScale
            }
            .onEnded { finalDragGestureValue in
                documentSteadyStatePanOffset += (finalDragGestureValue.translation / documentZoomScale)
            }
    }
    
    @State private var unselectedEmojiBeingDragged: EmojiArtModel.Emoji? = nil
    // TODO: Embed the @State into the @GestureState which become a Struct (CGSize + EmojiArtModel.Emoji?). Get rid of the DragGesture.onChanged .
    
    private func selectionPanGesture(on emoji: EmojiArtModel.Emoji) -> some Gesture {
        return DragGesture()
            .onChanged { _ in
                if !isSelected(emoji) {
                    unselectedEmojiBeingDragged = emoji
                }
            }
            .updating($selectionGesturePanOffset) { latestDragGestureValue, selectionGesturePanOffset, _ in
                selectionGesturePanOffset = latestDragGestureValue.translation / documentZoomScale
            }
            .onEnded { finalDragGestureValue in
                if isSelected(emoji) {
                    document.moveSelectedEmojis(by: finalDragGestureValue.translation / documentZoomScale)
                } else {
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation / documentZoomScale)
                    unselectedEmojiBeingDragged = nil
                }
            }
    }

    
    @State private var documentSteadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var documentZoomScale: CGFloat {
        documentSteadyStateZoomScale * (document.hasSelectedEmojis ? 1 : gestureZoomScale)
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
                
            }
            .onEnded { gestureScaleAtEnd in
                if document.hasSelectedEmojis {
                    document.scaleSelectedEmojis(by: gestureScaleAtEnd)
                }
                else {
                    documentSteadyStateZoomScale *= gestureScaleAtEnd
                }
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                } 
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            documentSteadyStatePanOffset = .zero
            documentSteadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "🤪🐗🦄🐸🏑🪭🎀🎉⏰ε🚀🏄🏽🫖🔥🌈"
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map(String.init) , id: \.self ) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
