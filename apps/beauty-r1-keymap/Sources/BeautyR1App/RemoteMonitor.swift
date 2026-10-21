import Foundation
import IOKit.hid
import BeautyR1Core

final class RemoteMonitor: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isConnected = false
    @Published private(set) var needsInputMonitoring = false
    @Published private(set) var status = "按「開始測試」後，按 Beauty-R1 的實體按鍵。"
    @Published private(set) var lastInput: RemoteInput?
    @Published private(set) var eventCount = 0

    private var manager: IOHIDManager?

    func start() {
        guard manager == nil else { return }
        needsInputMonitoring = false
        lastInput = nil
        eventCount = 0
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Int] = [
            kIOHIDVendorIDKey as String: 1452,
            kIOHIDProductIDKey as String: 556
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, _ in
            guard let context else { return }
            Unmanaged<RemoteMonitor>.fromOpaque(context).takeUnretainedValue().refreshConnection()
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, _ in
            guard let context else { return }
            Unmanaged<RemoteMonitor>.fromOpaque(context).takeUnretainedValue().refreshConnection()
        }, context)
        IOHIDManagerRegisterInputValueCallback(manager, { context, _, _, value in
            guard let context else { return }
            Unmanaged<RemoteMonitor>.fromOpaque(context).takeUnretainedValue().receive(value)
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            needsInputMonitoring = result == kIOReturnNotPermitted
            status = needsInputMonitoring
                ? "macOS 尚未允許此 App 監聽輸入。請在系統設定開啟權限，重新啟動 App，再按「開始測試」。"
                : "無法啟動裝置監聽（錯誤碼 \(result)）。"
            return
        }
        self.manager = manager
        isRunning = true
        refreshConnection()
    }

    func stop() {
        guard let manager else { return }
        IOHIDManagerRegisterInputValueCallback(manager, nil, nil)
        IOHIDManagerRegisterDeviceMatchingCallback(manager, nil, nil)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, nil, nil)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        self.manager = nil
        isRunning = false
        isConnected = false
        needsInputMonitoring = false
        status = "測試已停止。"
    }

    private func refreshConnection() {
        guard let manager else { return }
        let count = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>)?.count ?? 0
        isConnected = count > 0
        status = isConnected
            ? "已找到 Beauty-R1。請按實體按鍵。"
            : "正在等待 Beauty-R1 連線；請按一下按鍵喚醒遙控器。"
    }

    private func receive(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        guard let input = RemoteInput(
            usagePage: IOHIDElementGetUsagePage(element),
            usage: IOHIDElementGetUsage(element),
            value: IOHIDValueGetIntegerValue(value)
        ) else { return }
        lastInput = input
        eventCount += 1
        status = "已收到按鍵事件。"
    }

    deinit {
        stop()
    }
}
