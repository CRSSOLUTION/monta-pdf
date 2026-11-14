//
//  DossierTemplatesTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

struct DossierTemplatesTests {
    @Test func portugueseShowsTheBrazilianTemplates() {
        let templates = DossierTemplates.all(localization: "pt-BR")

        #expect(templates.map(\.title) == [
            "Aluguel de imóvel", "Financiamento imobiliário", "Admissão de emprego", "Matrícula escolar", "Lista em branco"
        ])
        // The counts shown on the "Novo dossiê" screen (all items, required and optional).
        #expect(templates.map(\.items.count) == [6, 8, 7, 5, 0])
    }

    @Test func rentalTemplateMatchesThePRD() throws {
        let rental = try #require(DossierTemplates.template(id: .rental, localization: "pt-BR"))

        #expect(rental.category == .realEstate)
        #expect(rental.items.filter(\.isRequired).map(\.title) == [
            "RG ou CNH", "Comprovante de renda", "Imposto de Renda", "Comprovante de residência", "Fiador: RG ou CNH"
        ])
        #expect(rental.items.filter { !$0.isRequired }.map(\.title) == ["Certidão de casamento"])
    }

    @Test func englishAndSpanishShowGenericTemplatesWithoutBrazilianDocuments() {
        for localization in ["en", "es-419", nil] {
            let titles = DossierTemplates.all(localization: localization).flatMap { $0.items.map(\.title) }

            #expect(titles.isEmpty == false)
            for brazilian in ["CPF", "CNH", "FGTS", "PIS"] {
                #expect(titles.allSatisfy { !$0.contains(brazilian) })
            }
        }
    }

    @Test func everyLanguageOffersEveryTemplateOnce() {
        for localization in ["pt-BR", "en", "es-419"] {
            let ids = DossierTemplates.all(localization: localization).map(\.id)

            #expect(ids == DossierTemplate.ID.allCases)
        }
    }

    @Test func onlyTheBlankListHasNoItems() {
        for localization in ["pt-BR", "en"] {
            for template in DossierTemplates.all(localization: localization) {
                #expect(template.items.isEmpty == (template.id == .blank))
                #expect(template.items.contains(where: \.isRequired) || template.id == .blank)
            }
        }
    }
}
