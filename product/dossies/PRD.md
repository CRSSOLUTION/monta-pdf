# PRD: Dossiês

| | |
| --- | --- |
| **Produto** | Monta PDF (iOS) |
| **Versão alvo** | 1.0 (reenvio à App Store) |
| **Status** | Rascunho para revisão |
| **Autor** | Carlos Augusto |
| **Atualizado** | 14/11/2026 |
| **Telas de referência** | [`telas/`](telas/), geradas no Google Stitch e revisadas |

---

## 1. Contexto

A versão 1.0 do Monta PDF (build 2) foi **rejeitada** pela App Store em 13/11/2026 pela regra **4.3 – Spam**: *"o app compartilha conceito semelhante a apps de outros desenvolvedores, com diferenças pequenas"*.

O motivo é real: **scanner e conversor de PDF** é uma das categorias mais lotadas da loja. Reenviar o mesmo app não funciona, e cada rejeição repetida aumenta o tempo de revisão e o risco para a conta.

A análise mostrou que o problema não é o outro app da conta (Home Market): ele tem outro conceito, outro código e outro Bundle ID. O problema é o **conceito genérico**.

**Decisão:** dar ao Monta PDF uma função principal que os scanners não têm. É o que este PRD descreve.

## 2. Problema

Quem precisa **entregar vários documentos** para alguém (imobiliária, RH, escola, banco) passa por isto:

- não sabe exatamente **quais** documentos juntar;
- tira fotos soltas e **perde a conta** do que já tem;
- manda **10 a 20 arquivos** separados pelo WhatsApp ou e-mail;
- recebe de volta *"faltou o comprovante de renda"*;
- na próxima situação, **escaneia tudo de novo**.

Scanners resolvem "transformar papel em PDF". **Ninguém resolve "juntar tudo o que pediram, sem esquecer nada, e entregar de uma vez".**

Uma pesquisa rápida na App Store (14/11/2026) não encontrou nenhum app que una checklist pronto por situação + escanear cada item + montar um PDF único. Existem scanners, apps de checklist genéricos e apps de gestão para locadores. *(Pesquisa não exaustiva.)*

## 3. Proposta

Um **Dossiê** é um checklist de documentos para uma situação concreta. O app:

1. oferece **modelos prontos** (aluguel, emprego, escola, financiamento) ou uma lista em branco;
2. mostra **o que já tem e o que falta**;
3. preenche cada item com o **scanner**, um **arquivo** ou um documento **já escaneado antes**;
4. **monta um PDF único**, com capa e sumário, pronto para compartilhar.

O nome do app passa a fazer sentido: o Monta PDF **monta** o dossiê.

## 4. Público

- **Principal:** pessoas no Brasil que precisam entregar documentos para alugar imóvel, ser admitidas num emprego, matricular filhos ou pedir financiamento.
- **Secundário:** quem só quer escanear e guardar documentos. A aba **Documentos** mantém tudo o que o app já faz hoje.

## 5. Objetivos

| Objetivo | Como saber |
| --- | --- |
| Ser aprovado na App Store | Revisão aprovada no reenvio |
| Usuário entende o diferencial na primeira tela | Tela vazia explica em 1 frase; teste com 5 pessoas sem explicação prévia |
| Usuário chega ao PDF final | Teste guiado: criar um dossiê de aluguel e compartilhar em menos de 5 minutos |

**Sobre métricas:** o app declara à Apple que **não coleta dados**. Por isso não haverá analytics no app. Acompanhamento via App Store Connect (downloads, retenção das contas que aceitam compartilhar dados com desenvolvedores, avaliações) e testes com usuários.

## 6. Histórias de usuário

1. **Como** pessoa que vai alugar um apartamento, **quero** ver a lista de documentos que a imobiliária costuma pedir, **para** não esquecer nenhum.
2. **Como** usuária, **quero** dar um nome ao dossiê ("Apto Rua das Flores"), **para** diferenciar de outros aluguéis.
3. **Como** usuária, **quero** escanear, importar ou reaproveitar um documento para cada item, **para** não repetir trabalho.
4. **Como** solteira, **quero** marcar "Certidão de casamento" como **não se aplica**, **para** conseguir completar o dossiê.
5. **Como** usuária, **quero** adicionar um item que não está no modelo ("Carta do fiador"), **para** atender pedidos específicos.
6. **Como** usuária, **quero** ver **o que falta** já na lista de dossiês, **para** não precisar abrir cada um.
7. **Como** usuária, **quero** um **PDF único com capa e sumário**, **para** mandar um arquivo organizado.
8. **Como** usuária, **quero** ser avisada se falta um documento obrigatório antes de montar, **para** não mandar incompleto sem querer.
9. **Como** usuária, **quero** marcar o dossiê como **enviado**, **para** separar o que já foi do que está pendente.
10. **Como** usuária, **quero** que o RG que escaneei para o aluguel apareça quando eu montar o dossiê de emprego, **para** não escanear de novo.

## 7. Fluxo e telas

As imagens estão em [`telas/`](telas/). Elas são **referência visual**; os ajustes da seção 10 valem sobre elas.

| # | Tela | Arquivo |
| --- | --- | --- |
| 1 | Dossiês (lista, aba "Em andamento") | [`01-dossi_s.png`](telas/01-dossi_s.png) |
| 2 | Novo dossiê: escolher modelo (sheet) | [`02-novo_dossi.png`](telas/02-novo_dossi.png) |
| 3 | Novo dossiê: nome do dossiê e nome na capa | [`03-aluguel_de_im_vel.png`](telas/03-aluguel_de_im_vel.png) |
| 4 | Checklist do dossiê | [`04-apto_rua_das_flores.png`](telas/04-apto_rua_das_flores.png) |
| 5 | Menu para preencher um item | [`05-action_sheet.png`](telas/05-action_sheet.png) |
| 6 | Alerta: falta documento obrigatório | [`06-alerta.png`](telas/06-alerta.png) |
| 7 | Montar e enviar | [`07-montar_e_enviar.png`](telas/07-montar_e_enviar.png) |
| 8 | Documentos (biblioteca) | [`08-documentos.png`](telas/08-documentos.png) |
| 9 | Dossiês vazio (primeiro uso) | [`09-dossi_s_vazio.png`](telas/09-dossi_s_vazio.png) |
| 10 | Alerta: marcar como enviado | [`10-alerta.png`](telas/10-alerta.png) |
| 11 | Checklist no modo escuro | [`11-apto_rua_das_flores_dark.png`](telas/11-apto_rua_das_flores_dark.png) |

### Fluxo principal
```
Login (já existe)
  └─ Dossiês (vazio: tela 9 · com dossiês: tela 1)
       └─ "Novo dossiê" → escolher modelo (2) → nome do dossiê e nome na capa (3) → "Criar dossiê"
            └─ Checklist (4)
                 ├─ "+" de um item → menu (5): Escanear · Importar · Escolher da biblioteca · Não se aplica
                 ├─ "…" de um item → Ver · Trocar · Renomear · Não se aplica / Voltar a ser necessário · Remover
                 ├─ "+ Adicionar item" → nome do item + obrigatório ou opcional
                 └─ "Montar PDF"
                      ├─ falta obrigatório → alerta (6): "Adicionar agora" · "Montar mesmo assim"
                      └─ Montar e enviar (7) → "Compartilhar PDF" → folha de compartilhamento do iOS
                           └─ ao fechar, se a ação foi concluída → alerta (10): "Ainda não" · "Marcar"
```

### Aba Documentos (8)
É a biblioteca atual, com o mesmo scanner, importação, visualização, renomear, apagar e compartilhar. A novidade é mostrar em qual dossiê cada documento é usado.

## 8. Regras de negócio

### 8.1 Status do dossiê
Só existem **3 status**, calculados (não escolhidos pelo usuário):

| Status | Regra |
| --- | --- |
| **Em andamento** | Pelo menos um item **obrigatório** sem documento e sem "Não se aplica" |
| **Pronto para enviar** | Todo item obrigatório tem documento **ou** está como "Não se aplica" |
| **Enviado em [data]** | O usuário confirmou "Marcar" no alerta da tela 10 |

- Um dossiê **Enviado** que é editado (documento trocado ou item adicionado) **continua Enviado** e mostra um aviso: *"Alterado depois do envio"*. Ele só volta a "Em andamento" se o usuário escolher **"Reabrir"** no menu do dossiê.
- A aba Dossiês tem dois filtros: **Em andamento** (inclui "Pronto para enviar") e **Enviados**.

### 8.2 Progresso
- Sempre mostrado como **"X de Y obrigatórios"**, nunca em percentual.
- **Y** = itens obrigatórios. Itens "Não se aplica" saem da conta (não contam em X nem em Y).
- Itens opcionais não entram no progresso.

### 8.3 Itens
Cada item tem um destes estados: **Falta**, **Adicionado** (com um documento) ou **Não se aplica**.

- Um item tem **no máximo 1 documento**. Documentos com várias páginas (RG frente e verso) são um documento só.
- O mesmo documento pode estar em **vários dossiês** (reaproveitamento).
- Apagar um documento da biblioteca que está em uso: o app avisa *"Este documento está em 2 dossiês. Apagar mesmo assim?"*. Se confirmar, os itens voltam para **Falta**.
- Tirar um documento de um item **não apaga** o documento da biblioteca.
- Todo documento escaneado ou importado **dentro de um dossiê** também vai para a biblioteca, com o nome do item como título ("Fiador: RG ou CNH").
- Itens podem ser **reordenados**, **renomeados** e **removidos** (botão "Editar" do checklist, como no app Lembretes).

### 8.4 PDF montado
- Ordem: **Capa** (opcional) → **Sumário** (opcional) → documentos na ordem do checklist.
- Entram só os itens **Adicionados**. Itens "Falta" e "Não se aplica" não aparecem no PDF nem no sumário.
- **Capa:** nome do dossiê, nome do modelo, nome na capa e data (ex.: "14 de novembro de 2026").
- **Sumário:** nome de cada item e o número da página onde ele começa.
- **Nome do arquivo:** `<nome do dossiê> - <nome na capa>.pdf` (ex.: `Apto Rua das Flores - Ana Souza.pdf`).
- O PDF é gerado **no aparelho**, na hora de compartilhar. Não fica salvo como documento novo.

### 8.5 Nome na capa
- Campo na criação do dossiê (tela 3), editável depois.
- Vem preenchido com o nome do Apple ID, quando o usuário compartilhou o nome no login. Se não, fica vazio, e a capa mostra só o nome do dossiê.

### 8.6 Marcar como enviado
- A folha de compartilhamento do iOS informa se o usuário **concluiu** uma ação (enviar, salvar) ou cancelou.
- Concluiu → alerta da tela 10. Cancelou → nada acontece.
- Não dá para saber se foi WhatsApp ou "Salvar em Arquivos", por isso a pergunta é feita ao usuário.

### 8.7 Modelos
- Ficam **dentro do app** (não vêm de servidor) e são traduzidos no String Catalog.
- Criar um dossiê **copia** os itens do modelo. Mudar o modelo numa versão futura não altera dossiês existentes.
- Texto fixo na tela de modelos: *"Os modelos são sugestões. Confirme a lista com quem pediu os documentos."* Isso evita prometer que a lista é oficial.

## 9. Modelos da v1 (Brasil)

Os números entre parênteses aparecem na tela 2 e contam **todos** os itens do modelo.

**Aluguel de imóvel (6)**
| Item | Tipo |
| --- | --- |
| RG ou CNH | Obrigatório |
| Comprovante de renda | Obrigatório |
| Imposto de Renda | Obrigatório |
| Comprovante de residência | Obrigatório |
| Fiador: RG ou CNH | Obrigatório |
| Certidão de casamento | Opcional |

**Financiamento imobiliário (8)**
| Item | Tipo |
| --- | --- |
| RG ou CNH | Obrigatório |
| CPF | Obrigatório |
| Certidão de nascimento ou casamento | Obrigatório |
| Comprovante de residência | Obrigatório |
| Comprovante de renda | Obrigatório |
| Imposto de Renda | Obrigatório |
| Extrato do FGTS | Opcional |
| Carteira de trabalho | Opcional |

**Admissão de emprego (7)**
| Item | Tipo |
| --- | --- |
| RG ou CNH | Obrigatório |
| CPF | Obrigatório |
| Carteira de trabalho | Obrigatório |
| Comprovante de residência | Obrigatório |
| Título de eleitor | Obrigatório |
| PIS/PASEP | Obrigatório |
| Exame admissional | Obrigatório |

**Matrícula escolar (5)**
| Item | Tipo |
| --- | --- |
| Certidão de nascimento do aluno | Obrigatório |
| RG ou CNH do responsável | Obrigatório |
| Comprovante de residência | Obrigatório |
| Carteira de vacinação | Obrigatório |
| Histórico escolar ou declaração de transferência | Opcional |

**Lista em branco (0)**: o usuário adiciona os itens.

> **Pendência:** validar as listas com 2 ou 3 pessoas que passaram por cada situação recentemente.

## 10. Ajustes sobre as telas do Stitch

As telas são referência. Na implementação em SwiftUI:

| Tela | Ajuste |
| --- | --- |
| 1 | Remover o "+" do topo. O único jeito de criar é o botão **Novo dossiê** |
| 1 | Linha de dossiê "Pronto para enviar" mostra o selo verde no lugar do texto "Falta" |
| 2 | Adicionar o texto *"Os modelos são sugestões..."* (seção 8.7) |
| 3 | Campos com rótulo visível: **Nome do dossiê** e **Nome na capa** |
| 4 | Todo item tem o menu **"…"**, inclusive os opcionais e os "Não se aplica" |
| 4 | Nenhum título cortado: quebrar em 2 linhas (vale também para Dynamic Type) |
| 4 | Miniaturas reais da primeira página de cada documento |
| 7 | Voltar mostra só "‹" quando o nome do dossiê é longo (comportamento padrão do iOS) |
| 7 | **Remover a opção "Tamanho do arquivo"** da v1 (seção 12) |
| 7 | A última miniatura aparece cortada na borda, indicando que a lista rola. Tocar numa miniatura abre a **prévia completa** do PDF |
| 9 | Três passos curtos abaixo do texto: *1. Escolha o modelo · 2. Adicione cada documento · 3. Envie um PDF só* |
| Todas | Selo de páginas ("2 p.") na fonte do sistema, não monoespaçada |
| Todas | Modo escuro com as cores do sistema (já validado na tela 11) |

## 11. Visão técnica

### 11.1 Modelo de dados (SwiftData + CloudKit)
Regras do CloudKit: toda propriedade com valor padrão ou opcional, relações opcionais, sem `@Attribute(.unique)`.

```swift
@Model final class Dossier {
    var id: UUID = UUID()
    var name: String = ""
    var templateID: String = ""          // "rental", "mortgage", "job", "school", "blank"
    var coverName: String = ""
    var createdAt: Date = Date()
    var sentAt: Date?                     // nil = não enviado
    var editedAfterSending: Bool = false
    var includesCover: Bool = true
    var includesSummary: Bool = true
    @Relationship(deleteRule: .cascade, inverse: \DossierItem.dossier)
    var items: [DossierItem]? = []
}

@Model final class DossierItem {
    var id: UUID = UUID()
    var title: String = ""
    var isRequired: Bool = true
    var isNotApplicable: Bool = false
    var order: Int = 0
    var dossier: Dossier?
    @Relationship(deleteRule: .nullify)
    var document: Document?               // nil = Falta (se não for "Não se aplica")
}
```

- `Document` (já existe) ganha a relação inversa `dossierItems: [DossierItem]?` com `.nullify`: apagar um documento devolve os itens para **Falta**.
- O status (seção 8.1) é **calculado** a partir dos itens e de `sentAt`, não é salvo.
- Depois de adicionar os modelos, **publicar o schema do CloudKit em produção** no CloudKit Console antes do reenvio.

### 11.2 Componentes
| Parte | Abordagem |
| --- | --- |
| Modelos de dossiê | `DossierTemplate` estático em Swift, textos no String Catalog |
| Repositório | `DossierRepository` (protocolo) + `SwiftDataDossierRepository`, no mesmo padrão de `DocumentRepository` |
| Status e progresso | `DossierProgress`, tipo puro e testável |
| Montagem do PDF | `DossierPDFAssembler`: capa e sumário com `UIGraphicsPDFRenderer`, junção com `PDFDocument` (PDFKit). Atrás de um protocolo, como o `PDFBuilding` |
| Scanner e importação | Reaproveita `ScannerViewModel` e `ImportViewModel`. O `onSaved` passa a ligar o documento ao item |
| Compartilhar | `UIActivityViewController` com `completionWithItemsHandler` para o alerta da tela 10 |
| Navegação | `TabView` com **Dossiês** e **Documentos**. A tela de documentos atual vira a segunda aba |

### 11.3 Testes
- **Unitários (Swift Testing):** status e progresso, "Não se aplica", ordem do PDF, números do sumário, nome do arquivo, apagar documento em uso, cópia do modelo.
- **UI (XCTest):** criar dossiê de aluguel → adicionar item com as páginas de exemplo (`-ui-testing`) → marcar "Não se aplica" → montar → alerta de item faltando. Atualizar os 6 testes atuais para a nova aba Documentos.

## 12. Fora da v1

| Item | Motivo |
| --- | --- |
| Tamanho do arquivo (leve ou alta qualidade) | Comprimir PDF sem rasterizar texto exige mais trabalho. Fica para a v1.1 |
| Links clicáveis no sumário | Escopo extra; o número da página resolve |
| Prazos e lembretes | Exige notificações |
| Validade de documentos (ex.: comprovante com mais de 90 dias) | v1.2 |
| Compartilhar o dossiê para outra pessoa preencher (ex.: o fiador) | Exige compartilhamento do CloudKit |
| Senha no PDF | Não é essencial para o problema |
| Modelos de outros países | Ver pergunta aberta 1 |

## 13. Perguntas abertas

1. **Modelos fora do Brasil.** O app está em inglês e espanhol, mas os modelos usam CPF, CNH e FGTS. **Recomendação:** em pt-BR, os modelos do Brasil; em en e es-419, modelos genéricos ("Documento de identidade", "Comprovante de residência", "Comprovante de renda") e a lista em branco.
2. **Nome "Dossiê" ou "Kit"?** O design usa "Dossiê". **Recomendação:** manter "Dossiê", que soa mais sério e é usado por imobiliárias e RH.
3. **Ordem das abas.** **Recomendação:** Dossiês primeiro, porque é o diferencial e é o que o revisor da Apple vê primeiro.

## 14. App Store

- **Textos** (`store/app-store-texts.md`): o subtítulo e a descrição passam a destacar os dossiês. Proposta de subtítulo: *"Junte documentos em um PDF"* (en: *"Gather documents into one PDF"*).
- **Capturas de tela:** a primeira mostra o checklist (tela 4), a segunda o PDF com capa e sumário (tela 7).
- **Notas para a revisão** (campo *App Review Information → Notes*), em inglês:

> Monta PDF helps people gather every document requested for a specific situation (renting an apartment, a new job, school enrollment, a mortgage). The user picks a template, sees which documents are still missing, scans, imports or reuses each one, and the app assembles a single PDF with a cover page and a table of contents. This checklist-based "dossier" workflow is the core of the app; scanning is only one way to fill an item. To try it: tap "Novo dossiê", choose "Aluguel de imóvel", add a document to any item and tap "Montar PDF".

- **Resposta à rejeição** (Central de resoluções), ao reenviar: explicar a mudança de conceito em 3 frases, citando a nota acima.

## 15. Plano de entrega (PRs)

| # | PR | Conteúdo |
| --- | --- | --- |
| 1 | `feat: dossier models and templates` | `Dossier`, `DossierItem`, relação em `Document`, `DossierTemplate`, `DossierProgress`, repositório e testes unitários |
| 2 | `feat: dossiers tab and new dossier flow` | `TabView`, telas 1, 2, 3 e 9 |
| 3 | `feat: dossier checklist` | Telas 4 e 5, "Não se aplica", adicionar, reordenar e remover itens, ligação com scanner, importação e biblioteca |
| 4 | `feat: assemble and share dossier PDF` | `DossierPDFAssembler`, telas 6, 7 e 10, prévia do PDF |
| 5 | `feat: show dossier usage in documents` | Tela 8 (tags), aviso ao apagar documento em uso |
| 6 | `test: UI tests for dossiers` | Fluxo principal e ajustes nos testes atuais |
| 7 | `docs: App Store texts for dossiers` | Textos em 3 idiomas, notas para a revisão |

Cada PR passa pelo CI e pelo SonarQube, com textos em **en, pt-BR e es-419**.
