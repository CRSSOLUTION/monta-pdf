//
//  DossiersFeature.swift
//  MontaPDF
//

import Foundation

/// ViewModels used by the Dossiers tab.
struct DossiersFeature {
    let list: DossierListViewModel
    /// Builds the ViewModel of the checklist of a dossier.
    let makeDetail: (UUID) -> DossierDetailViewModel
    /// Builds the ViewModel of the PDF viewer, opened from a checklist item.
    let makeViewer: (UUID) -> DocumentViewerViewModel
    /// Builds the ViewModel of the "Assemble and send" screen.
    let makeAssemble: (UUID) -> AssembleDossierViewModel
}
