import SwiftUI

struct JumperInstructionView: View {
    @EnvironmentObject var viewModel: FlasherViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.vistaOrange)
                Text("Prepare Your Board")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textDark)
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Board image and instructions
            VistaPanel {
                VStack(spacing: 12) {
                    // Board image
                    BoardImageView()
                        .frame(maxHeight: 350)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        InstructionStep(number: 1, text: "Disconnect power from your board")
                        InstructionStep(number: 2, text: "Short the 2 highlighted pins with a jumper", highlight: true)
                        InstructionStep(number: 3, text: "Connect via USB to this Mac")
                    }
                }
            }
            
            // Warning box
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.vistaOrange)
                    .font(.system(size: 14))
                Text("Keep jumper connected until flashing completes!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textDark)
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.vistaOrange.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.vistaOrange.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.top, 10)
            
            Spacer()
            
            // Device status
            HStack {
                StatusIndicator(isConnected: viewModel.isDeviceConnected)
                Spacer()
            }
            .padding(.bottom, 10)
            
            // Buttons
            HStack {
                VistaButton(title: "Back", icon: "chevron.left", action: {
                    viewModel.goBack()
                }, style: .secondary)
                
                Spacer()
                
                VistaButton(title: "Continue", icon: "chevron.right", action: {
                    viewModel.startFlashing()
                })
                .opacity(viewModel.isDeviceConnected ? 1 : 0.5)
                .disabled(!viewModel.isDeviceConnected)
            }
        }
    }
}

struct BoardImageView: View {
    @State private var boardImage: NSImage? = nil
    
    var body: some View {
        Group {
            if let image = boardImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(4)
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            Text("Board diagram")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Try multiple approaches to load the image
        if let path = Bundle.main.path(forResource: "flash-uno-q", ofType: "png") {
            boardImage = NSImage(contentsOfFile: path)
        } else if let url = Bundle.main.url(forResource: "flash-uno-q", withExtension: "png") {
            boardImage = NSImage(contentsOf: url)
        } else if let resourcePath = Bundle.main.resourcePath {
            let imagePath = (resourcePath as NSString).appendingPathComponent("flash-uno-q.png")
            boardImage = NSImage(contentsOfFile: imagePath)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    var highlight: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(highlight ? Color.vistaOrange : Color.vistaBlue)
                    .frame(width: 20, height: 20)
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(highlight ? .textDark : .textMedium)
                .fontWeight(highlight ? .medium : .regular)
        }
    }
}
