import Foundation
import IOKit.hid
import AppKit
import BeautyR1Core

final class RemoteMonitor: ObservableObject {
    private static let systemDefinedEvent = CGEventType(rawValue: 14)!
    @Published private(set) var isRunning = false
    @Published private(set) var isConnected = false
    @Published private(set) var needsInputMonitoring = false
    @Published private(set) var usesSystemEvents = false
    @Published private(set) var status = "按「開始測試」後，按 Beauty-R1 的實體按鍵。"
    @Published private(set) var lastInput: RemoteInput?
    @Published private(set) var eventCount = 0

    private var manager: IOHIDManager?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?

    func start() {
        guard manager == nil else { return }
        needsInputMonitoring = false
        usesSystemEvents = false
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
            if result == kIOReturnExclusiveAccess {
                startSystemEvents()
                return
            }
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
        if let manager {
            IOHIDManagerRegisterInputValueCallback(manager, nil, nil)
            IOHIDManagerRegisterDeviceMatchingCallback(manager, nil, nil)
            IOHIDManagerRegisterDeviceRemovalCallback(manager, nil, nil)
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        }
        if let eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
        }
        if let eventTap { CFMachPortInvalidate(eventTap) }
        self.manager = nil
        eventTap = nil
        eventTapSource = nil
        isRunning = false
        isConnected = false
        needsInputMonitoring = false
        usesSystemEvents = false
        status = "測試已停止。"
    }

    private func startSystemEvents() {
        let mask = (CGEventMask(1) << CGEventType.leftMouseDown.rawValue)
            | (CGEventMask(1) << Self.systemDefinedEvent.rawValue)
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<RemoteMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.receiveSystemEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: context
        ) else {
            status = "Karabiner 正在接管裝置，且無法建立系統事件監聽。請檢查輸入監控權限。"
            return
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        eventTapSource = source
        isRunning = true
        usesSystemEvents = true
        status = "Karabiner 正在接管裝置。現在監聽 macOS 的按鍵事件；測試時請只按 Beauty-R1。"
    }

    private func receiveSystemEvent(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return
        }
        let data1: Int
        if type == Self.systemDefinedEvent,
           let nativeEvent = NSEvent(cgEvent: event),
           nativeEvent.subtype.rawValue == 8 {
            data1 = nativeEvent.data1
        } else if type == .leftMouseDown {
            data1 = 0
        } else {
            return
        }
        let input = RemoteInput(systemEventType: type.rawValue, data1: data1)
        guard let input else { return }
        lastInput = input
        eventCount += 1
        status = "macOS 已收到事件。系統事件模式可能也會收到其他滑鼠的左鍵。"
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
