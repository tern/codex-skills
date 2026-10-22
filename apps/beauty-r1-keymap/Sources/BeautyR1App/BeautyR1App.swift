import SwiftUI

@main
struct BeautyR1App: App {
    @StateObject private var remoteMonitor = RemoteMonitor()

    var body: some Scene {
        WindowGroup("Beauty-R1 按鍵設定") {
            ContentView(remoteMonitor: remoteMonitor)
        }
        .windowResizability(.contentSize)
    }
}
