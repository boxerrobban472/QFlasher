import Foundation
import IOKit
import IOKit.usb
import Combine

/// Monitors USB device connections for Qualcomm EDL mode devices
class USBMonitor: ObservableObject {
    @Published var isEDLDeviceConnected: Bool = false
    
    // Qualcomm EDL Mode USB identifiers
    private let qualcommVendorID: Int = 0x05C6
    private let edlProductID: Int = 0x9008
    
    private var notificationPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        // Check if device is already connected
        checkForExistingDevice()
        
        // Set up notification for device connections
        setupUSBNotifications()
    }
    
    func stopMonitoring() {
        if addedIterator != 0 {
            IOObjectRelease(addedIterator)
            addedIterator = 0
        }
        if removedIterator != 0 {
            IOObjectRelease(removedIterator)
            removedIterator = 0
        }
        if let port = notificationPort {
            IONotificationPortDestroy(port)
            notificationPort = nil
        }
    }
    
    private func checkForExistingDevice() {
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
        matchingDict[kUSBVendorID] = qualcommVendorID
        matchingDict[kUSBProductID] = edlProductID
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        
        if result == KERN_SUCCESS {
            var device = IOIteratorNext(iterator)
            let found = device != 0
            
            while device != 0 {
                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
            
            DispatchQueue.main.async {
                self.isEDLDeviceConnected = found
            }
        }
    }
    
    private func setupUSBNotifications() {
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notificationPort else { return }
        
        let runLoopSource = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        
        // Create matching dictionary for Qualcomm EDL device
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary? else { return }
        matchingDict[kUSBVendorID] = qualcommVendorID
        matchingDict[kUSBProductID] = edlProductID
        
        // We need two copies of the matching dict (IOKit consumes them)
        guard let matchingDictAdd = matchingDict.mutableCopy() as? NSMutableDictionary,
              let matchingDictRemove = matchingDict.mutableCopy() as? NSMutableDictionary else { return }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        // Register for device added
        let addCallback: IOServiceMatchingCallback = { refcon, iterator in
            guard let refcon = refcon else { return }
            let monitor = Unmanaged<USBMonitor>.fromOpaque(refcon).takeUnretainedValue()
            monitor.handleDeviceAdded(iterator: iterator)
        }
        
        IOServiceAddMatchingNotification(
            port,
            kIOFirstMatchNotification,
            matchingDictAdd,
            addCallback,
            selfPtr,
            &addedIterator
        )
        
        // Drain the iterator to arm the notification
        handleDeviceAdded(iterator: addedIterator)
        
        // Register for device removed
        let removeCallback: IOServiceMatchingCallback = { refcon, iterator in
            guard let refcon = refcon else { return }
            let monitor = Unmanaged<USBMonitor>.fromOpaque(refcon).takeUnretainedValue()
            monitor.handleDeviceRemoved(iterator: iterator)
        }
        
        IOServiceAddMatchingNotification(
            port,
            kIOTerminatedNotification,
            matchingDictRemove,
            removeCallback,
            selfPtr,
            &removedIterator
        )
        
        // Drain the iterator to arm the notification
        handleDeviceRemoved(iterator: removedIterator)
    }
    
    private func handleDeviceAdded(iterator: io_iterator_t) {
        var device = IOIteratorNext(iterator)
        var found = false
        
        while device != 0 {
            found = true
            IOObjectRelease(device)
            device = IOIteratorNext(iterator)
        }
        
        if found {
            DispatchQueue.main.async {
                self.isEDLDeviceConnected = true
            }
        }
    }
    
    private func handleDeviceRemoved(iterator: io_iterator_t) {
        var device = IOIteratorNext(iterator)
        var removed = false
        
        while device != 0 {
            removed = true
            IOObjectRelease(device)
            device = IOIteratorNext(iterator)
        }
        
        if removed {
            // Re-check if any EDL device is still connected
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkForExistingDevice()
            }
        }
    }
}
