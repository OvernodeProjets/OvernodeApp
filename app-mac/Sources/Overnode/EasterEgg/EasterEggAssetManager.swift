import AppKit
import Foundation
import SwiftUI

/// Gère le chargement, la résolution et la mise en cache des assets pour l'Easter Egg félin.
@MainActor
public final class EasterEggAssetManager {
    public static let shared = EasterEggAssetManager()
    
    private var cachedImages: [Int: NSImage] = [:]
    private var cachedAudioURL: URL?
    private let totalImageCount = 12
    
    private init() {
        preloadImages()
    }
    
    // MARK: - Images Cache & Access
    
    public func preloadImages() {
        for index in 1...totalImageCount {
            if let image = loadImage(index: index) {
                cachedImages[index] = image
            }
        }
    }
    
    public func image(at index: Int) -> NSImage? {
        if let cached = cachedImages[index] {
            return cached
        }
        if let loaded = loadImage(index: index) {
            cachedImages[index] = loaded
            return loaded
        }
        return nil
    }
    
    public var allImages: [NSImage] {
        (1...totalImageCount).compactMap { image(at: $0) }
    }
    
    // Raccourcis sémantiques pour les poses du chat
    public var catJudge: NSImage? { image(at: 1) }        // Gros plan regard noir / jugement
    public var catLoaf: NSImage? { image(at: 2) }         // Pain de mie / loaf classique
    public var catHandsome: NSImage? { image(at: 3) }     // Couché pose détendue patte avant
    public var catOverhead: NSImage? { image(at: 4) }     // Vue du dessus avec queue trèfle
    public var catExtremeZoom: NSImage? { image(at: 5) }  // Macro nez / yeux perçants
    public var catBellyUp: NSImage? { image(at: 6) }      // Ventre en l'air / breakdance
    public var catLongPaws: NSImage? { image(at: 7) }     // Pattes allongées / moonwalk
    public var catKingChill: NSImage? { image(at: 8) }    // Majestueux dans la pénombre
    public var catStatue: NSImage? { image(at: 9) }       // Assis bien droit comme un sphinx
    public var catSidePeek: NSImage? { image(at: 10) }    // Tête large regard de côté
    public var catTilted: NSImage? { image(at: 11) }      // Tête penchée curieuse / mignonne
    public var catGrassSleep: NSImage? { image(at: 12) }  // Sieste paisible dans l'herbe
    
    // MARK: - Audio Resolution
    
    public var audioURL: URL? {
        if let cached = cachedAudioURL {
            return cached
        }
        if let url = resolveFileURL(named: "cat_audio", ext: "mp3") {
            cachedAudioURL = url
            return url
        }
        // Fallback direct vers le dossier de téléchargement utilisateur
        let dlCandidate = URL(fileURLWithPath: "/Users/matheus/Downloads/Dancing Rat x OIIA Cat.mp3")
        if FileManager.default.fileExists(atPath: dlCandidate.path) {
            cachedAudioURL = dlCandidate
            return dlCandidate
        }
        return nil
    }
    
    // MARK: - Private File Resolvers
    
    private func loadImage(index: Int) -> NSImage? {
        let name = String(format: "cat_%02d", index)
        if let url = resolveFileURL(named: name, ext: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return nil
    }
    
    private func resolveFileURL(named name: String, ext: String) -> URL? {
        // 1. Bundle principal sous sous-dossier EasterEgg
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "EasterEgg") {
            return url
        }
        
        // 2. Bundle principal racine
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        
        // 3. Dossier de ressources de l'application
        if let resourceURL = Bundle.main.resourceURL {
            let candidates = [
                resourceURL.appendingPathComponent("EasterEgg/\(name).\(ext)"),
                resourceURL.appendingPathComponent("Overnode_Overnode.bundle/EasterEgg/\(name).\(ext)"),
                resourceURL.appendingPathComponent("\(name).\(ext)")
            ]
            for cand in candidates {
                if FileManager.default.fileExists(atPath: cand.path) {
                    return cand
                }
            }
        }
        
        // 4. Dossier de développement Sources/Overnode/Resources/EasterEgg
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let devURL = currentDir.appendingPathComponent("Sources/Overnode/Resources/EasterEgg/\(name).\(ext)")
        if FileManager.default.fileExists(atPath: devURL.path) {
            return devURL
        }
        
        // 5. Recherche relative au bundle exécutable
        let execURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/EasterEgg/\(name).\(ext)")
        if FileManager.default.fileExists(atPath: execURL.path) {
            return execURL
        }
        
        return nil
    }
}
