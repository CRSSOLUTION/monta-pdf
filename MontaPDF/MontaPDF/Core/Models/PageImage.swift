//
//  PageImage.swift
//  MontaPDF
//

import Foundation

/// One page picture (a scanned page or an imported photo) as encoded bytes
/// (JPEG, PNG or HEIC). ViewModels pass pages around without depending on UIKit;
/// only the services that draw or filter them decode the image.
nonisolated struct PageImage: Equatable, Sendable {
    let data: Data

    init(data: Data) {
        self.data = data
    }
}
