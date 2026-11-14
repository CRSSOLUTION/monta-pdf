//
//  DossierItemRowView.swift
//  MontaPDF
//

import SwiftUI

/// A checklist line: status, thumbnail, title and state, with a "+" to fill it and a "…" menu.
struct DossierItemRowView: View {
    let item: DossierItem
    let loadThumbnail: () async -> Data?
    let onAdd: () -> Void
    let onView: () -> Void
    let onRemoveDocument: () -> Void
    let onRename: () -> Void
    let onSetNotApplicable: (Bool) -> Void
    let onRemoveItem: () -> Void
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: item.state == .added ? onView : onAdd) {
                HStack(spacing: 12) {
                    statusIcon
                    thumbnailView
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(item.state == .notApplicable ? .secondary : .primary)
                            .multilineTextAlignment(.leading)
                        stateText
                            .font(.subheadline)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("dossierItem")

            if item.state == .missing {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("Add document"))
                .accessibilityIdentifier("addDocumentButton")
            }
            menu
        }
        .padding(.vertical, 2)
        .task(id: item.document?.id) {
            thumbnail = await loadThumbnail().flatMap { UIImage(data: $0) }
        }
    }

    // MARK: - Parts

    @ViewBuilder
    private var statusIcon: some View {
        switch item.state {
        case .added:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .missing:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case .notApplicable:
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if item.state != .notApplicable {
            ZStack(alignment: .bottomTrailing) {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else if item.state == .added {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3]))
                        .foregroundStyle(.tertiary)
                }
                if let pages = item.document?.pageCount, pages > 0 {
                    Text("\(pages) p.")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 3))
                        .padding(3)
                }
            }
            .frame(width: 44, height: 58)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                if item.state == .added {
                    RoundedRectangle(cornerRadius: 6).stroke(Color(.separator), lineWidth: 0.5)
                }
            }
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var stateText: some View {
        switch item.state {
        case .added:
            if let pages = item.document?.pageCount {
                Text("\(pages) pages")
                    .foregroundStyle(.secondary)
            }
        case .missing:
            if item.isRequired {
                Text("Missing")
                    .foregroundStyle(.red)
            } else {
                Text("Not added")
                    .foregroundStyle(.secondary)
            }
        case .notApplicable:
            Text("Doesn't apply")
                .foregroundStyle(.secondary)
        }
    }

    private var menu: some View {
        Menu {
            switch item.state {
            case .added:
                Button("View document", systemImage: "eye", action: onView)
                Button("Replace document", systemImage: "arrow.triangle.2.circlepath", action: onAdd)
                Button("Remove document", systemImage: "doc.badge.minus", action: onRemoveDocument)
            case .missing:
                Button("Add document", systemImage: "plus", action: onAdd)
            case .notApplicable:
                EmptyView()
            }
            Divider()
            Button("Rename", systemImage: "pencil", action: onRename)
            if item.state == .notApplicable {
                Button("Needed again", systemImage: "arrow.uturn.backward") { onSetNotApplicable(false) }
            } else {
                Button("Doesn't apply", systemImage: "minus.circle") { onSetNotApplicable(true) }
            }
            Button("Remove from list", systemImage: "trash", role: .destructive, action: onRemoveItem)
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .accessibilityLabel(Text("More"))
        .accessibilityIdentifier("itemMenuButton")
    }
}
