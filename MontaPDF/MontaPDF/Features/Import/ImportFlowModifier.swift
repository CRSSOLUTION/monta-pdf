//
//  ImportFlowModifier.swift
//  MontaPDF
//

import PhotosUI
import SwiftUI

extension View {
    /// Everything the Import button needs: the Files and Photos pickers,
    /// the preview sheet and the import alerts.
    func importFlow(
        importer: ImportViewModel,
        isFileImporterPresented: Binding<Bool>,
        isPhotoPickerPresented: Binding<Bool>
    ) -> some View {
        modifier(ImportFlowModifier(
            importer: importer,
            isFileImporterPresented: isFileImporterPresented,
            isPhotoPickerPresented: isPhotoPickerPresented
        ))
    }
}

private struct ImportFlowModifier: ViewModifier {
    let importer: ImportViewModel
    @Binding var isFileImporterPresented: Bool
    @Binding var isPhotoPickerPresented: Bool
    @State private var photoSelection: [PhotosPickerItem] = []

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: ImportKind.supportedTypes,
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    Task { await importer.importFiles(at: urls) }
                }
            }
            .photosPicker(
                isPresented: $isPhotoPickerPresented,
                selection: $photoSelection,
                maxSelectionCount: 30,
                selectionBehavior: .ordered,
                matching: .images
            )
            .onChange(of: photoSelection) { _, items in
                guard !items.isEmpty else { return }
                photoSelection = []
                Task { await importPhotos(items) }
            }
            .sheet(item: previewBinding) { preview in
                ImportPreviewView(
                    preview: preview,
                    onSave: { importer.savePreview() },
                    onKeepOriginal: { importer.keepOriginal() },
                    onCancel: { importer.cancelPreview() }
                )
            }
            .alert(
                alertTitle(importer.alert),
                isPresented: isAlertPresented,
                presenting: importer.alert
            ) { alert in
                if alert == .conversionFailed {
                    Button("Keep Original") { importer.keepOriginal() }
                    Button("Cancel", role: .cancel) { importer.cancelPreview() }
                } else {
                    Button("OK", role: .cancel) {}
                }
            } message: { alert in
                switch alert {
                case .unsupported: Text("Send an image, a PDF or a Word file.")
                case .conversionFailed: Text("You can keep the original file and share it as it is.")
                case .failed: Text("Please try again.")
                }
            }
    }

    /// Loads the picked photos in selection order.
    private func importPhotos(_ items: [PhotosPickerItem]) async {
        var photos: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photos.append(data)
            }
        }
        await importer.importPhotos(photos)
    }

    private var previewBinding: Binding<ImportPreview?> {
        Binding(
            get: { importer.preview },
            set: { importer.preview = $0 }
        )
    }

    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { importer.alert != nil },
            set: { if !$0 { importer.alert = nil } }
        )
    }

    private func alertTitle(_ alert: ImportAlert?) -> Text {
        switch alert ?? .failed {
        case .unsupported: Text("Unsupported format")
        case .conversionFailed: Text("Couldn't convert this document")
        case .failed: Text("Couldn't import the file")
        }
    }
}
