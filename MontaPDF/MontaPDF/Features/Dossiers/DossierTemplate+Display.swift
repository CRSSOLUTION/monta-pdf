//
//  DossierTemplate+Display.swift
//  MontaPDF
//

import SwiftUI

extension DossierTemplate.ID {
    /// SF Symbol shown next to the template and to dossiers created from it.
    var symbolName: String {
        switch self {
        case .rental: "house"
        case .mortgage: "building.columns"
        case .job: "briefcase"
        case .school: "graduationcap"
        case .blank: "square.and.pencil"
        }
    }
}

extension DossierTemplate.Category {
    var title: LocalizedStringKey {
        switch self {
        case .realEstate: "Real estate"
        case .work: "Work"
        case .education: "Education"
        case .custom: "Custom"
        }
    }
}
