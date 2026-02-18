import Foundation
import Combine

enum AppState: Equatable {
    case welcome
    case jumperInstruction
    case waitingForDevice
    case downloading(progress: String)
    case flashing(progress: String)
    case complete
    case error(message: String)
}

@MainActor
class FlasherViewModel: ObservableObject {
    @Published var state: AppState = .welcome
    @Published var isDeviceConnected: Bool = false
    @Published var latestVersion: String = ""
    @Published var statusMessage: String = ""
    @Published var currentStep: FlashStep = .checking
    @Published var isCancellationSafe: Bool = true
    @Published var progress: Double = 0.0
    @Published var errorMessage: String? = nil
    
    private let usbMonitor = USBMonitor()
    private let flasherCLI = FlasherCLI()
    private var cancellables = Set<AnyCancellable>()
    private var flashTask: Task<Void, Never>?
    
    init() {
        setupUSBMonitoring()
        fetchLatestVersion()
    }
    
    private func setupUSBMonitoring() {
        usbMonitor.$isEDLDeviceConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isDeviceConnected = connected
                self?.handleDeviceConnectionChange(connected)
            }
            .store(in: &cancellables)
        
        usbMonitor.startMonitoring()
    }
    
    private func handleDeviceConnectionChange(_ connected: Bool) {
        // Auto-advance from waiting state when device connects
        if connected && state == .waitingForDevice {
            startFlashing()
        }
    }
    
    private func fetchLatestVersion() {
        Task {
            do {
                let versions = try await flasherCLI.listVersions()
                if let latest = versions.latest {
                    latestVersion = latest.version
                }
            } catch {
                print("Failed to fetch versions: \(error)")
            }
        }
    }
    
    // MARK: - User Actions
    
    func beginSetup() {
        state = .jumperInstruction
    }
    
    func confirmJumperConnected() {
        state = .waitingForDevice
        statusMessage = "Connect your Arduino UNO Q via USB..."
        
        // If device is already connected, start immediately
        if isDeviceConnected {
            startFlashing()
        }
    }
    
    func startFlashing() {
        state = .downloading(progress: "Preparing...")
        statusMessage = "Starting flash process..."
        progress = 0.0
        
        flashTask = Task {
            await performFlash()
        }
    }
    
    private func performFlash() async {
        for await update in flasherCLI.flashLatest() {
            guard !Task.isCancelled else { return }
            
            switch update {
            case .step(let step, let message):
                currentStep = step
                statusMessage = message
                isCancellationSafe = step.isCancellationSafe
                
                // Update progress - parse percentage from message if available
                let stepPercent = parsePercentage(from: message)
                
                switch step {
                case .checking:
                    progress = 0.02
                case .downloading:
                    // Downloading is 0.05 to 0.45 (40% of total)
                    if let pct = stepPercent {
                        progress = 0.05 + (pct * 0.40)
                    } else if progress < 0.05 {
                        progress = 0.05  // Just started
                    }
                case .extracting:
                    // Extracting is 0.45 to 0.55 (10% of total)
                    if let pct = stepPercent {
                        progress = 0.45 + (pct * 0.10)
                    } else if progress < 0.45 {
                        progress = 0.45  // Just started extracting
                    }
                case .waitingForDevice:
                    progress = 0.55
                case .flashing:
                    // Flashing is 0.55 to 0.95 (40% of total)
                    if let pct = stepPercent {
                        progress = 0.55 + (pct * 0.40)
                    } else if progress < 0.55 {
                        progress = 0.55  // Just started flashing
                    }
                case .complete:
                    progress = 1.0
                }
                
                // Update app state based on step
                switch step {
                case .checking, .downloading, .extracting:
                    state = .downloading(progress: message)
                case .waitingForDevice:
                    state = .waitingForDevice
                case .flashing:
                    state = .flashing(progress: message)
                case .complete:
                    state = .complete
                }
                
            case .success:
                currentStep = .complete
                state = .complete
                progress = 1.0
                statusMessage = "Flash completed successfully!"
                isCancellationSafe = true
                
            case .error(let message):
                state = .error(message: message)
                errorMessage = message
                statusMessage = message
                isCancellationSafe = true
            }
        }
    }
    
    func goBack() {
        switch state {
        case .jumperInstruction:
            state = .welcome
        case .waitingForDevice:
            state = .jumperInstruction
        default:
            break
        }
    }
    
    func cancelFlashing() {
        flashTask?.cancel()
        flashTask = nil
        state = .welcome
        statusMessage = ""
        currentStep = .checking
        progress = 0.0
        isCancellationSafe = true
    }
    
    func retryFlashing() {
        errorMessage = nil
        state = .jumperInstruction
        statusMessage = ""
        currentStep = .checking
        progress = 0.0
    }
    
    func reset() {
        state = .welcome
        statusMessage = ""
        currentStep = .checking
        progress = 0.0
        isCancellationSafe = true
        errorMessage = nil
    }
    
    // MARK: - Helpers
    
    /// Parse percentage from status message like "Downloading: 45%" or "45% |████"
    private func parsePercentage(from text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)\s*%"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text),
              let value = Double(text[range]) else {
            return nil
        }
        return value / 100.0
    }
}
