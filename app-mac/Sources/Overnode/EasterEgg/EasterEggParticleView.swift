import AppKit
import Foundation
import SwiftUI

/// Représente un chat volant généré lors d'un clic utilisateur ou dans la pluie de chats.
public struct InteractiveCatParticle: Identifiable {
    public let id = UUID()
    public var position: CGPoint
    public var velocity: CGPoint
    public var rotation: Double
    public var rotationSpeed: Double
    public var scale: CGFloat
    public var opacity: Double
    public let imageIndex: Int
    public let createdAt: Date
}

/// Vue de fond affichant des lasers de boîte de nuit et une ambiance disco Overnode.
public struct DiscoLaserOverlayView: View {
    let currentTime: Double
    let beatPulse: CGFloat
    
    public init(currentTime: Double, beatPulse: CGFloat) {
        self.currentTime = currentTime
        self.beatPulse = beatPulse
    }
    
    public var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                
                // Centre lumineux
                let center = CGPoint(x: w / 2, y: h / 2)
                
                // Faisceaux laser tournants
                let beamCount = 12
                for i in 0..<beamCount {
                    let angle = (Double(i) * (.pi * 2.0 / Double(beamCount))) + (currentTime * 0.7)
                    let length = max(w, h) * 1.5
                    let endPoint = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * length,
                        y: center.y + CGFloat(sin(angle)) * length
                    )
                    
                    var path = Path()
                    path.move(to: center)
                    path.addLine(to: endPoint)
                    
                    let hue = (Double(i) / Double(beamCount) + currentTime * 0.1).truncatingRemainder(dividingBy: 1.0)
                    let color = Color(hue: hue, saturation: 0.85, brightness: 1.0).opacity(0.18 * Double(beatPulse))
                    
                    context.stroke(path, with: .color(color), lineWidth: 3.0 * beatPulse)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Anneau de satellites félins qui orbitent autour du chat central en phase Oiia Oiia.
public struct OrbitingCatSatellitesView: View {
    let currentTime: Double
    let radius: CGFloat
    let assetManager = EasterEggAssetManager.shared
    
    public init(currentTime: Double, radius: CGFloat = 260) {
        self.currentTime = currentTime
        self.radius = radius
    }
    
    public var body: some View {
        let count = 8
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = (Double(i) * (2 * .pi / Double(count))) - (currentTime * 2.5)
                let x = CGFloat(cos(angle)) * radius
                let y = CGFloat(sin(angle)) * radius
                let catIndex = (i % 12) + 1
                
                if let nsImg = assetManager.image(at: catIndex) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .rotationEffect(.degrees(currentTime * 360 + Double(i * 45)))
                        .offset(x: x, y: y)
                        .shadow(color: Color.pink.opacity(0.6), radius: 8)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Pluie de chats (effet Matrix félin) pendant les moments intenses.
public struct FallingCatsRainView: View {
    let currentTime: Double
    let assetManager = EasterEggAssetManager.shared
    
    public init(currentTime: Double) {
        self.currentTime = currentTime
    }
    
    public var body: some View {
        GeometryReader { geo in
            let cols = 9
            let colWidth = geo.size.width / CGFloat(cols)
            
            ZStack {
                ForEach(0..<cols, id: \.self) { col in
                    let speed = 120.0 + Double((col * 37) % 80)
                    let offsetPhase = Double(col * 53)
                    let y = CGFloat((currentTime * speed + offsetPhase).truncatingRemainder(dividingBy: Double(geo.size.height + 200))) - 100
                    let catIndex = (col % 12) + 1
                    
                    if let nsImg = assetManager.image(at: catIndex) {
                        Image(nsImage: nsImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .opacity(0.4)
                            .position(x: CGFloat(col) * colWidth + colWidth / 2, y: y)
                            .rotationEffect(.degrees(currentTime * 120 + Double(col * 30)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
