//
//  SharePresenter.swift
//  MontaPDF
//

import UIKit

/// Opens the iOS share sheet directly with UIKit.
///
/// Inside a SwiftUI `.sheet`, the share sheet dismisses itself when an activity
/// finishes (WhatsApp, Mail...), outside SwiftUI's knowledge, so `onDismiss` may
/// never run. Presenting it here makes `completionWithItemsHandler` the single,
/// reliable signal that sharing is over.
@MainActor
enum SharePresenter {
    /// `onComplete` gets `true` when the user sent or saved the file, `false` when they cancelled.
    static func present(_ url: URL, onComplete: @escaping (Bool) -> Void) {
        guard let presenter = topViewController() else {
            onComplete(false)
            return
        }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete(completed)
        }
        // iPad shows the share sheet as a popover, which needs an anchor.
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(controller, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}
