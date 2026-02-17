import SwiftUI

struct FlashingView: View {
    @EnvironmentObject var viewModel: FlasherViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Step counter header
            HStack {
                Image(systemName: stepIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.vistaBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stepTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textDark)
                    Text("Step \(currentStepNumber) of 5")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.vistaBlue)
                }
                Spacer()
            }
            .padding(.bottom, 20)
            
            // Steps panel
            VistaPanel {
                VStack(alignment: .leading, spacing: 12) {
                    StepItem(number: 1, title: "Checking system", step: .checking, currentStep: viewModel.currentStep)
                    StepItem(number: 2, title: "Downloading firmware", step: .downloading, currentStep: viewModel.currentStep)
                    StepItem(number: 3, title: "Extracting files", step: .extracting, currentStep: viewModel.currentStep)
                    StepItem(number: 4, title: "Waiting for device", step: .waitingForDevice, currentStep: viewModel.currentStep)
                    StepItem(number: 5, title: "Flashing device", step: .flashing, currentStep: viewModel.currentStep)
                    
                    if !viewModel.statusMessage.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                            Text(viewModel.statusMessage)
                                .font(.system(size: 11))
                                .foregroundColor(.textMedium)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Safety indicator + Cancel
            HStack {
                if viewModel.isCancellationSafe {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.vistaGreen)
                    Text("Safe to cancel")
                        .font(.system(size: 11))
                        .foregroundColor(.textMedium)
                } else {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.vistaRed)
                    Text("Do not disconnect!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.vistaRed)
                }
                
                Spacer()
                
                VistaButton(title: "Cancel", icon: "xmark", action: {
                    viewModel.cancelFlashing()
                }, style: viewModel.isCancellationSafe ? .secondary : .danger)
            }
        }
    }
    
    private var currentStepNumber: Int {
        switch viewModel.currentStep {
        case .checking: return 1
        case .downloading: return 2
        case .extracting: return 3
        case .waitingForDevice: return 4
        case .flashing: return 5
        case .complete: return 5
        }
    }
    
    private var stepIcon: String {
        switch viewModel.currentStep {
        case .checking: return "magnifyingglass"
        case .downloading: return "arrow.down.circle.fill"
        case .extracting: return "archivebox.fill"
        case .waitingForDevice: return "cable.connector"
        case .flashing: return "bolt.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }
    
    private var stepTitle: String {
        switch viewModel.currentStep {
        case .checking: return "Checking..."
        case .downloading: return "Downloading"
        case .extracting: return "Extracting"
        case .waitingForDevice: return "Waiting"
        case .flashing: return "Flashing"
        case .complete: return "Complete"
        }
    }
}

struct StepItem: View {
    let number: Int
    let title: String
    let step: FlashStep
    let currentStep: FlashStep
    
    private var state: StepState {
        if step.rawValue < currentStep.rawValue {
            return .complete
        } else if step == currentStep {
            return .active
        } else {
            return .pending
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Step indicator circle
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 26, height: 26)
                
                if state == .complete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(state == .active ? .white : .textLight)
                }
            }
            
            Text(title)
                .font(.system(size: 13, weight: state == .active ? .semibold : .regular))
                .foregroundColor(textColor)
            
            Spacer()
            
            // Status indicator
            if state == .active {
                ProgressView()
                    .scaleEffect(0.6)
            } else if state == .complete {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.vistaGreen)
            }
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .complete: return .vistaGreen
        case .active: return .vistaBlue
        case .pending: return Color.gray.opacity(0.25)
        }
    }
    
    private var textColor: Color {
        switch state {
        case .complete: return .textDark
        case .active: return .textDark
        case .pending: return .textLight
        }
    }
    
    private enum StepState {
        case pending, active, complete
    }
}
