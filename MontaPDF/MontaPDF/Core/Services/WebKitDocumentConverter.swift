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
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)
        let printable = a4.insetBy(dx: margin, dy: margin)
        renderer.setValue(NSValue(cgRect: a4), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printable), forKey: "printableRect")

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

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume()
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
