//
//  SampleScan.swift
//  MontaPDF
//

#if DEBUG
import UIKit

/// The simulator has no camera, so the Scan button uses these fake pages there.
enum SampleScan {
    static func pages(count: Int = 2) -> [UIImage] {
        (1...count).map { page(number: $0) }
    }

    private static func page(number: Int) -> UIImage {
        let size = CGSize(width: 1240, height: 1754)
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let text = "Sample page \(number)" as NSString
            text.draw(
                at: CGPoint(x: 120, y: 160),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 96), .foregroundColor: UIColor.black]
            )
        }
    }
}
#endif
