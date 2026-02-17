import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var viewModel: FlasherViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon
            HStack(spacing: 16) {
                Image(nsImage: loadIcon())
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arduino UNO Q")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textDark)
                    
                    Text("Recovery & Flash Tool")
                        .font(.system(size: 14))
                        .foregroundColor(.textMedium)
                }
                Spacer()
            }
            .padding(.bottom, 20)
            
            VistaPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("This tool will flash the latest Debian image to your Arduino UNO Q board.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMedium)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.vistaBlue)
                        Text("Latest version:")
                            .font(.system(size: 12))
                            .foregroundColor(.textMedium)
                        Text(viewModel.latestVersion.isEmpty ? "Checking..." : viewModel.latestVersion)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textDark)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.vistaBlue)
                        Text("Requires ~12 GB free disk space")
                            .font(.system(size: 12))
                            .foregroundColor(.textMedium)
                        Spacer()
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                VistaButton(title: "Flash My Board", icon: "bolt.fill", action: {
                    viewModel.beginSetup()
                })
            }
        }
    }
    
    private func loadIcon() -> NSImage {
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
           let image = NSImage(contentsOfFile: path) {
            return image
        }
        return NSImage(systemSymbolName: "q.circle.fill", accessibilityDescription: "Q") ?? NSImage()
    }
}
