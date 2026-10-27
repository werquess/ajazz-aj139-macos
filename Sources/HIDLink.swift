import Foundation
import IOKit.hid

final class HIDLink {
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    private let inBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: Proto.reportSize)
    private var queue: [[UInt8]] = []

    var isConnected: Bool { device != nil }

    func connect() {
        if device != nil { return }
        let none = IOOptionBits(kIOHIDOptionsTypeNone)
        let mgr = IOHIDManagerCreate(kCFAllocatorDefault, none)
        let matches = Proto.vendorIDs.map { vid -> [String: Int] in
            [kIOHIDVendorIDKey: vid, kIOHIDProductIDKey: Proto.productID, kIOHIDPrimaryUsagePageKey: Proto.usagePage]
        }
        IOHIDManagerSetDeviceMatchingMultiple(mgr, matches as CFArray)
        guard IOHIDManagerOpen(mgr, none) == kIOReturnSuccess,
              let set = IOHIDManagerCopyDevices(mgr) as? Set<IOHIDDevice>, let dev = set.first,
              IOHIDDeviceOpen(dev, none) == kIOReturnSuccess else {
            IOHIDManagerClose(mgr, none)
            return
        }
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(dev, inBuf, Proto.reportSize, { ctx, _, _, _, _, report, len in
            let link = Unmanaged<HIDLink>.fromOpaque(ctx!).takeUnretainedValue()
            link.queue.append(Array(UnsafeBufferPointer(start: report, count: len)))
        }, ctx)
        IOHIDDeviceScheduleWithRunLoop(dev, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        manager = mgr
        device = dev
    }

    func disconnect() {
        let none = IOOptionBits(kIOHIDOptionsTypeNone)
        if let d = device { IOHIDDeviceClose(d, none) }
        if let m = manager { IOHIDManagerClose(m, none) }
        device = nil
        manager = nil
        queue.removeAll()
    }

    func transfer(_ p: [UInt8]) -> [UInt8]? {
        guard let dev = device else { return nil }
        queue.removeAll()
        let r = p.withUnsafeBufferPointer {
            IOHIDDeviceSetReport(dev, kIOHIDReportTypeOutput, 0, $0.baseAddress!, p.count)
        }
        if r != kIOReturnSuccess {
            disconnect()
            return nil
        }
        let deadline = Date().addingTimeInterval(0.6)
        while Date() < deadline {
            CFRunLoopRunInMode(.defaultMode, 0.01, false)
            while !queue.isEmpty {
                let rep = queue.removeFirst()
                if rep.count >= 2, rep[0] == 0xAA, rep[1] == p[1] { return rep }
            }
        }
        return nil
    }
}
