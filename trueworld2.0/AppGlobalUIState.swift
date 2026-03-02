import SwiftUI
import Combine

class AppGlobalUIState: ObservableObject {
    static let shared = AppGlobalUIState()
    
    @Published var isTabBarHidden: Bool = false
    @Published var isEyeWorldUiHidden: Bool = false
    
    func toggleTabBar() {
        withAnimation(.spring()) {
            isTabBarHidden.toggle()
        }
    }
    
    func toggleEyeWorldUi() {
        withAnimation(.spring()) {
            isEyeWorldUiHidden.toggle()
        }
    }
}
