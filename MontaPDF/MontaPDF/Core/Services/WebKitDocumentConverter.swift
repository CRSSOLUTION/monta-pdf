//
//  WebKitDocumentConverter.swift
//  MontaPDF
//

import UIKit
import WebKit

/// Free, on-device Word → PDF: WebKit renders the .docx/.doc and the print
/// system lays it out on A4 pages. Fidelity isn't perfect, so the original is always kept.
@MainActor
final class WebKitDocumentConverter: NSObject, DocumentConverter, WKNavigationDelegate {
    static let a4 = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
    static let margin: CGFloat = 36
    /// Gives up if WebKit can't open the file in time (e.g. a damaged document).
    static let loadTimeout: Duration = .seconds(20)

    private var continuation: CheckedContinuation<Void, Error>?

    func convertToPDF(data: Data, fileName: String) async throws -> ConvertedPDF {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("Convert", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let fileURL = folder.appendingPathComponent(fileName)
        try data.write(to: fileURL)

        let webView = WKWebView(frame: Self.a4)
        webView.navigationDelegate = self
        let timeout = Task { [weak self] in
            try await Task.sleep(for: Self.loadTimeout)
            self?.finishLoading(with: .failure(DocumentConverterError.timedOut))
        }
        defer { timeout.cancel() }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.continuation = continuation
            webView.loadFileURL(fileURL, allowingReadAccessTo: folder)
        }
        // Give WebKit a moment to finish laying out the document.
        try await Task.sleep(for: .milliseconds(600))

        let result = Self.renderPDF(from: webView)
        webView.navigationDelegate = nil
        guard result.pageCount > 0 else { throw DocumentConverterError.emptyDocument }
        return result
    }

    private static func renderPDF(from webView: WKWebView) -> ConvertedPDF {
        let renderer = A4PageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)

        let pageCount = renderer.numberOfPages
        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, a4, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: pageCount))
        for index in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: index, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        return ConvertedPDF(data: data as Data, pageCount: pageCount)
    }

    /// Resumes the waiting conversion once: load finished, failed or timed out.
    private func finishLoading(with result: Result<Void, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishLoading(with: .success(()))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishLoading(with: .failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finishLoading(with: .failure(error))
    }
}

/// Lays the document out on A4 pages with margins, using the public
/// paperRect / printableRect overrides (no private key-value coding).
private final class A4PageRenderer: UIPrintPageRenderer {
    override var paperRect: CGRect {
        WebKitDocumentConverter.a4
    }

    override var printableRect: CGRect {
        WebKitDocumentConverter.a4.insetBy(dx: WebKitDocumentConverter.margin, dy: WebKitDocumentConverter.margin)
    }
}
