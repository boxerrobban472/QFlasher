import SwiftUI

@main
struct QFlasherApp: App {
    @StateObject private var viewModel = FlasherViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .frame(width: 700, height: 650)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 700, height: 650)
    }
}

// MARK: - Vista/Aero Color Theme
extension Color {
    // Glass title bar gradient
    static let aeroTop = Color(hex: "4A90D9")
    static let aeroBottom = Color(hex: "2968B0")
    static let aeroHighlight = Color(hex: "A8D4FF")
    
    // Content area
    static let contentBg = Color(hex: "F0F0F0")
    static let panelBg = Color.white
    
    // Text
    static let textDark = Color(hex: "1A1A1A")
    static let textMedium = Color(hex: "444444")
    static let textLight = Color(hex: "666666")
    static let textOnGlass = Color.white
    
    // Accents
    static let vistaBlue = Color(hex: "0078D4")
    static let vistaGreen = Color(hex: "5CB85C")
    static let vistaOrange = Color(hex: "F0AD4E")
    static let vistaRed = Color(hex: "D9534F")
    
    // Button gradients
    static let buttonTop = Color(hex: "FFFFFF")
    static let buttonBottom = Color(hex: "E0E0E0")
    static let buttonBorder = Color(hex: "707070")
    
    // Shadows
    static let shadowColor = Color.black.opacity(0.2)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
