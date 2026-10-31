//
//  DocumentRowView.swift
//  MontaPDF
//

import SwiftUI

/// One row of My Documents: first-page thumbnail, name, date and page count.
struct DocumentRowView: View {
    let row: DocumentRow
    let loadThumbnail: () async -> UIImage?
    @State private var thumbnail: UIImage?

    init(row: DocumentRow, loadThumbnail: @escaping () async -> UIImage?) {
        self.row = row
        self.loadThumbnail = loadThumbnail
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 58)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separator), lineWidth: 0.5))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(row.createdAt, format: .dateTime.day().month().year())
                    if row.hasPDF || !row.hasOriginal {
                        Text("\(row.pageCount) pages")
                    } else {
                        Text("Original file")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .task(id: row.id) {
            thumbnail = await loadThumbnail()
        }
    }
}
