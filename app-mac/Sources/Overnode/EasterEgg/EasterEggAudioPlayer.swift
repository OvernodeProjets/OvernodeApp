import AVFoundation
import Combine
import Foundation
import SwiftUI

/// Phase chronologique du montage de l'Easter Egg (durée totale : ~64.6s).
public enum EasterEggPhase: String, CaseIterable, Sendable {
    case intro      // 00.0s - 14.0s : L'éveil du chat suprême (Loaf cosmique, lasers lents)
    case dancing    // 14.0s - 28.0s : Dancing Rat groove (bobbing heads, breakdance félin)
    case oiiaSpin   // 28.0s - 45.0s : Oiia Oiia Turbo (rotation centrifuge, satellites orbitaux)
    case discoChaos // 45.0s - 64.6s : Chaos Disco Total (12 chats en folie, stroboscope)
    case finished   // 64.6s+        : Célébration finale / Victoire

    @MainActor
    public var title: String {
        switch self {
        case .intro: return LocalizationManager.shared.string("easteregg_phase_intro_title")
        case .dancing: return LocalizationManager.shared.string("easteregg_phase_dancing_title")
        case .oiiaSpin: return LocalizationManager.shared.string("easteregg_phase_oiia_title")
        case .discoChaos: return LocalizationManager.shared.string("easteregg_phase_chaos_title")
        case .finished: return LocalizationManager.shared.string("easteregg_phase_finished_title")
        }
    }
    
    @MainActor
    public var subtitle: String {
        switch self {
        case .intro: return LocalizationManager.shared.string("easteregg_phase_intro_sub")
        case .dancing: return LocalizationManager.shared.string("easteregg_phase_dancing_sub")
        case .oiiaSpin: return LocalizationManager.shared.string("easteregg_phase_oiia_sub")
        case .discoChaos: return LocalizationManager.shared.string("easteregg_phase_chaos_sub")
        case .finished: return LocalizationManager.shared.string("easteregg_phase_finished_sub")
        }
    }
}

/// Lecteur audio et métronome synchronisé pour le morceau "Dancing Rat x OIIA Cat".
@MainActor
public final class EasterEggAudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    public static let shared = EasterEggAudioPlayer()
    
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var currentTime: Double = 0.0
    @Published public private(set) var duration: Double = 64.60
    @Published public private(set) var currentPhase: EasterEggPhase = .intro
    @Published public private(set) var beatPulse: CGFloat = 1.0
    @Published public private(set) var beatCount: Int = 0
    @Published public private(set) var visualizerBars: [CGFloat] = Array(repeating: 0.2, count: 16)
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private let bpm: Double = 137.0
    private var beatInterval: Double { 60.0 / bpm }
    
    public override init() {
        super.init()
        prepareAudio()
    }
    
    // MARK: - Setup
    
    public func prepareAudio() {
        guard let url = EasterEggAssetManager.shared.audioURL else {
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.prepareToPlay()
            self.player = p
            if p.duration > 0 {
                self.duration = p.duration
            }
        } catch {
            print("[EasterEgg] Failed to initialize AVAudioPlayer: \(error)")
        }
    }
    
    // MARK: - Controls
    
    public func play() {
        if player == nil {
            prepareAudio()
        }
        guard let p = player else { return }
        
        if !isPlaying {
            p.currentTime = currentTime
            p.play()
            isPlaying = true
            startTimer()
        }
    }
    
    public func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }
    
    public func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTime = 0
        isPlaying = false
        currentPhase = .intro
        beatPulse = 1.0
        stopTimer()
    }
    
    public func restart() {
        stop()
        play()
    }
    
    public func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    public func seek(to time: Double) {
        let clamped = max(0.0, min(duration, time))
        self.currentTime = clamped
        player?.currentTime = clamped
        updatePlaybackState()
    }
    
    // MARK: - Timer & Sync Engine
    
    private func startTimer() {
        stopTimer()
        // Rafraîchissement régulier à ~60Hz pour des animations ultra fluides
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePlaybackState()
            }
        }
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updatePlaybackState() {
        guard let p = player, isPlaying else { return }
        
        let t = p.currentTime
        self.currentTime = t
        
        // Calcul de la phase courante
        if t < 14.0 {
            self.currentPhase = .intro
        } else if t < 28.0 {
            self.currentPhase = .dancing
        } else if t < 45.0 {
            self.currentPhase = .oiiaSpin
        } else if t < self.duration {
            self.currentPhase = .discoChaos
        } else {
            self.currentPhase = .finished
        }
        
        // Calcul du pulse du métronome à 137 BPM
        let phaseInBeat = (t.truncatingRemainder(dividingBy: beatInterval)) / beatInterval
        // Attaque percutante et décroissance exponentielle
        let attackDecay = max(0.0, 1.0 - phaseInBeat * 3.0)
        self.beatPulse = 1.0 + CGFloat(attackDecay * 0.22)
        self.beatCount = Int(t / beatInterval)
        
        // Animation des barres de l'égaliseur / visualiseur
        var bars: [CGFloat] = []
        for i in 0..<16 {
            let offset = Double(i) * 0.4
            let wave = sin(t * 12.0 + offset) * 0.4 + 0.5
            let pulseFactor = (attackDecay > 0.1) ? 0.3 : 0.0
            let height = CGFloat(min(1.0, max(0.15, wave + pulseFactor)))
            bars.append(height)
        }
        self.visualizerBars = bars
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentPhase = .finished
            self.stopTimer()
        }
    }
}
