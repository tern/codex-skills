public enum RemoteInput: String, Equatable {
    case longUp
    case longDown
    case shortPress

    public init?(usagePage: UInt32, usage: UInt32, value: Int) {
        guard value != 0 else { return nil }
        switch (usagePage, usage) {
        case (0x0C, 0xE9): self = .longUp
        case (0x0C, 0xEA): self = .longDown
        case (0x09, 0x01): self = .shortPress
        default: return nil
        }
    }

    public var title: String {
        switch self {
        case .longUp: "音量增加事件（上鍵長按）"
        case .longDown: "音量減少事件（下鍵長按）"
        case .shortPress: "button1（五個短按共用）"
        }
    }

    public func mapping(in settings: KeymapSettings) -> ActionMapping {
        switch self {
        case .longUp: settings.longUp
        case .longDown: settings.longDown
        case .shortPress: settings.shortPress
        }
    }
}
