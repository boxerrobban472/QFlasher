import SwiftUI

struct ErrorView: View {
    @EnvironmentObject var viewModel: FlasherViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.vistaRed.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Circle()
                    .fill(Color.vistaRed)
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.vistaRed.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: "xmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
            
            Text("Something Went Wrong")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textDark)
                .padding(.bottom, 8)
            
            Text("The flash process encountered an error")
                .font(.system(size: 13))
                .foregroundColor(.textMedium)
            
            Spacer()
            
            // Error details panel
            VistaPanel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.vistaRed)
                        Text("Error Details")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textDark)
                        Spacer()
                    }
                    
                    Text(viewModel.errorMessage ?? "Unknown error")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.textMedium)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            
            // Buttons
            HStack {
                VistaButton(title: "Start Over", icon: "arrow.counterclockwise", action: {
                    viewModel.reset()
                }, style: .secondary)
                
                Spacer()
                
                VistaButton(title: "Try Again", icon: "arrow.clockwise", action: {
                    viewModel.retryFlashing()
                })
            }
            .padding(.top, 16)
        }
    }
}
