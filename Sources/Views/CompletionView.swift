import SwiftUI

struct CompletionView: View {
    @EnvironmentObject var viewModel: FlasherViewModel
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var checkmarkOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.vistaGreen.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(Color.vistaGreen)
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.vistaGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)
            }
            .padding(.bottom, 24)
            
            Text("Flash Complete!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textDark)
                .padding(.bottom, 8)
            
            Text("Your Arduino UNO Q is ready to use")
                .font(.system(size: 14))
                .foregroundColor(.textMedium)
            
            Spacer()
            
            VistaPanel {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.vistaBlue)
                        Text("Remove the jumper wire from JCTL")
                            .font(.system(size: 12))
                            .foregroundColor(.textDark)
                    }
                    HStack {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.vistaBlue)
                        Text("Disconnect and reconnect USB")
                            .font(.system(size: 12))
                            .foregroundColor(.textDark)
                    }
                    HStack {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.vistaBlue)
                        Text("Your board will boot into Debian Linux")
                            .font(.system(size: 12))
                            .foregroundColor(.textDark)
                    }
                }
            }
            
            HStack {
                Spacer()
                VistaButton(title: "Done", icon: "checkmark", action: {
                    viewModel.reset()
                })
            }
            .padding(.top, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }
}
