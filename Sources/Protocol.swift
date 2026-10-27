import Foundation

enum Proto {
    static let vendorIDs = [0xA8A4, 0xA8A5]
    static let productID = 0x2255
    static let usagePage = 0xFF01
    static let reportSize = 64
    static let dpiMin = 50, dpiMax = 26000, stageCount = 6
    static let defaultStages = [400, 800, 1200, 1600, 2400, 3200]

    static func packet(cmd: UInt8, head: UInt8 = 0xA5, len: UInt8) -> [UInt8] {
        var p = [UInt8](repeating: 0, count: reportSize)
        p[0] = 0x55; p[1] = cmd; p[2] = head; p[4] = len
        p[3] = checksum(p)
        return p
    }

    static func checksum(_ p: [UInt8]) -> UInt8 {
        UInt8(truncatingIfNeeded: p[4...].reduce(0) { $0 + Int($1) })
    }

    static let readBattery = packet(cmd: 0x30, len: 0x2E)
    static let readConfig = packet(cmd: 0x0E, len: 0x30)

    static func writeConfig(_ c: Config) -> [UInt8] {
        var p = c.raw
        p[0] = 0x55; p[1] = 0x0F; p[2] = 0xAE; p[4] = 0x30; p[5] = 0; p[6] = 0; p[7] = 0
        p[3] = checksum(p)
        return p
    }
}

struct Battery: Equatable {
    var percent: Int
    var charging: Bool
}

struct Config {
    var raw: [UInt8]

    var activeStage: Int {
        get { max(0, min(Proto.stageCount - 1, Int(raw[12]) - 1)) }
        set { raw[12] = UInt8(newValue + 1) }
    }

    func dpi(_ i: Int) -> Int { Int(raw[13 + 2 * i]) | Int(raw[14 + 2 * i]) << 8 }

    mutating func setDPI(_ i: Int, _ v: Int) {
        let c = max(Proto.dpiMin, min(Proto.dpiMax, v))
        raw[13 + 2 * i] = UInt8(c & 0xFF)
        raw[14 + 2 * i] = UInt8(c >> 8)
    }
}
