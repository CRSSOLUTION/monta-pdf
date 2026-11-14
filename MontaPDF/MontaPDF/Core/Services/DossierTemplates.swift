//
//  DossierTemplates.swift
//  MontaPDF
//

import Foundation

/// The templates offered when creating a dossier. They are suggestions, not official
/// lists: the app tells the user to confirm the list with whoever asked for the documents.
///
/// Portuguese shows the Brazilian templates (CPF, CNH, FGTS...). English and Spanish
/// show generic ones, because Brazilian documents mean nothing to other countries.
nonisolated enum DossierTemplates {
    /// Templates for the language the app is running in.
    static func all(localization: String? = Bundle.main.preferredLocalizations.first) -> [DossierTemplate] {
        if let localization, localization.hasPrefix("pt") {
            return brazil
        }
        return generic
    }

    static func template(id: DossierTemplate.ID, localization: String? = Bundle.main.preferredLocalizations.first) -> DossierTemplate? {
        all(localization: localization).first { $0.id == id }
    }

    // MARK: - Brazil (shown only in Portuguese, so the titles are not translated)

    static let brazil: [DossierTemplate] = [
        DossierTemplate(id: .rental, category: .realEstate, title: "Aluguel de imóvel", items: [
            requiredItem("RG ou CNH"),
            requiredItem("Comprovante de renda"),
            requiredItem("Imposto de Renda"),
            requiredItem("Comprovante de residência"),
            requiredItem("Fiador: RG ou CNH"),
            optionalItem("Certidão de casamento")
        ]),
        DossierTemplate(id: .mortgage, category: .realEstate, title: "Financiamento imobiliário", items: [
            requiredItem("RG ou CNH"),
            requiredItem("CPF"),
            requiredItem("Certidão de nascimento ou casamento"),
            requiredItem("Comprovante de residência"),
            requiredItem("Comprovante de renda"),
            requiredItem("Imposto de Renda"),
            optionalItem("Extrato do FGTS"),
            optionalItem("Carteira de trabalho")
        ]),
        DossierTemplate(id: .job, category: .work, title: "Admissão de emprego", items: [
            requiredItem("RG ou CNH"),
            requiredItem("CPF"),
            requiredItem("Carteira de trabalho"),
            requiredItem("Comprovante de residência"),
            requiredItem("Título de eleitor"),
            requiredItem("PIS/PASEP"),
            requiredItem("Exame admissional")
        ]),
        DossierTemplate(id: .school, category: .education, title: "Matrícula escolar", items: [
            requiredItem("Certidão de nascimento do aluno"),
            requiredItem("RG ou CNH do responsável"),
            requiredItem("Comprovante de residência"),
            requiredItem("Carteira de vacinação"),
            optionalItem("Histórico escolar ou declaração de transferência")
        ]),
        DossierTemplate(id: .blank, category: .custom, title: "Lista em branco", items: [])
    ]

    // MARK: - Generic (English and Spanish)

    static var generic: [DossierTemplate] {
        [
            DossierTemplate(id: .rental, category: .realEstate, title: String(localized: "Apartment rental"), items: [
                requiredItem(String(localized: "Identity document")),
                requiredItem(String(localized: "Proof of income")),
                requiredItem(String(localized: "Proof of address")),
                requiredItem(String(localized: "Bank statements")),
                optionalItem(String(localized: "Reference letter"))
            ]),
            DossierTemplate(id: .mortgage, category: .realEstate, title: String(localized: "Mortgage"), items: [
                requiredItem(String(localized: "Identity document")),
                requiredItem(String(localized: "Proof of income")),
                requiredItem(String(localized: "Proof of address")),
                requiredItem(String(localized: "Bank statements")),
                requiredItem(String(localized: "Tax return")),
                optionalItem(String(localized: "Employment letter"))
            ]),
            DossierTemplate(id: .job, category: .work, title: String(localized: "New job"), items: [
                requiredItem(String(localized: "Identity document")),
                requiredItem(String(localized: "Tax ID")),
                requiredItem(String(localized: "Proof of address")),
                optionalItem(String(localized: "Diplomas or certificates")),
                optionalItem(String(localized: "Medical certificate"))
            ]),
            DossierTemplate(id: .school, category: .education, title: String(localized: "School enrollment"), items: [
                requiredItem(String(localized: "Student's birth certificate")),
                requiredItem(String(localized: "Parent's identity document")),
                requiredItem(String(localized: "Proof of address")),
                requiredItem(String(localized: "Vaccination record")),
                optionalItem(String(localized: "School records"))
            ]),
            DossierTemplate(id: .blank, category: .custom, title: String(localized: "Blank list"), items: [])
        ]
    }

    private static func requiredItem(_ title: String) -> DossierTemplate.Item {
        DossierTemplate.Item(title: title, isRequired: true)
    }

    private static func optionalItem(_ title: String) -> DossierTemplate.Item {
        DossierTemplate.Item(title: title, isRequired: false)
    }
}
