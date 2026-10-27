import Foundation

enum Language: String, CaseIterable, Identifiable {
    case system, en, tr
    var id: String { rawValue }

    var resolved: Language {
        guard self == .system else { return self }
        let code = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        return code == "tr" ? .tr : .en
    }
}

enum S: CaseIterable {
    case connected, disconnected, refresh, battery, unreadable, usbConnected, onBattery
    case dpi, makeActive, hint, defaults, apply
    case searching, notFound, bluetooth, bluetoothShort, bluetoothDetail, readFailed, writeFailed, verifyFailed, saved
    case settings, language, systemLanguage, batteryRefresh, seconds, support, supportText
    case buyCoffee, about, version, source, done
    case tabMouse, tabButtons, tabScroll
    case accessTitle, accessDetail, accessButton
    case buttons, buttonsHint, middleButton, backButton, forwardButton
    case actionSystem, actionDisabled, recordShortcut, pressKeys, recordTitle, recordHint
    case groupNavigation, groupSystem, groupEdit, groupMedia
    case macros, noMacros, newMacro, editMacro, macroName, steps, stepsCount, noSteps
    case addKeys, addText, addDelay, textPlaceholder, ms, cancel, save, delete
    case scroll, smooth, smoothHint, reverse, reverseHint, speed, precise, preciseHint, scrollFooter
    case general, showMenuBar, menuBarPercent, showDock, launchAtLogin, backgroundHint
    case openApp, quit, activeStage
}

struct Strings {
    let lang: Language

    subscript(_ key: S) -> String {
        let t = Strings.table[key]!
        return lang.resolved == .tr ? t.1 : t.0
    }

    func status(_ s: Status) -> String {
        switch s {
        case .searching: return self[.searching]
        case .notFound: return self[.notFound]
        case .bluetooth: return self[.bluetooth]
        case .connected: return self[.connected]
        case .readFailed: return self[.readFailed]
        case .writeFailed: return self[.writeFailed]
        case .verifyFailed: return self[.verifyFailed]
        case .saved: return self[.saved]
        }
    }

    func button(_ b: MouseButton) -> String {
        switch b {
        case .middle: return self[.middleButton]
        case .back: return self[.backButton]
        case .forward: return self[.forwardButton]
        }
    }

    func group(_ g: Preset.Group) -> String {
        switch g {
        case .navigation: return self[.groupNavigation]
        case .system: return self[.groupSystem]
        case .edit: return self[.groupEdit]
        case .media: return self[.groupMedia]
        }
    }

    func preset(_ p: Preset) -> String {
        let t = Strings.presets[p]!
        return lang.resolved == .tr ? t.1 : t.0
    }

    func action(_ a: ButtonAction, macros: [Macro]) -> String {
        switch a {
        case .system: return self[.actionSystem]
        case .disabled: return self[.actionDisabled]
        case .preset(let p): return preset(p)
        case .shortcut(let c): return c.display
        case .macro(let id): return macros.first { $0.id == id }?.name ?? self[.actionSystem]
        }
    }

    private static let presets: [Preset: (String, String)] = [
        .back: ("Back", "Geri"),
        .forward: ("Forward", "İleri"),
        .nextTab: ("Next tab", "Sonraki sekme"),
        .previousTab: ("Previous tab", "Önceki sekme"),
        .middleClick: ("Middle click", "Orta tık"),
        .missionControl: ("Mission Control", "Mission Control"),
        .appExpose: ("App windows", "Uygulama pencereleri"),
        .showDesktop: ("Show desktop", "Masaüstünü göster"),
        .spotlight: ("Spotlight", "Spotlight"),
        .screenshot: ("Screenshot", "Ekran görüntüsü"),
        .copy: ("Copy", "Kopyala"),
        .paste: ("Paste", "Yapıştır"),
        .undo: ("Undo", "Geri al"),
        .redo: ("Redo", "Yinele"),
        .playPause: ("Play / Pause", "Oynat / Duraklat"),
        .nextTrack: ("Next track", "Sonraki parça"),
        .previousTrack: ("Previous track", "Önceki parça"),
        .volumeUp: ("Volume up", "Sesi aç"),
        .volumeDown: ("Volume down", "Sesi kıs"),
        .mute: ("Mute", "Sessiz"),
    ]

    private static let table: [S: (String, String)] = [
        .connected: ("Connected", "Bağlı"),
        .disconnected: ("Not connected", "Bağlı değil"),
        .refresh: ("Refresh", "Yenile"),
        .battery: ("Battery", "Pil"),
        .unreadable: ("Unavailable", "Okunamadı"),
        .usbConnected: ("USB connected", "USB bağlı"),
        .onBattery: ("On battery", "Pil ile çalışıyor"),
        .dpi: ("DPI", "DPI"),
        .makeActive: ("Make active stage", "Aktif aşama yap"),
        .hint: ("The filled circle is the active stage.", "Dolu daire aktif aşamadır."),
        .defaults: ("Defaults", "Varsayılan"),
        .apply: ("Apply", "Uygula"),
        .searching: ("Looking for the mouse…", "Mouse aranıyor…"),
        .notFound: ("Mouse not found. Check the cable or receiver.", "Mouse bulunamadı. Kabloyu veya alıcıyı kontrol et."),
        .bluetooth: ("Connected over Bluetooth", "Bluetooth ile bağlı"),
        .bluetoothShort: ("Bluetooth", "Bluetooth"),
        .bluetoothDetail: ("Over Bluetooth the mouse does not share its battery level or settings. Connect the USB cable or the 2.4 GHz receiver to change DPI. Settings are stored on the mouse itself.",
                           "Mouse, Bluetooth'ta pil seviyesini ve ayarlarını paylaşmıyor. DPI'ı değiştirmek için USB kabloyu veya 2.4 GHz alıcıyı tak. Ayarlar mouse'un kendisinde saklanır."),
        .readFailed: ("Could not read settings", "Ayarlar okunamadı"),
        .writeFailed: ("Write failed", "Yazma başarısız"),
        .verifyFailed: ("Could not verify", "Doğrulanamadı"),
        .saved: ("Saved to mouse", "Mouse'a kaydedildi"),
        .settings: ("Settings", "Ayarlar"),
        .language: ("Language", "Dil"),
        .systemLanguage: ("System", "Sistem"),
        .batteryRefresh: ("Battery refresh", "Pil yenileme"),
        .seconds: ("s", "sn"),
        .support: ("Support", "Destek"),
        .supportText: ("If this app is useful to you, you can support its development.", "Uygulama işine yaradıysa geliştirilmesine destek olabilirsin."),
        .buyCoffee: ("Buy me a coffee", "Bana bir kahve ısmarla"),
        .about: ("About", "Hakkında"),
        .version: ("Version", "Sürüm"),
        .source: ("Source code", "Kaynak kod"),
        .done: ("Done", "Tamam"),
        .tabMouse: ("Mouse", "Mouse"),
        .tabButtons: ("Buttons & Macros", "Tuşlar ve Makrolar"),
        .tabScroll: ("Scrolling", "Kaydırma"),
        .accessTitle: ("Accessibility permission needed", "Erişilebilirlik izni gerekli"),
        .accessDetail: ("Button actions, macros and scrolling need Accessibility access. Turn on AJ139 Driver in System Settings › Privacy & Security › Accessibility. If it is already on and this message stays, remove AJ139 Driver from the list with − and add it again.",
                        "Tuş atamaları, makrolar ve kaydırma için Erişilebilirlik izni gerekir. Sistem Ayarları › Gizlilik ve Güvenlik › Erişilebilirlik bölümünde AJ139 Driver'ı aç. Zaten açıksa ve bu uyarı kaybolmuyorsa AJ139 Driver'ı listeden − ile kaldırıp yeniden ekle."),
        .accessButton: ("Open System Settings", "Sistem Ayarları'nı aç"),
        .buttons: ("Buttons", "Tuşlar"),
        .buttonsHint: ("Works over USB, 2.4 GHz and Bluetooth. Left and right buttons are never changed.",
                       "USB, 2.4 GHz ve Bluetooth'ta çalışır. Sol ve sağ tuş hiçbir zaman değiştirilmez."),
        .middleButton: ("Middle button", "Orta tuş"),
        .backButton: ("Back side button", "Geri yan tuşu"),
        .forwardButton: ("Forward side button", "İleri yan tuşu"),
        .actionSystem: ("Default", "Varsayılan"),
        .actionDisabled: ("Disabled", "Devre dışı"),
        .recordShortcut: ("Keyboard shortcut…", "Klavye kısayolu…"),
        .pressKeys: ("Press keys…", "Tuşlara bas…"),
        .recordTitle: ("Keyboard shortcut", "Klavye kısayolu"),
        .recordHint: ("Click the field and press the key combination. Esc cancels.",
                      "Alana tıkla ve tuş kombinasyonuna bas. Esc iptal eder."),
        .groupNavigation: ("Navigation", "Gezinme"),
        .groupSystem: ("System", "Sistem"),
        .groupEdit: ("Edit", "Düzenle"),
        .groupMedia: ("Media", "Medya"),
        .macros: ("Macros", "Makrolar"),
        .noMacros: ("No macros yet. A macro plays shortcuts, text and pauses in order.",
                    "Henüz makro yok. Makro; kısayolları, metni ve beklemeleri sırayla çalıştırır."),
        .newMacro: ("New macro", "Yeni makro"),
        .editMacro: ("Macro", "Makro"),
        .macroName: ("Name", "Ad"),
        .steps: ("Steps", "Adımlar"),
        .stepsCount: ("steps", "adım"),
        .noSteps: ("Add a step below.", "Aşağıdan bir adım ekle."),
        .addKeys: ("Shortcut", "Kısayol"),
        .addText: ("Text", "Metin"),
        .addDelay: ("Pause", "Bekleme"),
        .textPlaceholder: ("Text to type", "Yazılacak metin"),
        .ms: ("ms", "ms"),
        .cancel: ("Cancel", "İptal"),
        .save: ("Save", "Kaydet"),
        .delete: ("Delete", "Sil"),
        .scroll: ("Scrolling", "Kaydırma"),
        .smooth: ("Smooth scrolling", "Yumuşak kaydırma"),
        .smoothHint: ("Turns each wheel step into a smooth, accelerated scroll.",
                      "Her tekerlek adımını yumuşak ve hızlanan bir kaydırmaya çevirir."),
        .reverse: ("Reverse scroll direction", "Kaydırma yönünü ters çevir"),
        .reverseHint: ("Only the mouse wheel is reversed. The trackpad keeps its own direction.",
                       "Yalnızca mouse tekerleği ters döner. Trackpad kendi yönünde kalır."),
        .speed: ("Speed", "Hız"),
        .precise: ("Precise scrolling with ⌥", "⌥ ile hassas kaydırma"),
        .preciseHint: ("Hold Option while scrolling to move slowly.", "Yavaş kaydırmak için kaydırırken Option tuşunu basılı tut."),
        .scrollFooter: ("Applies to mouse wheels only. Trackpads and Magic Mouse are not affected.",
                        "Yalnızca mouse tekerleklerini etkiler. Trackpad ve Magic Mouse etkilenmez."),
        .general: ("General", "Genel"),
        .showMenuBar: ("Show in menu bar", "Menü çubuğunda göster"),
        .menuBarPercent: ("Battery percentage in menu bar", "Menü çubuğunda pil yüzdesi"),
        .showDock: ("Show Dock icon", "Dock simgesini göster"),
        .launchAtLogin: ("Open at login", "Oturum açılınca başlat"),
        .backgroundHint: ("Closing the window keeps the app running in the background, so buttons and scrolling keep working.",
                          "Pencereyi kapatınca uygulama arka planda çalışmaya devam eder, tuşlar ve kaydırma çalışmayı sürdürür."),
        .openApp: ("Open AJ139 Driver", "AJ139 Driver'ı aç"),
        .quit: ("Quit", "Çık"),
        .activeStage: ("DPI stage", "DPI aşaması"),
    ]
}
