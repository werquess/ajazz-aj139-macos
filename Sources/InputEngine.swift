import AppKit
import ApplicationServices

enum Keys {
    static let marker: Int64 = 0x414A_3133

    static func post(_ e: CGEvent?) {
        guard let e else { return }
        e.setIntegerValueField(.eventSourceUserData, value: marker)
        e.post(tap: .cghidEventTap)
    }

    static func press(_ c: KeyCombo) {
        let src = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: src, virtualKey: c.keyCode, keyDown: down)
            e?.flags = CGEventFlags(rawValue: c.modifiers)
            post(e)
        }
    }

    static func type(_ text: String) {
        let src = CGEventSource(stateID: .hidSystemState)
        let units = Array(text.utf16)
        for start in stride(from: 0, to: units.count, by: 16) {
            let chunk = Array(units[start..<min(start + 16, units.count)])
            for down in [true, false] {
                let e = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: down)
                e?.flags = []
                chunk.withUnsafeBufferPointer { e?.keyboardSetUnicodeString(stringLength: $0.count, unicodeString: $0.baseAddress) }
                post(e)
            }
            usleep(4000)
        }
    }

    static func play(_ m: Macro) {
        for s in m.steps {
            switch s.kind {
            case .keys:
                if let c = s.combo { press(c) }
                usleep(10000)
            case .text:
                type(s.text)
            case .delay:
                usleep(UInt32(min(max(s.delay, 0), 10000)) * 1000)
            }
        }
    }

    static func media(_ key: Int32) {
        for down in [true, false] {
            let state: Int32 = down ? 0xA : 0xB
            let e = NSEvent.otherEvent(with: .systemDefined, location: .zero,
                                       modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state) << 8),
                                       timestamp: 0, windowNumber: 0, context: nil, subtype: 8,
                                       data1: Int((key << 16) | (state << 8)), data2: -1)
            post(e?.cgEvent)
        }
    }

    static func middleClick() {
        let loc = CGEvent(source: nil)?.location ?? .zero
        for type in [CGEventType.otherMouseDown, .otherMouseUp] {
            post(CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: loc, mouseButton: .center))
        }
    }

    static func missionControl(_ arg: String?) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/System/Applications/Mission Control.app/Contents/MacOS/Mission Control")
        p.arguments = arg.map { [$0] } ?? []
        try? p.run()
    }
}

final class SmoothScroller {
    private var x = 0.0
    private var y = 0.0
    private var timer: Timer?

    func add(x dx: Double, y dy: Double) {
        if dy != 0, y != 0, (dy > 0) != (y > 0) { y = 0 }
        if dx != 0, x != 0, (dx > 0) != (x > 0) { x = 0 }
        y += dy
        x += dx
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1.0 / 120, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let sy = step(y), sx = step(x)
        y -= Double(sy)
        x -= Double(sx)
        if sy != 0 || sx != 0 {
            Keys.post(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: sy, wheel2: sx, wheel3: 0))
        }
        if abs(y) < 1 && abs(x) < 1 {
            x = 0
            y = 0
            timer?.invalidate()
            timer = nil
        }
    }

    private func step(_ r: Double) -> Int32 {
        guard abs(r) >= 1 else { return 0 }
        let v = r * 0.16
        if abs(v) < 1 { return r > 0 ? 1 : -1 }
        return Int32(v.rounded())
    }
}

final class InputEngine {
    static let shared = InputEngine()

    var settings = InputSettings()
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let scroller = SmoothScroller()
    private let worker = DispatchQueue(label: "io.github.werquess.aj139.macro")
    private var lastWheel = 0.0
    private var streak = 0.0

    var isRunning: Bool { tap != nil }

    func start() {
        guard tap == nil else { return }
        let types: [CGEventType] = [.scrollWheel, .otherMouseDown, .otherMouseUp, .otherMouseDragged]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                        eventsOfInterest: mask, callback: { _, type, event, ctx in
            Unmanaged<InputEngine>.fromOpaque(ctx!).takeUnretainedValue().handle(type, event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
        tap = t
        source = src
    }

    func stop() {
        guard let t = tap else { return }
        CGEvent.tapEnable(tap: t, enable: false)
        if let s = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), s, .commonModes) }
        CFMachPortInvalidate(t)
        tap = nil
        source = nil
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(event)
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
            return pass
        default:
            break
        }
        if event.getIntegerValueField(.eventSourceUserData) == Keys.marker { return pass }
        switch type {
        case .scrollWheel:
            return scroll(event) ? nil : pass
        case .otherMouseDown, .otherMouseUp, .otherMouseDragged:
            return button(type, event) ? nil : pass
        default:
            return pass
        }
    }

    private func button(_ type: CGEventType, _ event: CGEvent) -> Bool {
        let action = settings.action(for: Int(event.getIntegerValueField(.mouseEventButtonNumber)))
        if action == .system { return false }
        if type == .otherMouseDown { perform(action) }
        return true
    }

    func perform(_ action: ButtonAction) {
        switch action {
        case .system, .disabled:
            break
        case .preset(let p):
            run(p)
        case .shortcut(let c):
            worker.async { Keys.press(c) }
        case .macro(let id):
            guard let m = settings.macros.first(where: { $0.id == id }) else { return }
            worker.async { Keys.play(m) }
        }
    }

    private func run(_ p: Preset) {
        if let c = p.combo {
            worker.async { Keys.press(c) }
            return
        }
        if let k = p.mediaKey {
            Keys.media(k)
            return
        }
        switch p {
        case .middleClick: Keys.middleClick()
        case .missionControl: Keys.missionControl(nil)
        case .appExpose: Keys.missionControl("2")
        case .showDesktop: Keys.missionControl("1")
        default: break
        }
    }

    private func scroll(_ e: CGEvent) -> Bool {
        let s = settings
        guard s.scrollActive, e.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 else { return false }
        var factor = s.speed * (s.reverse ? -1 : 1)
        if s.precise, e.flags.contains(.maskAlternate) { factor *= 0.25 }

        if s.smooth {
            let now = ProcessInfo.processInfo.systemUptime
            streak = now - lastWheel < 0.08 ? min(streak + 1, 16) : 0
            lastWheel = now
            let accel = 1 + streak * 0.12
            var dy = Double(e.getIntegerValueField(.scrollWheelEventDeltaAxis1))
            var dx = Double(e.getIntegerValueField(.scrollWheelEventDeltaAxis2))
            if e.flags.contains(.maskShift), dx == 0 {
                dx = dy
                dy = 0
            }
            scroller.add(x: dx * 50 * factor * accel, y: dy * 50 * factor * accel)
            return true
        }

        let axes: [(CGEventField, CGEventField, CGEventField)] = [
            (.scrollWheelEventDeltaAxis1, .scrollWheelEventPointDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1),
            (.scrollWheelEventDeltaAxis2, .scrollWheelEventPointDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2),
        ]
        for (line, point, fixed) in axes {
            let l = e.getIntegerValueField(line)
            guard l != 0 else { continue }
            let scaled = (Double(l) * factor).rounded()
            e.setIntegerValueField(line, value: scaled == 0 ? (l * (factor < 0 ? -1 : 1)) : Int64(scaled))
            e.setIntegerValueField(point, value: Int64((Double(e.getIntegerValueField(point)) * factor).rounded()))
            e.setDoubleValueField(fixed, value: e.getDoubleValueField(fixed) * factor)
        }
        return false
    }
}

@MainActor
final class InputStore: ObservableObject {
    static let shared = InputStore()

    @Published var settings: InputSettings { didSet { persist() } }
    @Published private(set) var trusted = AXIsProcessTrusted()
    private var timer: Timer?

    init() {
        if let d = UserDefaults.standard.data(forKey: "input"),
           let s = try? JSONDecoder().decode(InputSettings.self, from: d) {
            settings = s
        } else {
            settings = InputSettings()
        }
        InputEngine.shared.settings = settings
    }

    func start() {
        checkTrust()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in InputStore.shared.checkTrust() }
        }
    }

    func checkTrust() {
        let now = AXIsProcessTrusted()
        if now != trusted { trusted = now }
        if now { InputEngine.shared.start() } else { InputEngine.shared.stop() }
    }

    func requestAccess() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    func save(_ m: Macro) {
        if let i = settings.macros.firstIndex(where: { $0.id == m.id }) {
            settings.macros[i] = m
        } else {
            settings.macros.append(m)
        }
    }

    func delete(_ m: Macro) {
        settings.macros.removeAll { $0.id == m.id }
        for (k, v) in settings.buttons where v == .macro(m.id) { settings.buttons[k] = .system }
    }

    private func persist() {
        InputEngine.shared.settings = settings
        if let d = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(d, forKey: "input") }
    }
}
