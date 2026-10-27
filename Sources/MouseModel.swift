import SwiftUI

enum Status {
    case searching, notFound, bluetooth, connected, readFailed, writeFailed, verifyFailed, saved
}

@MainActor
final class MouseModel: ObservableObject {
    @Published var connected = false
    @Published var battery: Battery?
    @Published var stages = Proto.defaultStages
    @Published var active = 0
    @Published var status = Status.searching

    private var config: Config?
    private let link = HIDLink()
    private var timer: Timer?

    func start(interval: Double) {
        refresh()
        setPollInterval(interval)
    }

    func setPollInterval(_ seconds: Double) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollBattery() }
        }
    }

    func refresh() {
        link.connect()
        connected = link.isConnected
        guard connected else {
            status = HIDLink.bluetoothDevicePresent() ? .bluetooth : .notFound
            battery = nil
            return
        }
        pollBattery()
        loadConfig()
    }

    func pollBattery() {
        if !link.isConnected {
            refresh()
            return
        }
        guard let r = link.transfer(Proto.readBattery), r.count > 9 else {
            connected = link.isConnected
            return
        }
        battery = Battery(percent: Int(r[8]), charging: r[9] != 0)
    }

    func loadConfig() {
        guard let r = link.transfer(Proto.readConfig), r.count >= Proto.reportSize else {
            status = .readFailed
            return
        }
        show(Config(raw: r))
        status = .connected
    }

    func resetDefaults() {
        stages = Proto.defaultStages
        active = 1
    }

    func apply() {
        guard var c = config else { return }
        for i in 0..<Proto.stageCount { c.setDPI(i, stages[i]) }
        c.activeStage = active
        guard let ack = link.transfer(Proto.writeConfig(c)), ack.count > 2, ack[2] == 0xAE else {
            status = .writeFailed
            return
        }
        guard let r = link.transfer(Proto.readConfig), r.count >= Proto.reportSize else {
            status = .verifyFailed
            return
        }
        show(Config(raw: r))
        status = .saved
    }

    private func show(_ c: Config) {
        config = c
        stages = (0..<Proto.stageCount).map { c.dpi($0) }
        active = c.activeStage
    }
}
