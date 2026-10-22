public enum RemoteButton: String, CaseIterable, Codable, Equatable {
    case up
    case down
    case left
    case right
    case center

 public var title: String {
  switch self {
  case .up: "上鍵"
  case .down: "下鍵"
  case .left: "左鍵"
  case .right: "右鍵"
  case .center: "愛心鍵"
  }
 }
}

/// Classifies the mouse motion that DY10 emits between button 1 down and up.
/// The large positioning reports before button down are deliberately ignored.
public struct RemoteGestureDecoder {
    private var pressed = false
 private var emitted = false
    private var x = 0
    private var y = 0

    public init() {}

    public mutating func receive(usagePage: Int, usage: Int, value: Int) -> RemoteButton? {
        if usagePage == 0x09 && usage == 0x01 {
            if value == 1 {
                pressed = true
  emitted = false
                x = 0
                y = 0
                return nil
            }
            if value == 0 && pressed {
                pressed = false
  return emitted ? nil : .center
            }
        }

        guard pressed, usagePage == 0x01, abs(value) < 1000 else { return nil }
        switch usage {
        case 0x30: x += value
        case 0x31: y += value
        default: break
        }
 guard !emitted, abs(x) >= 40 || abs(y) >= 40 else { return nil }
 emitted = true
 return classify()
    }

    private func classify() -> RemoteButton {
        let threshold = 40
        if abs(y) >= threshold && abs(y) >= abs(x) {
            return y > 0 ? .up : .down
        }
        if abs(x) >= threshold {
            // DY10's report moves right for its left key, and vice versa.
            return x > 0 ? .left : .right
        }
        return .center
    }
}
