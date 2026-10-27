import Foundation

struct KeyCombo: Codable, Hashable {
    var keyCode: UInt16
    var modifiers: UInt64
    var key: String

    static let command: UInt64 = 0x100000
    static let shift: UInt64 = 0x20000
    static let control: UInt64 = 0x40000
    static let option: UInt64 = 0x80000
    static let mask = command | shift | control | option

    static let specialKeys: [UInt16: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 117: "⌦",
        123: "←", 124: "→", 125: "↓", 126: "↑", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    var display: String {
        var s = ""
        if modifiers & Self.control != 0 { s += "⌃" }
        if modifiers & Self.option != 0 { s += "⌥" }
        if modifiers & Self.shift != 0 { s += "⇧" }
        if modifiers & Self.command != 0 { s += "⌘" }
        return s + key
    }
}

struct MacroStep: Codable, Hashable, Identifiable {
    enum Kind: String, Codable { case keys, text, delay }
    var id = UUID()
    var kind: Kind
    var combo: KeyCombo?
    var text = ""
    var delay = 100
}

struct Macro: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var steps: [MacroStep] = []
}

enum Preset: String, Codable, CaseIterable {
    case back, forward, nextTab, previousTab, middleClick
    case missionControl, appExpose, showDesktop, spotlight, screenshot
    case copy, paste, undo, redo
    case playPause, nextTrack, previousTrack, volumeUp, volumeDown, mute

    enum Group: CaseIterable { case navigation, system, edit, media }

    var group: Group {
        switch self {
        case .back, .forward, .nextTab, .previousTab, .middleClick: return .navigation
        case .missionControl, .appExpose, .showDesktop, .spotlight, .screenshot: return .system
        case .copy, .paste, .undo, .redo: return .edit
        case .playPause, .nextTrack, .previousTrack, .volumeUp, .volumeDown, .mute: return .media
        }
    }

    var combo: KeyCombo? {
        let cmd = KeyCombo.command, shift = KeyCombo.shift, ctrl = KeyCombo.control
        switch self {
        case .back: return KeyCombo(keyCode: 33, modifiers: cmd, key: "[")
        case .forward: return KeyCombo(keyCode: 30, modifiers: cmd, key: "]")
        case .nextTab: return KeyCombo(keyCode: 48, modifiers: ctrl, key: "⇥")
        case .previousTab: return KeyCombo(keyCode: 48, modifiers: ctrl | shift, key: "⇥")
        case .spotlight: return KeyCombo(keyCode: 49, modifiers: cmd, key: "Space")
        case .screenshot: return KeyCombo(keyCode: 21, modifiers: cmd | shift, key: "4")
        case .copy: return KeyCombo(keyCode: 8, modifiers: cmd, key: "C")
        case .paste: return KeyCombo(keyCode: 9, modifiers: cmd, key: "V")
        case .undo: return KeyCombo(keyCode: 6, modifiers: cmd, key: "Z")
        case .redo: return KeyCombo(keyCode: 6, modifiers: cmd | shift, key: "Z")
        default: return nil
        }
    }

    var mediaKey: Int32? {
        switch self {
        case .playPause: return 16
        case .nextTrack: return 17
        case .previousTrack: return 18
        case .volumeUp: return 0
        case .volumeDown: return 1
        case .mute: return 7
        default: return nil
        }
    }
}

enum ButtonAction: Codable, Hashable {
    case system
    case disabled
    case preset(Preset)
    case shortcut(KeyCombo)
    case macro(UUID)
}

enum MouseButton: Int, CaseIterable, Identifiable {
    case middle = 2, back = 3, forward = 4
    var id: Int { rawValue }
}

struct InputSettings: Codable, Equatable {
    var buttons: [Int: ButtonAction] = [:]
    var macros: [Macro] = []
    var smooth = false
    var reverse = false
    var speed = 1.0
    var precise = false

    var scrollActive: Bool { smooth || reverse || speed != 1 || precise }

    func action(for button: Int) -> ButtonAction { buttons[button] ?? .system }
}

extension InputSettings {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        buttons = try c.decodeIfPresent([Int: ButtonAction].self, forKey: .buttons) ?? [:]
        macros = try c.decodeIfPresent([Macro].self, forKey: .macros) ?? []
        smooth = try c.decodeIfPresent(Bool.self, forKey: .smooth) ?? false
        reverse = try c.decodeIfPresent(Bool.self, forKey: .reverse) ?? false
        speed = try c.decodeIfPresent(Double.self, forKey: .speed) ?? 1
        precise = try c.decodeIfPresent(Bool.self, forKey: .precise) ?? false
    }
}
