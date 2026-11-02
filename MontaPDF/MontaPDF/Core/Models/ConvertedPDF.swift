//
//  ConvertedPDF.swift
//  MontaPDF
//

import Foundation

nonisolated struct ConvertedPDF: Sendable {
    let data: Data
    let pageCount: Int
}
