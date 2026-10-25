import Foundation

/// Named product signals. No free-form strings — keeps the surface intentional and reviewable.
enum AnalyticsEvent: String, Sendable {
    case appLaunch = "AppLaunch"
    case captureCompleted = "CaptureCompleted"
    case ocrEmptyOrFail = "OCREmptyOrFail"
    case openAtLoginToggled = "OpenAtLoginToggled"
    case promptTransformUsed = "PromptTransformUsed"
}
