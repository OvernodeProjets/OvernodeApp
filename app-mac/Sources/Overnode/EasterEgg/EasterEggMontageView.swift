import AppKit
import Foundation
import SwiftUI

/// Fenêtre / Overlay immersif de l'Easter Egg "Dancing Rat x OIIA Cat".
public struct EasterEggMontageView: View {
    @Binding var isPresented: Bool
    @StateObject private var audioPlayer = EasterEggAudioPlayer.shared
    @ObservedObject var loc = LocalizationManager.shared
    private let assetManager = EasterEggAssetManager.shared
    
    @State private var spawnedParticles: [InteractiveCatParticle] = []
    @State private var clickCount: Int = 0
    @State private var showMemeBadge: Bool = true
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fond immersif avec dégradé Overnode et rotation de teinte disco
                backgroundLayer
                
                // Lasers disco en arrière-plan
                DiscoLaserOverlayView(currentTime: audioPlayer.currentTime, beatPulse: audioPlayer.beatPulse)
                
                // Pluie de chats en phase Oiia Spin et Disco Chaos
                if audioPlayer.currentPhase == .oiiaSpin || audioPlayer.currentPhase == .discoChaos {
                    FallingCatsRainView(currentTime: audioPlayer.currentTime)
                }
                
                // Montage central selon la phase musicale
                VStack(spacing: 0) {
                    topControlBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    
                    Spacer()
                    
                    stageContent(size: geo.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                    
                    bottomTimelineBar
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
                
                // Particules générées par les clics utilisateurs
                interactiveParticlesLayer
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                spawnInteractiveCat(at: location)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            if audioPlayer.currentTime == 0 {
                audioPlayer.restart()
            } else {
                audioPlayer.play()
            }
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
    
    // MARK: - Background Layer
    
    private var backgroundLayer: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(red: 0.15, green: 0.10, blue: 0.25),
                Color(red: 0.05, green: 0.05, blue: 0.08)
            ]),
            center: .center,
            startRadius: 50,
            endRadius: 800
        )
        .hueRotation(.degrees(audioPlayer.currentTime * 45))
        .overlay(
            // Flash stroboscopique sur le temps fort
            Color.white
                .opacity(audioPlayer.beatPulse > 1.18 ? 0.08 : 0.0)
                .animation(.easeOut(duration: 0.1), value: audioPlayer.beatPulse)
        )
    }
    
    // MARK: - Top Control Bar
    
    private var topControlBar: some View {
        HStack(spacing: 16) {
            // Visualiseur audio en temps réel
            HStack(spacing: 3) {
                ForEach(0..<audioPlayer.visualizerBars.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [Color.pink, Color.yellow, Color.cyan],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: 4, height: max(6, audioPlayer.visualizerBars[i] * 28))
                }
            }
            .frame(height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("🐱 DANCING RAT x OIIA CAT")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                Text(audioPlayer.currentPhase.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(OvernodeTheme.accentGold)
            }
            
            Spacer()
            
            // Badge Chats Invoqués
            if clickCount > 0 {
                HStack(spacing: 6) {
                    Text("🐾")
                    Text(String(format: loc.string("easteregg_summoned_count"), clickCount))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .cornerRadius(20)
                .transition(.scale)
            }
            
            // Bouton Quitter
            Button(action: {
                audioPlayer.stop()
                isPresented = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                    Text(loc.string("easteregg_quit_btn"))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.8))
                .cornerRadius(10)
                .shadow(color: Color.red.opacity(0.4), radius: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.black.opacity(0.45))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Montage Stage Content
    
    @ViewBuilder
    private func stageContent(size: CGSize) -> some View {
        switch audioPlayer.currentPhase {
        case .intro:
            introStage(size: size)
        case .dancing:
            dancingStage(size: size)
        case .oiiaSpin:
            oiiaSpinStage(size: size)
        case .discoChaos:
            discoChaosStage(size: size)
        case .finished:
            victoryStage(size: size)
        }
    }
    
    // Phase 1 : Intro majestueuse avec Loaf Cosmique
    private func introStage(size: CGSize) -> some View {
        VStack(spacing: 20) {
            ZStack {
                // Halo doré rotatif
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.yellow, .orange, .pink, .purple, .yellow]),
                            center: .center
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 40)
                    .opacity(0.45)
                    .rotationEffect(.degrees(audioPlayer.currentTime * 30))
                
                // Couronne flottante au-dessus du chat
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(OvernodeTheme.accentGold)
                    .offset(y: -150 + sin(audioPlayer.currentTime * 4) * 10)
                    .shadow(color: .yellow, radius: 10)
                
                // Chat Loaf
                if let loaf = assetManager.catLoaf {
                    Image(nsImage: loaf)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .scaleEffect(audioPlayer.beatPulse)
                        .shadow(color: .black.opacity(0.6), radius: 20)
                }
            }
            
            VStack(spacing: 8) {
                Text(loc.string("easteregg_intro_banner"))
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .shadow(color: .yellow, radius: 8)
                
                Text(loc.string("easteregg_intro_hint"))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // Phase 2 : Dancing Rat Groove
    private func dancingStage(size: CGSize) -> some View {
        VStack(spacing: 24) {
            HStack(spacing: 36) {
                // Danseur Gauche : Regard jugeant qui hoche la tête
                VStack {
                    if let judge = assetManager.catJudge {
                        Image(nsImage: judge)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(sin(audioPlayer.currentTime * 14) * 22))
                            .scaleEffect(audioPlayer.beatPulse)
                    }
                    Text(loc.string("easteregg_dancer_judge"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
                
                // Danseur Centre : Ventre en l'air qui breakdance
                VStack {
                    if let belly = assetManager.catBellyUp {
                        Image(nsImage: belly)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 260)
                            .rotationEffect(.degrees(sin(audioPlayer.currentTime * 8) * 35))
                            .scaleEffect(audioPlayer.beatPulse * 1.1)
                            .shadow(color: .cyan.opacity(0.6), radius: 15)
                    }
                    Text(loc.string("easteregg_dancer_breakdancer"))
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.cyan)
                }
                
                // Danseur Droite : Longues pattes qui moonwalk
                VStack {
                    if let paws = assetManager.catLongPaws {
                        Image(nsImage: paws)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(-sin(audioPlayer.currentTime * 14) * 22))
                            .offset(x: sin(audioPlayer.currentTime * 6) * 25)
                            .scaleEffect(audioPlayer.beatPulse)
                    }
                    Text(loc.string("easteregg_dancer_velvet_paw"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(OvernodeTheme.accentGold)
                }
            }
            
            // Bannière hilarante avec punchlines changeantes
            memeTickerView
        }
    }
    
    // Phase 3 : Oiia Oiia Turbo Spin
    private func oiiaSpinStage(size: CGSize) -> some View {
        ZStack {
            // Anneau de satellites orbitaux
            OrbitingCatSatellitesView(currentTime: audioPlayer.currentTime, radius: 240)
            
            // Chat central en rotation supersonique
            VStack(spacing: 16) {
                if let spinCat = assetManager.catExtremeZoom ?? assetManager.catLoaf {
                    Image(nsImage: spinCat)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees((audioPlayer.currentTime - 28.0) * 600))
                        .scaleEffect(audioPlayer.beatPulse * 1.15)
                        .shadow(color: .pink.opacity(0.8), radius: 25)
                }
                
                Text("🌀 OIIA OIIA OIIA OIIA 🌀")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .pink, radius: 10)
                    .scaleEffect(audioPlayer.beatPulse)
            }
        }
    }
    
    // Phase 4 : Chaos Disco Total
    private func discoChaosStage(size: CGSize) -> some View {
        VStack(spacing: 16) {
            // Galerie des 4 coins + chat central changeant à chaque beat
            HStack(spacing: 20) {
                // Coin 1
                if let img = assetManager.catStatue {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(sin(audioPlayer.currentTime * 10) * 25))
                }
                
                Spacer()
                
                // Centre : Pose changeante chaque beat (effet montage rapide)
                let currentBeatImageIndex = (audioPlayer.beatCount % 12) + 1
                if let activeCat = assetManager.image(at: currentBeatImageIndex) {
                    Image(nsImage: activeCat)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 290, height: 290)
                        .scaleEffect(audioPlayer.beatPulse * 1.12)
                        .rotationEffect(.degrees(Double((audioPlayer.beatCount % 4) - 2) * 8))
                        .shadow(color: .yellow, radius: 20)
                }
                
                Spacer()
                
                // Coin 2
                if let img = assetManager.catTilted {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-sin(audioPlayer.currentTime * 10) * 25))
                }
            }
            .padding(.horizontal, 40)
            
            Text(loc.string("easteregg_chaos_banner"))
                .font(.system(size: 24, weight: .black))
                .foregroundColor(OvernodeTheme.accentGold)
                .shadow(color: .orange, radius: 10)
                .scaleEffect(audioPlayer.beatPulse)
            
            HStack(spacing: 16) {
                badgePill(text: loc.string("easteregg_badge_lag_purr"))
                badgePill(text: loc.string("easteregg_badge_salmon"))
                badgePill(text: loc.string("easteregg_badge_silicon"))
            }
        }
    }
    
    // Phase 5 : Célébration finale / Victoire
    private func victoryStage(size: CGSize) -> some View {
        VStack(spacing: 24) {
            Text(loc.string("easteregg_victory_title"))
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .shadow(color: OvernodeTheme.accentGold, radius: 15)
            
            if let cat = assetManager.catHandsome ?? assetManager.catLoaf {
                Image(nsImage: cat)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .shadow(color: .yellow.opacity(0.8), radius: 20)
            }
            
            Text(loc.string("easteregg_victory_desc"))
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 16) {
                Button(action: {
                    audioPlayer.restart()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text(loc.string("easteregg_restart_btn"))
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(OvernodeTheme.accentGold)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    audioPlayer.stop()
                    isPresented = false
                }) {
                    Text(loc.string("easteregg_back_settings_btn"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(OvernodeTheme.accentGold.opacity(0.5), lineWidth: 2)
        )
    }
    
    // MARK: - Bottom Timeline Bar
    
    private var bottomTimelineBar: some View {
        VStack(spacing: 8) {
            // Ligne de progression avec tête de chat qui avance
            GeometryReader { pGeo in
                let progress = min(1.0, max(0.0, audioPlayer.currentTime / max(1.0, audioPlayer.duration)))
                let catX = CGFloat(progress) * pGeo.size.width
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color.pink, Color.yellow, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(6, catX), height: 6)
                    
                    // Curseur tête de chat
                    Text("🐱")
                        .font(.system(size: 20))
                        .offset(x: max(0, catX - 10), y: -1)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text(formatTime(audioPlayer.currentTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { audioPlayer.toggle() }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        // Spawne 5 chats au centre
                        for _ in 0..<5 {
                            spawnInteractiveCat(at: CGPoint(x: 400 + Double.random(in: -100...100), y: 300 + Double.random(in: -100...100)))
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("🐾")
                            Text(loc.string("easteregg_meow_btn"))
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Text(formatTime(audioPlayer.duration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.45))
        .cornerRadius(16)
    }
    
    // MARK: - Interactive Spawning Layer
    
    private var interactiveParticlesLayer: some View {
        ZStack {
            ForEach(spawnedParticles) { p in
                if let img = assetManager.image(at: p.imageIndex) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80 * p.scale, height: 80 * p.scale)
                        .rotationEffect(.degrees(p.rotation))
                        .opacity(p.opacity)
                        .position(p.position)
                        .shadow(color: .yellow.opacity(0.6), radius: 8)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func spawnInteractiveCat(at point: CGPoint) {
        clickCount += 1
        let randomImg = Int.random(in: 1...12)
        let particle = InteractiveCatParticle(
            position: point,
            velocity: CGPoint(x: CGFloat.random(in: -40...40), y: CGFloat.random(in: -80 ... -20)),
            rotation: Double.random(in: -30...30),
            rotationSpeed: Double.random(in: -180...180),
            scale: CGFloat.random(in: 0.8...1.3),
            opacity: 1.0,
            imageIndex: randomImg,
            createdAt: Date()
        )
        spawnedParticles.append(particle)
        
        // Nettoyage après 1.8s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if let idx = spawnedParticles.firstIndex(where: { $0.id == particle.id }) {
                spawnedParticles.remove(at: idx)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var memeTickerView: some View {
        let quotes = [
            loc.string("easteregg_quote_1"),
            loc.string("easteregg_quote_2"),
            loc.string("easteregg_quote_3"),
            loc.string("easteregg_quote_4")
        ]
        let currentQuote = quotes[Int(audioPlayer.currentTime / 3.5) % quotes.count]
        
        return Text(currentQuote)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
            .cornerRadius(20)
            .overlay(
                Capsule().stroke(OvernodeTheme.accentGold.opacity(0.6), lineWidth: 1)
            )
            .transition(.opacity)
    }
    
    private func badgePill(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.12))
            .cornerRadius(8)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
