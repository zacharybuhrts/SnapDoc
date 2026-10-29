import CoreGraphics

enum TestImages {
    static func solid(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) -> CGImage {
        rgba(width: width, height: height) { _, _ in (red, green, blue, 255) }
    }

    static func rgba(
        width: Int,
        height: Int,
        pixel: (Int, Int) -> (UInt8, UInt8, UInt8, UInt8)
    ) -> CGImage {
        let bytesPerRow = width * 4
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        for y in 0..<height {
            for x in 0..<width {
                let sample = pixel(x, y)
                let index = y * bytesPerRow + x * 4
                data[index] = sample.0
                data[index + 1] = sample.1
                data[index + 2] = sample.2
                data[index + 3] = sample.3
            }
        }
        guard let provider = CGDataProvider(data: Data(data) as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            fatalError("Could not build a test image.")
        }
        return image
    }

    /// Samples a pixel. `y` 0 is the top row.
    static func sample(_ image: CGImage, x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8)? {
        guard x >= 0, y >= 0, x < image.width, y < image.height else { return nil }
        let bytesPerRow = image.width * 4
        var data = [UInt8](repeating: 0, count: image.height * bytesPerRow)
        var pixel: (UInt8, UInt8, UInt8, UInt8)?
        data.withUnsafeMutableBytes { raw in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }
            context.translateBy(x: 0, y: CGFloat(image.height))
            context.scaleBy(x: 1, y: -1)
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            let index = y * bytesPerRow + x * 4
            let bytes = raw.bindMemory(to: UInt8.self)
            pixel = (bytes[index], bytes[index + 1], bytes[index + 2], bytes[index + 3])
        }
        return pixel
    }
}
