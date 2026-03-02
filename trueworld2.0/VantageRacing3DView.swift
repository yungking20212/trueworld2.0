import SwiftUI
import SceneKit
import GameController

struct VantageRacing3DView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var creditManager = GameCreditManager.shared
    @StateObject private var orchestrator = CloudOrchestrator.shared
    @StateObject private var controller = ControllerManager.shared
    @StateObject private var neuralEngine = NeuralEngine.shared
    
    // Game Physics State
    @State private var speed: Float = 0.0
    @State private var steering: Float = 0.0
    @State private var throttle: Float = 0.0
    @State private var brake: Float = 0.0
    @State private var nitro: Bool = false
    
    // Neural Audio & Visual Feedback
    @State private var shakeAmount: CGFloat = 0.0
    @State private var isGlitching = false
    private let soundPulse = SoundPulseManager.shared
    
    // Scene components
    @State private var scene = SCNScene()
    @State private var carNode: SCNNode?
    @State private var cameraNode: SCNNode?
    @State private var trackNode: SCNNode?
    
    // Metal Tech Symbols
    @State private var time: Float = 0.0
    @State private var technique: SCNTechnique?
    
    // Performance metrics
    @State private var frameTime: Double = 0.016
    
    var body: some View {
        ZStack {
            // High-Performance Engine Depth
            SceneView(
                scene: scene,
                pointOfView: cameraNode,
                options: [.autoenablesDefaultLighting, .rendersContinuously]
            )
            .ignoresSafeArea()
            .offset(x: CGFloat.random(in: -shakeAmount...shakeAmount), y: CGFloat.random(in: -shakeAmount...shakeAmount))
            .overlay(
                ZStack {
                    if isGlitching {
                        Color.cyan.opacity(0.15)
                            .blendMode(.screen)
                        
                        ForEach(0..<5) { _ in
                            Rectangle()
                                .fill(LinearGradient(colors: [.clear, [Color.cyan, Color.pink].randomElement()!.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                                .frame(height: CGFloat.random(in: 1...4))
                                .offset(y: CGFloat.random(in: -400...400))
                        }
                    }
                }
                .allowsHitTesting(false)
            )
            .overlay(Color.black.opacity(orchestrator.currentState == .streaming ? 0 : 0.4))
            
            // Pro Controller Layer (Virtual + Physical Support)
            VStack {
                // Header (Minimalist & High-Tech)
                HStack(alignment: .top) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VANTAGE RACING 3D")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Circle().fill(controller.isConnected ? Color.green : Color.white.opacity(0.3)).frame(width: 6, height: 6)
                            Text(controller.isConnected ? "EXT_CONTROLLER: ACTIVE" : "ENGINE_LINK: NEURAL")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Session Runtime
                    HStack(spacing: 8) {
                        TelemetryCapsule(label: "FPS", value: "\(Int(1.0/frameTime))", color: .green)
                        TelemetryCapsule(label: "PNG", value: "\(orchestrator.latency)ms", color: .cyan)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Virtual Control Area (Lower layer to avoid blocking view)
                ZStack {
                    HStack(alignment: .bottom) {
                        // Left: Virtual Joystick (Steering)
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.1), lineWidth: 1).frame(width: 120, height: 120)
                            Circle().fill(Color.white.opacity(0.05)).frame(width: 120, height: 120)
                            Circle()
                                .fill(AppDesignSystem.Colors.primaryGradient)
                                .frame(width: 40, height: 40)
                                .offset(x: CGFloat(steering * 40))
                                .shadow(color: .pink.opacity(0.5), radius: 10)
                        }
                        .padding(.leading, 30)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let limit: CGFloat = 40
                                    steering = Float(max(min(value.translation.width, limit), -limit) / limit)
                                }
                                .onEnded { _ in steering = 0 }
                        )
                        
                        Spacer()
                        
                        // Right: Gas & Brake Pedals (Futuristic Design)
                        VStack(spacing: 12) {
                            // Gas (Throttle)
                            HStack {
                                Spacer()
                                Text("GAS")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                    .rotationEffect(.degrees(-90))
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(throttle > 0 ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                                    .frame(width: 80, height: 120)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15).stroke(throttle > 0 ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                                    )
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in throttle = 1.0 }
                                            .onEnded { _ in throttle = 0.0 }
                                    )
                            }
                            
                            // Brake
                            HStack {
                                Spacer()
                                Text("BRK")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                    .rotationEffect(.degrees(-90))
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(brake > 0 ? Color.red.opacity(0.3) : Color.white.opacity(0.1))
                                    .frame(width: 100, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10).stroke(brake > 0 ? Color.red : Color.white.opacity(0.2), lineWidth: 2)
                                    )
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in brake = 1.0 }
                                            .onEnded { _ in brake = 0.0 }
                                    )
                            }
                        }
                        .padding(.trailing, 30)
                    }
                    .padding(.bottom, 60)
                    
                    // Center Speedometer
                    VStack(spacing: 4) {
                        Text("\(Int(speed * 30))")
                            .font(.system(size: 64, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .shadow(color: .cyan.opacity(0.5), radius: 20)
                        Text("KM/H")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        
                        // Nitro Status
                        Capsule()
                            .fill(Color.cyan.opacity(0.2))
                            .frame(width: 80, height: 6)
                            .overlay(
                                Capsule().fill(Color.cyan).frame(width: CGFloat(speed / 5.0 * 80), height: 6), alignment: .leading
                            )
                            .padding(.top, 8)
                    }
                    .offset(y: 40)
                }
            }
        }
        .onAppear {
            orchestrator.launchSession(for: UUID())
            setupWorld()
            soundPulse.startEngine()
        }
        .onDisappear {
            orchestrator.terminateSession()
            soundPulse.stopEngine()
        }
    }
    
    func setupWorld() {
        // High-End Scene Setup
        scene.background.contents = UIColor.black
        
        // Load Neural Metal Glitch Technique (Direct SCNTechnique Injection)
        if let path = Bundle.main.path(forResource: "NeuralGlitch", ofType: "json"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            technique = SCNTechnique(dictionary: dict)
        }
        
        // Ground with Cyberpunk Neon-Track Texture
        let floor = SCNFloor()
        floor.reflectivity = 0.3
        floor.firstMaterial?.diffuse.contents = UIImage(named: "racing_track_texture_neon_1772241279516.png") ?? UIImage.gridImage(color: .darkGray)
        floor.firstMaterial?.diffuse.wrapS = .repeat
        floor.firstMaterial?.diffuse.wrapT = .repeat
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(20, 20, 1)
        
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
        
        // 📐 CYBERTRUCK ENGINE INJECTION 📐
        let truckNode = SCNNode()
        
        // Brushed Stainless Steel Material
        let steelMaterial = SCNMaterial()
        steelMaterial.diffuse.contents = UIImage(named: "cybertruck_steel_texture_1772241534900.png") ?? UIColor.gray
        steelMaterial.metalness.contents = 1.0
        steelMaterial.roughness.contents = 0.1
        steelMaterial.specular.contents = UIColor.white
        
        // Chassis (Lower Block)
        let chassis = SCNBox(width: 2.1, height: 0.7, length: 4.8, chamferRadius: 0)
        chassis.materials = [steelMaterial]
        let chassisNode = SCNNode(geometry: chassis)
        truckNode.addChildNode(chassisNode)
        
        // The Wedge (Upper Roof)
        let roof = SCNPyramid(width: 2.1, height: 0.9, length: 4.0)
        roof.materials = [steelMaterial]
        let roofNode = SCNNode(geometry: roof)
        roofNode.position = SCNVector3(0, 0.35, -0.2) // Offset to the front/mid
        roofNode.eulerAngles = SCNVector3(0, 0, 0)
        truckNode.addChildNode(roofNode)
        
        // Cyber Light Bar (Front)
        let lightBar = SCNBox(width: 1.8, height: 0.05, length: 0.1, chamferRadius: 0)
        lightBar.firstMaterial?.emission.contents = UIColor.white
        lightBar.firstMaterial?.diffuse.contents = UIColor.white
        let lightBarNode = SCNNode(geometry: lightBar)
        lightBarNode.position = SCNVector3(0, 0.2, 2.45)
        truckNode.addChildNode(lightBarNode)
        
        // Red Rear Light Bar
        let tailBar = SCNBox(width: 1.8, height: 0.05, length: 0.1, chamferRadius: 0)
        tailBar.firstMaterial?.emission.contents = UIColor.red
        tailBar.firstMaterial?.diffuse.contents = UIColor.red
        let tailBarNode = SCNNode(geometry: tailBar)
        tailBarNode.position = SCNVector3(0, 0.1, -2.45)
        truckNode.addChildNode(tailBarNode)

        carNode = truckNode
        carNode?.position = SCNVector3(0, 0.4, 0)
        scene.rootNode.addChildNode(carNode!)
        
        // Underglow effect (Neural Cyan)
        let underglow = SCNPlane(width: 2.2, height: 5.0)
        underglow.firstMaterial?.diffuse.contents = UIColor.clear
        underglow.firstMaterial?.emission.contents = UIColor.cyan.withAlphaComponent(0.8)
        let lightNode = SCNNode(geometry: underglow)
        lightNode.position = SCNVector3(0, 0.05, 0)
        lightNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        carNode?.addChildNode(lightNode)
        
        // Camera (Strategic TPS)
        cameraNode = SCNNode()
        cameraNode?.camera = SCNCamera()
        cameraNode?.camera?.fieldOfView = 80
        cameraNode?.camera?.zFar = 1000
        cameraNode?.position = SCNVector3(0, 3.5, 7) // Lower, more dynamic angle
        cameraNode?.eulerAngles = SCNVector3(-0.35, Float.pi, 0)
        carNode?.addChildNode(cameraNode!)
        
        // World Objects (Neon Markers)
        for _ in 0..<50 {
            let p = SCNBox(width: 0.5, height: 4, length: 0.5, chamferRadius: 0)
            p.firstMaterial?.emission.contents = [UIColor.magenta, UIColor.cyan].randomElement()!
            let pNode = SCNNode(geometry: p)
            pNode.position = SCNVector3(Float.random(in: -30...30), 2, Float.random(in: 20...500))
            scene.rootNode.addChildNode(pNode)
        }
        
        // Main Loop
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            updatePhysics()
        }
    }
    
    func updatePhysics() {
        guard let car = carNode else { return }
        
        // Combine Inputs (Physical Controller + Virtual)
        let finalSteering = controller.isConnected ? controller.leftThumbstickX : steering
        let finalThrottle = controller.isConnected ? controller.rightTrigger : throttle
        let finalBrake = controller.isConnected ? controller.leftTrigger : brake
        
        // Acceleration Modifiers
        let accelerationRate: Float = 0.06
        let friction: Float = 0.015
        let maxSpd: Float = 12.0
        
        if finalThrottle > 0 {
            speed = min(speed + (accelerationRate * finalThrottle), maxSpd)
        } else if finalBrake > 0 {
            speed = max(speed - (0.2 * finalBrake), 0)
            triggerHaptic(style: .heavy)
        } else {
            speed = max(speed - friction, 0)
        }
        
        // Neural Pulse Audio Injection
        soundPulse.updateEngine(speed: speed, throttle: finalThrottle)
        
        // Steering Math (Ackermann-lite)
        if speed > 0.1 {
            let turnRadius = 0.04 * (speed / 10.0)
            car.eulerAngles.y -= finalSteering * turnRadius
            car.eulerAngles.z = -finalSteering * 0.15 
        }
        
        // Position Injection
        let angle = car.eulerAngles.y
        car.position.x += sin(angle) * speed
        car.position.z += cos(angle) * speed
        
        // CameraDynamics (Matching user video transition)
        if speed > 1.0 {
            cameraNode?.camera?.fieldOfView = CGFloat(80 + (speed * 3.5))
            shakeAmount = CGFloat(speed * 0.15)
            
            // Random Glitch "Spikes"
            if speed > 8.0 && Int.random(in: 0...100) == 0 {
                isGlitching = true
                soundPulse.playGlitch()
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    isGlitching = false
                }
            }
        } else {
            cameraNode?.camera?.fieldOfView = 80
            shakeAmount = 0
        }
        
        // Pass Neural Pulse Data to Metal Pipeline
        time += 0.016
        technique?.setValue(time as NSNumber, forKey: "time_symbol")
        technique?.setValue((isGlitching ? 0.8 : 0.0) as NSNumber, forKey: "intensity_symbol")
        
        // Physics Loop (Telemetry)
        frameTime = 0.016
    }
    
    func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct TelemetryCapsule: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    VantageRacing3DView()
}

extension UIImage {
    static func gridImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        color.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 100, y: 0))
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 100))
        path.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
