//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Pierre-Hugues Oger on 14/05/2023.
//

import Foundation

struct EmojiArtModel: Codable {
    var background = Background.blank
    var emojis = [Emoji]()
        
    struct Emoji: Identifiable, Hashable, Codable {
        let text: String
        var x: Int  // offset from the center
        var y: Int  // offset from the center
        var size: Int
        let id: Int
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try EmojiArtModel(json: data)
    }
    
    init() { }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
    
    mutating func remove(_ emoji: Emoji) {
        guard let index = emojis.index(matching: emoji) else { return }
        emojis.remove(at: index)
    }
    
    mutating func move(_ emoji: Emoji, by offset: CGSize) {
        if let index = emojis.index(matching: emoji) {
            emojis[index].x += Int(offset.width)
            emojis[index].y += Int(offset.height)
        }
    }
    
    mutating func scale(_ emoji: Emoji, by scale: CGFloat) {
        if let index = emojis.index(matching: emoji) {        
            emojis[index].size = Int((CGFloat(emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}
