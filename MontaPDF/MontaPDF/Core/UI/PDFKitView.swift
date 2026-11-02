//
//  PDFKitView.swift
//  MontaPDF
//

import PDFKit
import SwiftUI

/// PDFKit viewer: vertical scrolling, pinch to zoom, reports the current page.
struct PDFKitView: UIViewRepresentable {
    let data: Data
    @Binding var currentPage: Int
    @Binding var pageCount: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .secondarySystemBackground
        view.document = PDFDocument(data: data)
        context.coordinator.observe(view)
        DispatchQueue.main.async {
            context.coordinator.updatePage(in: view)
        }
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject {
        var parent: PDFKitView

        init(parent: PDFKitView) {
            self.parent = parent
        }

        func observe(_ view: PDFView) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(pageChanged(_:)),
                name: .PDFViewPageChanged,
                object: view
            )
        }

        @objc private func pageChanged(_ notification: Notification) {
            guard let view = notification.object as? PDFView else { return }
            updatePage(in: view)
        }

        func updatePage(in view: PDFView) {
            guard let document = view.document else { return }
            parent.pageCount = document.pageCount
            if let page = view.currentPage {
                parent.currentPage = document.index(for: page) + 1
            }
        }
    }
}
