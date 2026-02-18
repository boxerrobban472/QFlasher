import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FlasherViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Aero glass title bar
            AeroTitleBar(title: "QFlasher – Arduino UNO Q Recovery")
            
            // Content area
            ZStack {
                Color.contentBg
                
                Group {
                    switch viewModel.state {
                    case .welcome:
                        WelcomeView()
                    case .jumperInstruction:
                        JumperInstructionView()
                    case .waitingForDevice:
                        WaitingForDeviceView()
                    case .downloading, .flashing:
                        FlashingView()
                    case .complete:
                        CompletionView()
                    case .error:
                        ErrorView()
                    }
                }
                .padding(20)
            }
        }
        .background(Color.contentBg)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Aero Glass Title Bar

struct AeroTitleBar: View {
    let title: String
    
    var body: some View {
        ZStack {
            // Glass gradient background
            LinearGradient(
                colors: [
                    Color.aeroHighlight.opacity(0.6),
                    Color.aeroTop,
                    Color.aeroBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Glass shine overlay (top half)
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.white.opacity(0.45), Color.white.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 16)
                Spacer()
            }
            
            // Title and icon
            HStack(spacing: 10) {
                // Q icon
                Image(nsImage: loadAppIcon())
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 22, height: 22)
                
                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                
                Spacer()
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 32)
        .overlay(WindowDragGesture())
    }
    
    private func loadAppIcon() -> NSImage {
        // Try to load from bundle Resources
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
           let image = NSImage(contentsOfFile: path) {
            return image
        }
        // Fallback
        return NSImage(systemSymbolName: "q.circle.fill", accessibilityDescription: "Q") ?? NSImage()
    }
}

struct WindowDragGesture: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class DraggableView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

// MARK: - Vista-Style Button

struct VistaButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var style: VistaButtonStyle = .primary
    
    enum VistaButtonStyle {
        case primary, secondary, danger
    }
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(isPressed ? 0.05 : 0.15), radius: isPressed ? 0 : 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: isHovered ? [Color(hex: "C0E0FF"), Color(hex: "70B8FF")] : [Color(hex: "B0D8FF"), Color(hex: "5098E0")],
                startPoint: .top, endPoint: .bottom
            )
        case .secondary:
            LinearGradient(
                colors: isHovered ? [.white, Color(hex: "D8D8D8")] : [Color(hex: "FAFAFA"), Color(hex: "E8E8E8")],
                startPoint: .top, endPoint: .bottom
            )
        case .danger:
            LinearGradient(
                colors: isHovered ? [Color(hex: "FF9090"), Color(hex: "E05050")] : [Color(hex: "FF7070"), Color(hex: "D94040")],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return Color(hex: "1A3A5C")
        case .secondary: return .textDark
        case .danger: return .white
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary: return Color(hex: "3070A8")
        case .secondary: return Color(hex: "A8A8A8")
        case .danger: return Color(hex: "A03030")
        }
    }
}

// MARK: - Vista Panel

struct VistaPanel<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(hex: "C8C8C8"), lineWidth: 1)
            )
    }
}

// MARK: - Vista Progress Bar

struct VistaProgressBar: View {
    let progress: Double
    var animated: Bool = true
    
    @State private var stripeOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(
                        colors: [Color(hex: "DFDFDF"), Color(hex: "EFEFEF"), Color(hex: "DFDFDF")],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color(hex: "A0A0A0"), lineWidth: 1)
                    )
                
                // Fill
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LinearGradient(
                            colors: [Color(hex: "B8F0B8"), Color(hex: "70D070"), Color(hex: "50B850")],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: max(4, geo.size.width * min(progress, 1.0) - 4))
                        .overlay(
                            animated ? AnyView(AnimatedStripes(offset: $stripeOffset)) : AnyView(EmptyView())
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 1))
                        .padding(2)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
        }
        .frame(height: 20)
        .onAppear {
            if animated {
                withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
                    stripeOffset = 16
                }
            }
        }
    }
}

struct AnimatedStripes: View {
    @Binding var offset: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let w: CGFloat = 8
                for x in stride(from: -size.height + offset, to: size.width + size.height, by: w * 2) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height + w, y: 0))
                    path.addLine(to: CGPoint(x: x + w, y: size.height))
                    path.closeSubpath()
                    ctx.fill(path, with: .color(.white.opacity(0.35)))
                }
            }
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Color.vistaGreen : Color.vistaOrange)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle().stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            
            Text(isConnected ? "Device connected" : "No device detected")
                .font(.system(size: 11))
                .foregroundColor(.textMedium)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FlasherViewModel())
        .frame(width: 480, height: 400)
}
