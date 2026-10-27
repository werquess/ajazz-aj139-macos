import SwiftUI

enum Links {
    static let coffee = URL(string: "https://buymeacoffee.com/werquess")!
    static let repo = URL(string: "https://github.com/werquess/ajazz-aj139-macos")!
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

struct ContentView: View {
    @ObservedObject var m: MouseModel
    @AppStorage("language") private var language = Language.system
    @State private var showSettings = false

    var body: some View {
        let t = Strings(lang: language)
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AJ139 V2 MC").font(.title3.weight(.semibold))
                    HStack(spacing: 6) {
                        Circle().fill(m.connected ? .green : .red).frame(width: 8, height: 8)
                        Text(m.connected ? t[.connected] : t[.disconnected])
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { m.refresh() } label: { Image(systemName: "arrow.clockwise") }.help(t[.refresh])
                Button { showSettings = true } label: { Image(systemName: "gearshape") }.help(t[.settings])
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
        .padding(18)
        .frame(width: 520)
        .sheet(isPresented: $showSettings) { SettingsView(m: m) }
    }
}

struct SettingsView: View {
    @ObservedObject var m: MouseModel
    @AppStorage("language") private var language = Language.system
    @AppStorage("pollInterval") private var pollInterval = 15.0
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        let t = Strings(lang: language)
        VStack(alignment: .leading, spacing: 14) {
            Text(t[.settings]).font(.title2.weight(.semibold))

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
