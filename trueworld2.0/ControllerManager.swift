import SwiftUI
import GameController
import Combine

class ControllerManager: ObservableObject {
    static let shared = ControllerManager()
    
    @Published var leftThumbstickX: Float = 0
    @Published var rightTrigger: Float = 0
    @Published var leftTrigger: Float = 0
    @Published var isConnected: Bool = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didConnect), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnect), name: .GCControllerDidDisconnect, object: nil)
    }
    
    @objc func didConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        isConnected = true
        setupController(controller)
    }
    
    @objc func didDisconnect() {
        if GCController.controllers().isEmpty {
            isConnected = false
        }
    }
    
    func setupController(_ controller: GCController) {
        controller.extendedGamepad?.leftThumbstick.valueChangedHandler = { [weak self] _, x, _ in
            self?.leftThumbstickX = x
        }
        
        controller.extendedGamepad?.rightTrigger.valueChangedHandler = { [weak self] _, value, _ in
            self?.rightTrigger = value
        }
        
        controller.extendedGamepad?.leftTrigger.valueChangedHandler = { [weak self] _, value, _ in
            self?.leftTrigger = value
        }
    }
}
