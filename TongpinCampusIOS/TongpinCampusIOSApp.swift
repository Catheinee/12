import SwiftUI

@main
struct TongpinCampusIOSApp: App {
    @StateObject private var store = CampusStore()

    var body: some Scene {
        WindowGroup {
            CampusRootView()
                .environmentObject(store)
        }
    }
}
