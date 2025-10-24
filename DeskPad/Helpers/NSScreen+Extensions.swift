import Foundation

extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let displayID = deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID else {
            return 0
        }
        return displayID
    }
}
