import AppKit
import XCTest
@testable import Overnode

final class EasterEggTests: XCTestCase {
    
    @MainActor
    func testEasterEggAssetsPreloadedAndAvailable() {
        let manager = EasterEggAssetManager.shared
        manager.preloadImages()
        
        let allImages = manager.allImages
        XCTAssertEqual(allImages.count, 12, "Les 12 images de chat doivent être chargées")
        
        // Vérification des poses spécifiques
        XCTAssertNotNil(manager.catJudge, "catJudge doit être présent")
        XCTAssertNotNil(manager.catLoaf, "catLoaf doit être présent")
        XCTAssertNotNil(manager.catHandsome, "catHandsome doit être présent")
        XCTAssertNotNil(manager.catOverhead, "catOverhead doit être présent")
        XCTAssertNotNil(manager.catExtremeZoom, "catExtremeZoom doit être présent")
        XCTAssertNotNil(manager.catBellyUp, "catBellyUp doit être présent")
        XCTAssertNotNil(manager.catLongPaws, "catLongPaws doit être présent")
        XCTAssertNotNil(manager.catKingChill, "catKingChill doit être présent")
        XCTAssertNotNil(manager.catStatue, "catStatue doit être présent")
        XCTAssertNotNil(manager.catSidePeek, "catSidePeek doit être présent")
        XCTAssertNotNil(manager.catTilted, "catTilted doit être présent")
        XCTAssertNotNil(manager.catGrassSleep, "catGrassSleep doit être présent")
        
        // Vérification des dimensions
        for (i, img) in allImages.enumerated() {
            XCTAssertGreaterThan(img.size.width, 0, "L'image \(i + 1) doit avoir une largeur valide")
            XCTAssertGreaterThan(img.size.height, 0, "L'image \(i + 1) doit avoir une hauteur valide")
        }
    }
    
    @MainActor
    func testExcludedImageNotPresent() {
        let excludedName = "5242E2B2-7A35-4A75-B865-D381C8A47636_1_105_c"
        let resourcesURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/Overnode/Resources/EasterEgg")
        let excludedFile = resourcesURL.appendingPathComponent("\(excludedName).jpeg")
        XCTAssertFalse(FileManager.default.fileExists(atPath: excludedFile.path), "L'image 5242E2B2... ne doit pas être incluse dans le projet")
    }
    
    @MainActor
    func testEasterEggAudioResolutionAndProperties() {
        let manager = EasterEggAssetManager.shared
        let audioURL = manager.audioURL
        XCTAssertNotNil(audioURL, "L'URL du fichier audio doit être résolue")
        
        let player = EasterEggAudioPlayer.shared
        player.prepareAudio()
        XCTAssertGreaterThan(player.duration, 60.0, "La durée audio doit être supérieure à 60s (~64.6s)")
        XCTAssertLessThan(player.duration, 70.0, "La durée audio ne doit pas dépasser 70s")
    }
    
    @MainActor
    func testEasterEggPhasesTiming() {
        let phases = EasterEggPhase.allCases
        XCTAssertEqual(phases.count, 5, "Il doit y avoir 5 phases distinctes")
        
        XCTAssertEqual(EasterEggPhase.intro.rawValue, "intro")
        XCTAssertEqual(EasterEggPhase.dancing.rawValue, "dancing")
        XCTAssertEqual(EasterEggPhase.oiiaSpin.rawValue, "oiiaSpin")
        XCTAssertEqual(EasterEggPhase.discoChaos.rawValue, "discoChaos")
        XCTAssertEqual(EasterEggPhase.finished.rawValue, "finished")
        
        // Vérification des titres
        for phase in phases {
            XCTAssertFalse(phase.title.isEmpty, "Le titre de la phase \(phase) ne doit pas être vide")
            XCTAssertFalse(phase.subtitle.isEmpty, "Le sous-titre de la phase \(phase) ne doit pas être vide")
        }
    }
    
    @MainActor
    func testEasterEggAudioPlayerControls() {
        let player = EasterEggAudioPlayer.shared
        player.stop()
        XCTAssertFalse(player.isPlaying, "Le lecteur doit être arrêté initialement")
        XCTAssertEqual(player.currentTime, 0.0, "Le temps de lecture doit être remis à 0")
        XCTAssertEqual(player.currentPhase, .intro, "La phase initiale doit être .intro")
    }
    
    @MainActor
    func testEasterEggLocalizationActiveSwitch() {
        let loc = LocalizationManager.shared
        
        // Tester en français
        loc.setLanguage(.french)
        XCTAssertEqual(loc.currentLanguage, .french)
        XCTAssertEqual(EasterEggPhase.intro.title, "👑 L'ÉVEIL DU CHAT OVERNODE")
        XCTAssertEqual(loc.string("easteregg_quit_btn"), "Quitter (Échap)")
        XCTAssertEqual(loc.string("easteregg_meow_btn"), "Miaou !")
        XCTAssertEqual(loc.string("easteregg_quote_2"), "Serveurs Overnode propulsés par 12 chats surpuissants")
        
        // Basculer activement en anglais
        loc.setLanguage(.english)
        XCTAssertEqual(loc.currentLanguage, .english)
        XCTAssertEqual(EasterEggPhase.intro.title, "👑 THE OVERNODE CAT AWAKENS")
        XCTAssertEqual(loc.string("easteregg_quit_btn"), "Exit (Esc)")
        XCTAssertEqual(loc.string("easteregg_meow_btn"), "Meow!")
        XCTAssertEqual(loc.string("easteregg_quote_2"), "Overnode servers powered by 12 overpowered cats")
        
        // Rebasculer en français pour l'état par défaut
        loc.setLanguage(.french)
        XCTAssertEqual(loc.currentLanguage, .french)
    }
}
