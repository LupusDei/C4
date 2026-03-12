import SwiftUI

// MARK: - Adaptive Color Engine

/// Extracts a dominant color from a generated image and provides it as an accent override.
/// When `adaptiveColorEnabled` is true in AppStorage, the extracted color replaces
/// the default accent throughout the SynthesisTheme.
@Observable
public final class AdaptiveColorEngine {
    public var extractedColor: Color?
    public var isExtracting: Bool = false

    public init() {}

    /// Extracts the dominant color from image data using average color sampling.
    @MainActor
    public func extractColor(from imageData: Data) async {
        isExtracting = true
        defer { isExtracting = false }

        #if canImport(UIKit)
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            return
        }

        // Downsample to 16x16 for fast average color computation
        let size = CGSize(width: 16, height: 16)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: 16,
            height: 16,
            bitsPerComponent: 8,
            bytesPerRow: 16 * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let data = context.data else { return }
        let pointer = data.bindMemory(to: UInt8.self, capacity: 16 * 16 * 4)

        var totalR: Int = 0
        var totalG: Int = 0
        var totalB: Int = 0
        let pixelCount = 16 * 16

        for i in 0..<pixelCount {
            let offset = i * 4
            totalR += Int(pointer[offset])
            totalG += Int(pointer[offset + 1])
            totalB += Int(pointer[offset + 2])
        }

        let avgR = Double(totalR) / Double(pixelCount) / 255.0
        let avgG = Double(totalG) / Double(pixelCount) / 255.0
        let avgB = Double(totalB) / Double(pixelCount) / 255.0

        // Boost saturation to make it a usable accent color
        extractedColor = Color(red: avgR, green: avgG, blue: avgB).saturated()
        #endif
    }

    /// Reset extracted color
    public func reset() {
        extractedColor = nil
    }
}

// MARK: - SynthesisTheme

/// Centralised theme that adapts its accent color when adaptive color is enabled.
public struct SynthesisTheme {
    @AppStorage("adaptiveColorEnabled") private var adaptiveColorEnabled = false

    private let engine: AdaptiveColorEngine?
    private let defaultAccent: Color

    public init(engine: AdaptiveColorEngine? = nil, defaultAccent: Color = .accentColor) {
        self.engine = engine
        self.defaultAccent = defaultAccent
    }

    /// The current accent color, which may be adaptively overridden.
    public var accent: Color {
        if adaptiveColorEnabled, let extracted = engine?.extractedColor {
            return extracted
        }
        return defaultAccent
    }
}

// MARK: - Color Extension

extension Color {
    /// Boosts saturation of the color to make muted averages more vivid.
    func saturated(by factor: Double = 1.4) -> Color {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: min(Double(s) * factor, 1.0), brightness: Double(b))
        #else
        return self
        #endif
    }
}

// MARK: - Environment Key

private struct AdaptiveColorEngineKey: EnvironmentKey {
    static let defaultValue: AdaptiveColorEngine? = nil
}

extension EnvironmentValues {
    public var adaptiveColorEngine: AdaptiveColorEngine? {
        get { self[AdaptiveColorEngineKey.self] }
        set { self[AdaptiveColorEngineKey.self] = newValue }
    }
}
