import SwiftUI

extension KeyCombo {
    init(event e: NSEvent) {
        let mods = UInt64(e.modifierFlags.rawValue) & KeyCombo.mask
        let key = KeyCombo.specialKeys[e.keyCode] ?? (e.charactersIgnoringModifiers ?? "?").uppercased()
        self.init(keyCode: e.keyCode, modifiers: mods, key: key)
    }
}

struct AccessBanner: View {
    @ObservedObject var input: InputStore
    let t: Strings

    var body: some View {
        if !input.trusted {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill").font(.title2).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 8) {
                    Text(t[.accessTitle]).font(.callout.weight(.semibold))
                    Text(t[.accessDetail]).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(t[.accessButton]) { input.requestAccess() }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.15)))
        }
    }
}

struct ShortcutField: View {
    @Binding var combo: KeyCombo?
    let t: Strings
    var autoStart = false
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button { recording ? stop() : begin() } label: {
            Text(recording ? t[.pressKeys] : combo?.display ?? t[.recordShortcut])
                .font(.body.monospaced())
                .frame(minWidth: 130)
        }
        .onAppear { if autoStart { begin() } }
        .onDisappear { stop() }
    }

    private func begin() {
        stop()
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
            let mods = UInt64(e.modifierFlags.rawValue) & KeyCombo.mask
            if e.keyCode != 53 || mods != 0 { combo = KeyCombo(event: e) }
            stop()
            return nil
        }
    }

    private func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
        recording = false
    }
}

struct ShortcutSheet: View {
    let t: Strings
    let onSave: (KeyCombo) -> Void
    @State private var combo: KeyCombo?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t[.recordTitle]).font(.title3.weight(.semibold))
            Text(t[.recordHint]).font(.callout).foregroundStyle(.secondary)
            HStack {
                Spacer()
                ShortcutField(combo: $combo, t: t, autoStart: true).controlSize(.large)
                Spacer()
            }
            HStack {
                Spacer()
                Button(t[.cancel]) { dismiss() }
                Button(t[.save]) {
                    if let combo { onSave(combo) }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(combo == nil)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}

struct ActionMenu: View {
    @ObservedObject var input: InputStore
    let button: MouseButton
    let t: Strings
    let onRecord: () -> Void

    private func set(_ a: ButtonAction) { input.settings.buttons[button.rawValue] = a }

    var body: some View {
        Menu {
            Button(t[.actionSystem]) { set(.system) }
            Button(t[.actionDisabled]) { set(.disabled) }
            Divider()
            ForEach(Preset.Group.allCases, id: \.self) { g in
                Menu(t.group(g)) {
                    ForEach(Preset.allCases.filter { $0.group == g }, id: \.self) { p in
                        Button(t.preset(p)) { set(.preset(p)) }
                    }
                }
            }
            Divider()
            Button(t[.recordShortcut]) { onRecord() }
            if !input.settings.macros.isEmpty {
                Menu(t[.macros]) {
                    ForEach(input.settings.macros) { m in
                        Button(m.name) { set(.macro(m.id)) }
                    }
                }
            }
        } label: {
            Text(t.action(input.settings.action(for: button.rawValue), macros: input.settings.macros))
        }
        .fixedSize()
    }
}

struct ButtonsTab: View {
    @ObservedObject var input: InputStore
    let t: Strings
    @State private var recording: MouseButton?
    @State private var editing: Macro?

    var body: some View {
        VStack(spacing: 14) {
            AccessBanner(input: input, t: t)

            Card(title: t[.buttons], icon: "computermouse") {
                VStack(spacing: 10) {
                    ForEach(MouseButton.allCases) { b in
                        HStack {
                            Text(t.button(b))
                            Spacer()
                            ActionMenu(input: input, button: b, t: t) { recording = b }
                        }
                    }
                    Text(t[.buttonsHint]).font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Card(title: t[.macros], icon: "list.bullet.rectangle") {
                VStack(spacing: 8) {
                    if input.settings.macros.isEmpty {
                        Text(t[.noMacros]).font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ForEach(input.settings.macros) { m in
                        HStack {
                            Image(systemName: "play.rectangle").foregroundStyle(.secondary)
                            Text(m.name)
                            Text("\(m.steps.count) \(t[.stepsCount])").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button { editing = m } label: { Image(systemName: "pencil") }.buttonStyle(.borderless)
                            Button { input.delete(m) } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless).help(t[.delete])
                        }
                    }
                    HStack {
                        Button {
                            editing = Macro(name: "\(t[.newMacro]) \(input.settings.macros.count + 1)")
                        } label: { Label(t[.newMacro], systemImage: "plus") }
                        Spacer()
                    }
                }
            }
        }
        .sheet(item: $recording) { b in
            ShortcutSheet(t: t) { input.settings.buttons[b.rawValue] = .shortcut($0) }
        }
        .sheet(item: $editing) { m in
            MacroEditor(macro: m, t: t) { input.save($0) }
        }
    }
}

struct MacroEditor: View {
    @State var macro: Macro
    let t: Strings
    let onSave: (Macro) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t[.editMacro]).font(.title2.weight(.semibold))
            TextField(t[.macroName], text: $macro.name).textFieldStyle(.roundedBorder)

            Card(title: t[.steps], icon: "list.number") {
                if macro.steps.isEmpty {
                    Text(t[.noSteps]).font(.callout).foregroundStyle(.secondary)
                }
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(macro.steps.enumerated()), id: \.element.id) { i, s in
                            row(i, s)
                        }
                    }
                }
                .frame(maxHeight: 280)
                .fixedSize(horizontal: false, vertical: macro.steps.count < 7)
                HStack {
                    Button { macro.steps.append(MacroStep(kind: .keys)) } label: { Label(t[.addKeys], systemImage: "command") }
                    Button { macro.steps.append(MacroStep(kind: .text)) } label: { Label(t[.addText], systemImage: "textformat") }
                    Button { macro.steps.append(MacroStep(kind: .delay)) } label: { Label(t[.addDelay], systemImage: "timer") }
                }
            }

            HStack {
                Spacer()
                Button(t[.cancel]) { dismiss() }
                Button(t[.save]) {
                    onSave(macro)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(macro.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500)
    }

    private func binding(_ id: UUID) -> Binding<MacroStep> {
        Binding(get: { macro.steps.first { $0.id == id } ?? MacroStep(kind: .delay) },
                set: { v in
                    if let i = macro.steps.firstIndex(where: { $0.id == id }) { macro.steps[i] = v }
                })
    }

    private func move(_ i: Int, by d: Int) {
        let j = i + d
        guard macro.steps.indices.contains(j) else { return }
        macro.steps.swapAt(i, j)
    }

    @ViewBuilder
    private func row(_ i: Int, _ s: MacroStep) -> some View {
        let b = binding(s.id)
        HStack(spacing: 8) {
            Text("\(i + 1)").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 16)
            switch s.kind {
            case .keys:
                Image(systemName: "command").frame(width: 18)
                ShortcutField(combo: b.combo, t: t)
                Spacer()
            case .text:
                Image(systemName: "textformat").frame(width: 18)
                TextField(t[.textPlaceholder], text: b.text).textFieldStyle(.roundedBorder)
            case .delay:
                Image(systemName: "timer").frame(width: 18)
                TextField("", value: b.delay, format: .number.grouping(.never))
                    .textFieldStyle(.roundedBorder).frame(width: 70).multilineTextAlignment(.trailing)
                Text(t[.ms]).foregroundStyle(.secondary)
                Spacer()
            }
            Button { move(i, by: -1) } label: { Image(systemName: "chevron.up") }
                .buttonStyle(.borderless).disabled(i == 0)
            Button { move(i, by: 1) } label: { Image(systemName: "chevron.down") }
                .buttonStyle(.borderless).disabled(i == macro.steps.count - 1)
            Button { macro.steps.removeAll { $0.id == s.id } } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
        }
    }
}

struct ScrollTab: View {
    @ObservedObject var input: InputStore
    let t: Strings

    var body: some View {
        VStack(spacing: 14) {
            AccessBanner(input: input, t: t)

            Card(title: t[.scroll], icon: "scroll") {
                SwitchRow(title: t[.smooth], detail: t[.smoothHint], isOn: $input.settings.smooth)
                Divider()
                SwitchRow(title: t[.reverse], detail: t[.reverseHint], isOn: $input.settings.reverse)
                Divider()
                HStack(spacing: 12) {
                    Text(t[.speed])
                    Slider(value: $input.settings.speed, in: 0.5...3, step: 0.25)
                    Text(String(format: "%.2f×", input.settings.speed))
                        .font(.callout.monospacedDigit()).foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
                }
                Divider()
                SwitchRow(title: t[.precise], detail: t[.preciseHint], isOn: $input.settings.precise)
            }

            Text(t[.scrollFooter]).font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
