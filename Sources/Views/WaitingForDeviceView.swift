import SwiftUI

struct WaitingForDeviceView: View {
    @EnvironmentObject var viewModel: FlasherViewModel
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated waiting indicator
            ZStack {
                Circle()
                    .stroke(Color.vistaBlue.opacity(0.2), lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(Color.vistaBlue.opacity(pulseAnimation ? 0.0 : 0.6), lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)
                
                Image(systemName: "cable.connector")
                    .font(.system(size: 32))
                    .foregroundColor(.vistaBlue)
            }
            .padding(.bottom, 20)
            
            Text("Waiting for Device")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textDark)
                .padding(.bottom, 8)
            
            Text("Connect your Arduino UNO Q in EDL mode")
                .font(.system(size: 12))
                .foregroundColor(.textMedium)
            
            Spacer()
            
            VistaPanel {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.vistaOrange)
                    Text("Make sure the jumper is connected before plugging in USB")
                        .font(.system(size: 11))
                        .foregroundColor(.textMedium)
                    Spacer()
                }
            }
            
            HStack {
                VistaButton(title: "Cancel", icon: "xmark", action: {
                    viewModel.cancelFlashing()
                }, style: .secondary)
                Spacer()
            }
            .padding(.top, 16)
        }
        .onAppear {
            pulseAnimation = true
        }
    }
}
