import Combine
import CoreImage
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - AdaptiveColorEngine

/// Extracts the dominant color from a UIImage and publishes it as an adaptive accent color.
///
/// Features:
/// - Uses CIAreaAverage CIFilter for color extraction
/// - Runs on background queue (userInitiated QoS)
/// - 2-second debounce to avoid rapid recalculation
/// - WCAG AA contrast check (luminance ratio >= 4.5:1 against background)
/// - Falls back to configured accent if contrast check fails
///
/// Usage:
/// ```swift
/// @StateObject private var colorEngine = AdaptiveColorEngine()
///
/// // When content changes:
/// colorEngine.updateImage(someUIImage)
///
/// // Read the color:
/// Text("Hello").foregroundStyle(colorEngine.adaptiveColor)
/// ```
@MainActor
public final class AdaptiveColorEngine: ObservableObject {
    /// The current adaptive accent color. Falls back to `fallbackColor` if extraction
    /// fails or the extracted color doesn't pass WCAG AA contrast check.
    @Published public private(set) var adaptiveColor: Color

    /// The fallback accent color (default: deep terracotta #C2410C).
    public let fallbackColor: Color

    /// Whether adaptive color is currently enabled.
    @Published public var isEnabled: Bool {
        didSet {
            if !isEnabled {
                adaptiveColor = fallbackColor
            }
            #if canImport(UIKit)
            if isEnabled, let lastImage {
                updateImage(lastImage)
            }
            #endif
        }
    }

    #if canImport(UIKit)
    private var lastImage: UIImage?
    private let debounceSubject = PassthroughSubject<UIImage, Never>()
    #endif
    private var cancellables = Set<AnyCancellable>()

    /// Minimum WCAG AA luminance contrast ratio.
    nonisolated(unsafe) private static let minimumContrastRatio: CGFloat = 4.5

    /// Default terracotta accent: #C2410C
    public static let defaultAccent = Color(red: 194/255, green: 65/255, blue: 12/255)

    public init(
        fallbackColor: Color = AdaptiveColorEngine.defaultAccent,
        isEnabled: Bool = false
    ) {
        self.fallbackColor = fallbackColor
        self.adaptiveColor = fallbackColor
        self.isEnabled = isEnabled

        #if canImport(UIKit)
        setupDebounce()
        #endif
    }

    // MARK: - Public API

    #if canImport(UIKit)
    /// Provide a new image for color extraction. The extraction is debounced by 2 seconds.
    public func updateImage(_ image: UIImage) {
        lastImage = image
        guard isEnabled else { return }
        debounceSubject.send(image)
    }
    #endif

    /// Reset to the fallback color.
    public func reset() {
        #if canImport(UIKit)
        lastImage = nil
        #endif
        adaptiveColor = fallbackColor
    }

    // MARK: - Private

    #if canImport(UIKit)
    private func setupDebounce() {
        debounceSubject
            .debounce(for: .seconds(2), scheduler: DispatchQueue.global(qos: .userInitiated))
            .compactMap { [weak self] image -> Color? in
                self?.extractDominantColor(from: image)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] color in
                guard let self else { return }
                self.adaptiveColor = color
            }
            .store(in: &cancellables)
    }

    /// Extracts the dominant color from an image using CIAreaAverage.
    /// Returns the fallback color if extraction fails or WCAG check fails.
    nonisolated private func extractDominantColor(from image: UIImage) -> Color {
        guard let ciImage = CIImage(image: image) else {
            return fallbackColor
        }

        let extent = ciImage.extent
        guard let filter = CIFilter(name: "CIAreaAverage") else {
            return fallbackColor
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(
            x: extent.origin.x,
            y: extent.origin.y,
            z: extent.size.width,
            w: extent.size.height
        ), forKey: "inputExtent")

        guard let outputImage = filter.outputImage else {
            return fallbackColor
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return fallbackColor
        }

        let context = CIContext(options: [.workingColorSpace: colorSpace])
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: colorSpace
        )

        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0

        let extractedColor = Color(red: r, green: g, blue: b)

        // WCAG AA check against both light and dark backgrounds
        let lightBgLuminance = Self.relativeLuminance(r: 250/255, g: 248/255, b: 245/255) // #FAF8F5
        let darkBgLuminance = Self.relativeLuminance(r: 28/255, g: 25/255, b: 23/255)     // #1C1917
        let colorLuminance = Self.relativeLuminance(r: r, g: g, b: b)

        let lightContrast = Self.contrastRatio(colorLuminance, lightBgLuminance)
        let darkContrast = Self.contrastRatio(colorLuminance, darkBgLuminance)

        // Must pass on at least one background
        if lightContrast >= Self.minimumContrastRatio || darkContrast >= Self.minimumContrastRatio {
            return extractedColor
        }

        return fallbackColor
    }
    #endif

    // MARK: - WCAG Contrast Utilities

    /// Calculates the relative luminance of a color per WCAG 2.0.
    /// https://www.w3.org/TR/WCAG20/#relativeluminancedef
    nonisolated static func relativeLuminance(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        func linearize(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// Calculates the contrast ratio between two luminance values.
    /// https://www.w3.org/TR/WCAG20/#contrast-ratiodef
    nonisolated static func contrastRatio(_ l1: CGFloat, _ l2: CGFloat) -> CGFloat {
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

// MARK: - Preview

#if canImport(UIKit)
#Preview("AdaptiveColorEngine") {
    AdaptiveColorPreview()
}

@MainActor
private struct AdaptiveColorPreview: View {
    @StateObject private var engine = AdaptiveColorEngine(isEnabled: true)

    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(engine.adaptiveColor)
                .frame(width: 80, height: 80)

            Text("Adaptive Color Engine")
                .font(.headline)
                .foregroundStyle(engine.adaptiveColor)

            Text("Tap a swatch to simulate image extraction")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                swatchButton(.red, label: "Warm")
                swatchButton(.blue, label: "Cool")
                swatchButton(.green, label: "Nature")
                swatchButton(.gray, label: "Neutral")
            }

            Toggle("Enabled", isOn: $engine.isEnabled)
                .padding(.horizontal)
        }
        .padding()
    }

    private func swatchButton(_ color: Color, label: String) -> some View {
        Button {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
            let image = renderer.image { ctx in
                UIColor(color).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            }
            engine.updateImage(image)
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                Text(label)
                    .font(.caption2)
            }
        }
        .buttonStyle(.plain)
    }
}
#endif
