import SwiftUI

// MARK: - Environment Key

/// The list of media types the user has enabled in Settings.
/// Defaults to all types when nothing has been disabled.
private struct EnabledMediaTypesKey: EnvironmentKey {
    static let defaultValue: [MediaType] = MediaType.allCases.map { $0 }
}

extension EnvironmentValues {
    var enabledMediaTypes: [MediaType] {
        get { self[EnabledMediaTypesKey.self] }
        set { self[EnabledMediaTypesKey.self] = newValue }
    }
}

// MARK: - Helpers

/// Parse the comma-separated `@AppStorage` string into a set of disabled raw values.
func disabledMediaTypeSet(from raw: String) -> Set<String> {
    guard !raw.isEmpty else { return [] }
    return Set(raw.split(separator: ",").map { String($0) })
}

/// Compute the ordered list of enabled media types from a disabled set.
func enabledMediaTypes(disabledRaw: String) -> [MediaType] {
    let disabled = disabledMediaTypeSet(from: disabledRaw)
    return MediaType.allCases.filter { !disabled.contains($0.rawValue) }
}

/// Whether a specific type can be toggled off (i.e. more than one type is still enabled).
func canDisableMediaType(_ type: MediaType, disabledRaw: String) -> Bool {
    let enabled = enabledMediaTypes(disabledRaw: disabledRaw)
    return enabled.count > 1 && enabled.contains(type)
}

/// Toggle a media type on/off, returning the updated raw string.
/// Enforces the "at least one enabled" constraint.
func toggleMediaType(_ type: MediaType, disabledRaw: String) -> String {
    var disabled = disabledMediaTypeSet(from: disabledRaw)

    if disabled.contains(type.rawValue) {
        // Re-enable
        disabled.remove(type.rawValue)
    } else {
        // Disable — only if at least one will remain
        let currentEnabled = MediaType.allCases.filter { !disabled.contains($0.rawValue) }
        guard currentEnabled.count > 1 else { return disabledRaw }
        disabled.insert(type.rawValue)
    }

    return disabled.sorted().joined(separator: ",")
}
