## [2.2.1]
### Fixed
- The `sandbox` environment now points to `https://sandbox-sync.aero.inc` (previously `https://sandbox.aerosync.com`). If you allowlist AeroSync domains in a firewall or CSP policy, update it to the new host.

## [2.2.0]
### Added
- Typed success models — `AerosyncSingleAccountSuccessPayload`, `AerosyncLinkedAccount`, `AerosyncMultiAccountSuccessPayload`, and the `AerosyncSuccessPayload` enum, in `AerosyncSuccessModels.swift`. Call `AerosyncSuccessPayload.parse(from:)` inside your `onSuccess` closure to parse the raw JSON string into a `.multiAccount` case (returned when the merchant's AeroSync configuration has multi-account linking enabled) or a `.singleAccount` case (the default) — switch on the enum to narrow. This is purely additive: `onSuccess` keeps its existing `(String) -> Void` signature, so no existing integration needs to change.

## [2.1.0]
### Removed
- `AerosyncEmbeddedView` has been removed and will be re-introduced in a future release
### Changed
- Removed `dev` and `staging` environments — only `sandbox` and `production` are supported
- Removed all debug `print` statements from production code paths

---

### 2.x Summary — what changed from 1.x

**New parameters**
- `aeroPassUserUuid` — now **required** for all widget flows
- `configurationId` — optional configuration ID for widget customization
- `manualLinkOnly` — restrict the widget to manual (non-OAuth) linking only
- `handleMFA` — enable MFA re-authentication flows; requires `jobId` and `connectionId`

**Renamed parameters**
- `connectionId` and `configurationId` unified across all AeroSync SDKs for consistency

**Removed**
- `dev` and `staging` environments dropped — use `sandbox` for all non-production testing

---

## [2.0.4]
### Fixed
- Fixed compatibility issues with iOS 26 message handler registration
- Restored `onBankClick` event forwarding that was accidentally dropped
- Removed erroneous `wrapper` self-reference that caused a retain cycle

## [2.0.0-rc.3]
### Breaking Changes
- `aeroPassUserUuid` is now required for `AerosyncSDK`

## [2.0.0-rc.2]
### Fixed
- Fixed `aeroPassUserUuid` and `theme` parameters not being passed to the widget URL

## [2.0.0-rc.1]
### Added
- `AerosyncEmbeddedView` — lightweight bank search and selection interface
- `aeroPassUserUuid` parameter for user identification
- `manualLinkOnly` parameter to restrict to manual linking flows
- `handleMFA` support with `jobId` and `connectionId` parameters
- `configurationId` parameter for custom widget configurations
### Changed
- `connectionId` renamed from previous parameter name for cross-SDK consistency
- Removed `dev` and `staging` environments — only `sandbox` and `production` are supported

## [1.1.0]
### Added
- `sandbox` environment support

## [1.0.2]
### Added
- MFA flow handling
- Swipe gesture navigation (swipe right to go back, swipe left to go forward)

## [1.0.1]
### Changed
- Removed `dev` environment from available options

## [1.0.0]
### Fixed
- `onLoad` callback firing on every navigation instead of only on initial page load
