import SwiftUI
import ServiceManagement

enum Links {
    static let coffee = URL(string: "https://buymeacoffee.com/werquess")!
    static let repo = URL(string: "https://github.com/werquess/ajazz-aj139-macos")!
}

enum Tab: String {
    case mouse, buttons, scroll
}

func batteryIcon(_ b: Battery?) -> String {
    guard let b else { return "computermouse" }
    if b.charging { return "battery.100.bolt" }
    switch b.percent {
    case 88...: return "battery.100"
    case 63..<88: return "battery.75"
    case 38..<63: return "battery.50"
    case 13..<38: return "battery.25"
    default: return "battery.0"
    }
}

struct Card<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(.background.secondary))
    }
}

struct SwitchRow: View {
    let title: String
    var detail: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn).toggleStyle(.switch).labelsHidden().controlSize(.small)
        }
    }
}

struct BatteryView: View {
    let battery: Battery?
    let t: Strings

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(battery?.percent ?? 0) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if battery?.charging == true {
                    Image(systemName: "bolt.fill").foregroundStyle(color)
                }
            }
            .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 2) {
                Text(battery.map { "\($0.percent)%" } ?? "—")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var subtitle: String {
        guard let b = battery else { return t[.unreadable] }
        return b.charging ? t[.usbConnected] : t[.onBattery]
    }

    private var color: Color {
        guard let p = battery?.percent else { return .gray }
        return p <= 15 ? .red : p <= 40 ? .orange : .green
    }
}

struct StageRow: View {
    @ObservedObject var m: MouseModel
    let index: Int
    let t: Strings

    var body: some View {
        HStack(spacing: 10) {
            Button { m.active = index } label: {
                Image(systemName: m.active == index ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(m.active == index ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(t[.makeActive])
            Text("\(index + 1)").font(.caption.monospacedDigit()).frame(width: 12)
            Slider(value: Binding(get: { Double(m.stages[index]) },
                                  set: { m.stages[index] = Int($0 / 50) * 50 }),
                   in: 100...12000)
            TextField("", value: $m.stages[index], format: .number.grouping(.never))
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct MouseTab: View {
    @ObservedObject var m: MouseModel
    let t: Strings

    private var onBluetooth: Bool { !m.connected && m.status == .bluetooth }

    var body: some View {
        VStack(spacing: 14) {
            if onBluetooth {
                Label(t[.bluetoothDetail], systemImage: "info.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.15)))
            }

            Card(title: t[.battery], icon: "battery.100") { BatteryView(battery: m.battery, t: t) }

            Card(title: t[.dpi], icon: "slider.horizontal.3") {
                VStack(spacing: 10) {
                    ForEach(0..<Proto.stageCount, id: \.self) { StageRow(m: m, index: $0, t: t) }
                    Text(t[.hint]).font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .disabled(!m.connected)

            HStack {
                Text(t.status(m.status)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Spacer()
                Button(t[.defaults]) { m.resetDefaults() }
                Button(t[.apply]) { m.apply() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .disabled(!m.connected)
        }
    }
}

struct ContentView: View {
    @ObservedObject var m: MouseModel
    @ObservedObject var input: InputStore
    @AppStorage("language") private var language = Language.system
    @AppStorage("tab") private var tab = Tab.mouse
    @State private var showSettings = false

    private var onBluetooth: Bool { !m.connected && m.status == .bluetooth }

    var body: some View {
        let t = Strings(lang: language)
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AJ139 V2 MC").font(.title3.weight(.semibold))
                    HStack(spacing: 6) {
                        Circle().fill(m.connected ? .green : onBluetooth ? .blue : .red).frame(width: 8, height: 8)
                        Text(m.connected ? t[.connected] : onBluetooth ? t[.bluetooth] : t[.disconnected])
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { m.refresh() } label: { Image(systemName: "arrow.clockwise") }.help(t[.refresh])
                Button { showSettings = true } label: { Image(systemName: "gearshape") }.help(t[.settings])
            }

            Picker("", selection: $tab) {
                Text(t[.tabMouse]).tag(Tab.mouse)
                Text(t[.tabButtons]).tag(Tab.buttons)
                Text(t[.tabScroll]).tag(Tab.scroll)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch tab {
            case .mouse: MouseTab(m: m, t: t)
            case .buttons: ButtonsTab(input: input, t: t)
            case .scroll: ScrollTab(input: input, t: t)
            }
        }
        .padding(18)
        .frame(width: 520)
        .sheet(isPresented: $showSettings) { SettingsView(m: m) }
    }
}

struct SettingsView: View {
    @ObservedObject var m: MouseModel
    @AppStorage("language") private var language = Language.system
    @AppStorage("pollInterval") private var pollInterval = 15.0
    @AppStorage("menuBar") private var menuBar = true
    @AppStorage("menuBarPercent") private var menuBarPercent = true
    @AppStorage("showDock") private var showDock = true
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        let t = Strings(lang: language)
        VStack(alignment: .leading, spacing: 14) {
            Text(t[.settings]).font(.title2.weight(.semibold))

            Card(title: t[.general], icon: "macwindow") {
                SwitchRow(title: t[.showMenuBar], isOn: $menuBar).disabled(!showDock)
                SwitchRow(title: t[.menuBarPercent], isOn: $menuBarPercent).disabled(!menuBar)
                SwitchRow(title: t[.showDock], isOn: $showDock).disabled(!menuBar)
                SwitchRow(title: t[.launchAtLogin], isOn: $openAtLogin)
                Text(t[.backgroundHint]).font(.caption).foregroundStyle(.secondary)
            }
            .onChange(of: showDock) {
                AppDelegate.applyDockPolicy()
                NSApp.activate()
            }
            .onChange(of: openAtLogin) { _, on in
                try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                openAtLogin = SMAppService.mainApp.status == .enabled
            }

            Card(title: t[.language], icon: "globe") {
                Picker("", selection: $language) {
                    Text(t[.systemLanguage]).tag(Language.system)
                    Text("English").tag(Language.en)
                    Text("Türkçe").tag(Language.tr)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Card(title: t[.batteryRefresh], icon: "clock.arrow.circlepath") {
                Picker("", selection: $pollInterval) {
                    ForEach([15.0, 30.0, 60.0, 300.0], id: \.self) { Text("\(Int($0)) \(t[.seconds])").tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .onChange(of: pollInterval) { m.setPollInterval($1) }
            }

            Card(title: t[.support], icon: "heart") {
                Text(t[.supportText]).font(.callout).foregroundStyle(.secondary)
                Link(destination: Links.coffee) {
                    Label(t[.buyCoffee], systemImage: "cup.and.saucer.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color(red: 1, green: 0.87, blue: 0)))
                }
                .buttonStyle(.plain)
            }

            Card(title: t[.about], icon: "info.circle") {
                HStack {
                    Text("\(t[.version]) \(version)").foregroundStyle(.secondary)
                    Spacer()
                    Link(t[.source], destination: Links.repo)
                }
            }

            HStack {
                Spacer()
                Button(t[.done]) { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var m: MouseModel
    @AppStorage("menuBarPercent") private var percent = true

    var body: some View {
        if percent, let b = m.battery {
            HStack(spacing: 3) {
                Image(systemName: batteryIcon(b))
                Text("\(b.percent)%")
            }
        } else {
            Image(systemName: "computermouse.fill")
        }
    }
}

struct MenuBarView: View {
    @ObservedObject var m: MouseModel
    @ObservedObject var input: InputStore
    @AppStorage("language") private var language = Language.system
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let t = Strings(lang: language)
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("AJ139 V2 MC").font(.headline)
                    Text(m.connected ? t[.connected] : m.status == .bluetooth ? t[.bluetooth] : t[.disconnected])
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let b = m.battery {
                    Label("\(b.percent)%", systemImage: batteryIcon(b)).font(.callout.monospacedDigit())
                }
            }

            if m.connected {
                Divider()
                Text(t[.activeStage]).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    ForEach(0..<Proto.stageCount, id: \.self) { i in
                        Button {
                            m.active = i
                            m.apply()
                        } label: {
                            Text("\(m.stages[i])")
                                .font(.callout.monospacedDigit().weight(m.active == i ? .semibold : .regular))
                                .foregroundStyle(m.active == i ? Color.white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 7)
                                    .fill(m.active == i ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()
            SwitchRow(title: t[.smooth], isOn: $input.settings.smooth)
            SwitchRow(title: t[.reverse], isOn: $input.settings.reverse)
            if !input.trusted {
                Button(t[.accessButton]) { input.requestAccess() }
            }

            Divider()
            HStack {
                Button(t[.openApp]) {
                    openWindow(id: "main")
                    NSApp.activate()
                }
                Spacer()
                Button(t[.quit]) { NSApp.terminate(nil) }
            }
        }
        .padding(14)
        .frame(width: 290)
        .onAppear { m.pollBattery() }
    }
}
