import SwiftUI
import PhotosUI

struct AIProductionView: View {
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var castImages: [UIImage] = []
    @State private var projectName = ""
    @State private var scriptPrompt = ""
    @State private var isGenerating = false
    @State private var generationProgress: CGFloat = 0.0
    @State private var showingLibrary = false
    @State private var selectedResolution = "4K"
    @State private var selectedDimension = "4D"
    @State private var tunvisionEnabled = true
    @StateObject private var service = ProductionService.shared
    @FocusState private var focusedField: Field?
    
    enum Field {
        case projectName
        case scriptPrompt
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TRUEWORLD AI")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                                
                                Text("PRODUCTION STUDIO")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "film.stack.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AppDesignSystem.Colors.primaryGradient)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Main Action: Create New Film
                    VStack(alignment: .leading, spacing: 20) {
                        Text("START NEW PROJECT")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal)
                        
                        VStack(spacing: 20) {
                            // Project Name Input
                            CustomTextField(placeholder: "Project Title (e.g. Cyberpunk Destiny)", text: $projectName, icon: "pencil.line")
                                .glassy(cornerRadius: 16)
                                .focused($focusedField, equals: .projectName)
                            
                            // Genre Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Genre Template")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        GenreChip(title: "Cyberpunk", icon: "bolt.fill", isSelected: scriptPrompt.contains("Cyberpunk")) {
                                            scriptPrompt = "A futuristic cyberpunk tale set in Neo-Tokyo. High stakes, neon lights, and neural implants."
                                        }
                                        GenreChip(title: "Space Opera", icon: "star.fill", isSelected: scriptPrompt.contains("Space")) {
                                            scriptPrompt = "An epic space odyssey across the Andromeda galaxy. Forbidden planets and ancient starships."
                                        }
                                        GenreChip(title: "Noir", icon: "moon.fill", isSelected: scriptPrompt.contains("Noir")) {
                                            scriptPrompt = "A gritty 1940s detective noir. Shadows, rain-slicked streets, and a mysterious femme fatale."
                                        }
                                        GenreChip(title: "High Fantasy", icon: "wand.and.stars", isSelected: scriptPrompt.contains("Fantasy")) {
                                            scriptPrompt = "A world of magic and dragons. A forgotten prophecy and an unlikely hero."
                                        }
                                    }
                                }
                            }
                            
                            // Engine Mode (Model Selection)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("NEURAL ENGINE MODE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                HStack(spacing: 0) {
                                    ModelOption(id: "gen4_turbo", title: "GEN-4", subtitle: "Speed", isSelected: service.selectedModel == "gen4_turbo") {
                                        service.selectedModel = "gen4_turbo"
                                    }
                                    
                                    ModelOption(id: "veo3.1", title: "VEO 3.1", subtitle: "Cinema", isSelected: service.selectedModel == "veo3.1") {
                                        service.selectedModel = "veo3.1"
                                    }
                                }
                                .padding(4)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                            }
                            
                            // Neural Specs (Resolution & Dimension)
                            VStack(alignment: .leading, spacing: 20) {
                                Text("NEURAL OUTPUT SPECS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("RESOLUTION")
                                            .font(.system(size: 8, weight: .black))
                                            .foregroundColor(.white.opacity(0.3))
                                        
                                        Picker("Res", selection: $selectedResolution) {
                                            Text("10K IMAX").tag("10K_IMAX")
                                            Text("10K NEURAL").tag("10K_NEURAL")
                                            Text("10K CINEMA").tag("10K_CINEMA")
                                            Text("8K").tag("8K")
                                            Text("4K").tag("4K")
                                        }
                                        .pickerStyle(.menu)
                                        .tint(AppDesignSystem.Colors.vibrantBlue)
                                        .scaleEffect(0.9)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("DIMENSION")
                                            .font(.system(size: 8, weight: .black))
                                            .foregroundColor(.white.opacity(0.3))
                                        
                                        Picker("Dim", selection: $selectedDimension) {
                                            Text("10D NEURAL").tag("10D_NEURAL")
                                            Text("10D").tag("10D")
                                            Text("8D").tag("8D")
                                            Text("4D").tag("4D")
                                        }
                                        .pickerStyle(.menu)
                                        .tint(AppDesignSystem.Colors.vibrantPink)
                                        .scaleEffect(0.9)
                                    }
                                }
                                
                                Toggle(isOn: $tunvisionEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("TUNVISION™ ENHANCEMENT")
                                            .font(.system(size: 12, weight: .black, design: .monospaced))
                                        Text("Proprietary neural upscaling and color grading")
                                            .font(.system(size: 8))
                                            .opacity(0.5)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: AppDesignSystem.Colors.vibrantBlue))
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            
                            // Script/Prompt Input
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "text.quote")
                                        .foregroundColor(AppDesignSystem.Colors.vibrantPink)
                                    Text("Neural Script Prompt")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                ZStack(alignment: .topLeading) {
                                    if scriptPrompt.isEmpty {
                                        Text("Describe the genre, tone, and opening scene...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.3))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                    
                                    TextEditor(text: $scriptPrompt)
                                        .focused($focusedField, equals: .scriptPrompt)
                                        .frame(height: 120)
                                        .scrollContentBackground(.hidden)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedField == .scriptPrompt ? AppDesignSystem.Colors.vibrantBlue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
                                }
                                .id("scriptPrompt")
                                
                                Text("Describe the genre, tone, and opening scene.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .padding(24)
                        .glassy(cornerRadius: 24)
                        .padding(.horizontal)
                    }
                    
                    // Cast Yourself Section (Photo Uploads)
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("CAST YOURSELF (UP TO 5)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("\(castImages.count)/5")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(castImages.count == 5 ? .green : .white.opacity(0.3))
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Existing cast members
                                ForEach(0..<castImages.count, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: castImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 140)
                                            .cornerRadius(16)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppDesignSystem.Colors.vibrantBlue.opacity(0.3), lineWidth: 1))
                                        
                                        Button(action: { castImages.remove(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.black))
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                                
                                // Add button
                                if castImages.count < 5 {
                                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5 - castImages.count, matching: .images) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "plus.viewfinder")
                                                .font(.system(size: 30))
                                            Text("Add Member")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .frame(width: 100, height: 140)
                                        .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                                .foregroundColor(AppDesignSystem.Colors.vibrantBlue.opacity(0.3))
                                        )
                                    }
                                    .onChange(of: selectedPhotos) { _ in
                                        Task {
                                            for item in selectedPhotos {
                                                if let data = try? await item.loadTransferable(type: Data.self),
                                                   let image = UIImage(data: data) {
                                                    castImages.append(image)
                                                }
                                            }
                                            selectedPhotos = []
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Generate Button (UNLOCKED)
                    VStack(spacing: 12) {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            startGeneration()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles.tv.fill")
                                    .font(.system(size: 22))
                                
                                Text("GENERATE NEURAL FILM")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                ZStack {
                                    AppDesignSystem.Colors.primaryGradient
                                    
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            )
                            .cornerRadius(22)
                            .shadow(color: AppDesignSystem.Colors.vibrantBlue.opacity(0.3), radius: 20, x: 0, y: 10)
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                        .disabled(isGenerating || projectName.isEmpty || castImages.isEmpty)
                        .opacity(isGenerating || projectName.isEmpty || castImages.isEmpty ? 0.6 : 1.0)
                        
                        Text(isGenerating ? "NEURAL ENGINE ACTIVE" : "ENGINE READY FOR 10K RENDER")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(isGenerating ? .cyan : .white.opacity(0.3))
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                .onChange(of: focusedField) { field in
                    if field == .scriptPrompt {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring()) {
                                proxy.scrollTo("scriptPrompt", anchor: .center)
                            }
                        }
                    }
                }
                
                if isGenerating {
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            Capsule()
                                .fill(AppDesignSystem.Colors.vibrantBlue)
                                .frame(width: 300 * generationProgress, height: 6)
                        }
                        .frame(width: 300)
                        
                        Text("Neural Engine processing frames...")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .transition(.opacity)
                }
                
                // Neural Scene Preview - "Imagination" Feed
                VStack(alignment: .leading, spacing: 20) {
                    Text("NEURAL SCENE PREVIEW")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 140, height: 80)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "cpu")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppDesignSystem.Colors.vibrantBlue.opacity(0.4))
                                            Text("SCENE \(i+1)")
                                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.2))
                                        }
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recent Feed/Dashboard Section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("RECENT PRODUCTIONS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                        Button("VIEW ALL") { showingLibrary = true }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppDesignSystem.Colors.vibrantBlue)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ProductionCard(title: "Neon Shadows", character: "Detective V", category: "CYBERPUNK", color: .purple)
                            ProductionCard(title: "Martian Sands", character: "Captain Nova", category: "SCI-FI", color: .orange)
                            ProductionCard(title: "Ancient Echoes", character: "The Explorer", category: "ADVENTURE", color: .green)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 120)
            }
            .padding(.top, 40)
        }
        .sheet(isPresented: $showingLibrary) {
            ProductionLibraryView()
        }
    }
    
    private func startGeneration() {
        Task {
            withAnimation(.spring()) { isGenerating = true; generationProgress = 0.1 }
            
            do {
                // 1. Prepare cast data
                let castData = castImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
                
                // 2. Trigger Production (Upload -> Script Gen -> DB)
                _ = try await service.createProduction(
                    title: projectName,
                    prompt: scriptPrompt,
                    genre: "Cyberpunk", 
                    castImages: castData,
                    resolution: selectedResolution,
                    dimension: selectedDimension,
                    isTunvision: tunvisionEnabled
                )
                
                withAnimation { generationProgress = 1.0 }
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                withAnimation {
                    isGenerating = false
                    projectName = ""
                    scriptPrompt = ""
                    castImages = []
                }
            } catch {
                print("Generation Error: \(error)")
                withAnimation { isGenerating = false }
            }
        }
    }
}

struct GenreChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? AnyShapeStyle(AppDesignSystem.Colors.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.1)))
            .foregroundColor(.white)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}


struct ModelOption: View {
    let id: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                Text(subtitle)
                    .font(.system(size: 8, weight: .bold))
                    .opacity(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? AnyShapeStyle(AppDesignSystem.Colors.primaryGradient) : AnyShapeStyle(Color.clear))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .animation(.spring(), value: isSelected)
    }
}

struct ProductionCard: View {
    let title: String
    let character: String
    let category: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(color.opacity(0.1))
                    .frame(width: 220, height: 280)
                
                // Placeholder for AI movie poster
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                }
                .padding(20)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 12)).foregroundColor(color))
                
                VStack(alignment: .leading) {
                    Text("STAR CHARACTER")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    Text(character)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    AIProductionView()
}

