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
    ]
}
