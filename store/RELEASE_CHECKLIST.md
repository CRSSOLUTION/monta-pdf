# Checklist de publicação na App Store

Passo a passo para enviar uma versão para a App Store, com as lições dos envios do **Grocery Home** (aprovado na 1.0 build 6, depois de uma rejeição) e do **Monta PDF** (1.0 build 2, enviado em 02/11/2026).

Siga na ordem. Cada seção tem as armadilhas que já custaram tempo.

---

## 1. Antes do Archive

- [ ] `main` atualizado e CI verde (testes unitários, testes de UI, SonarQube).
- [ ] **Versão** (`MARKETING_VERSION`) e **build** (`CURRENT_PROJECT_VERSION`) atualizados. O build precisa ser maior que o último enviado.
- [ ] **Edit Scheme → Run → Arguments:** nenhum argumento de teste marcado (`-ui-testing`, `-ui-testing-signed-in`).
- [ ] **Info.plist sem permissões mortas.** Só declare câmera, fotos, localização etc. se o app usar de verdade.
  > Grocery Home: tinha câmera e galeria declaradas sem uso. Isso entrou na lista de correções da rejeição.
- [ ] `ITSAppUsesNonExemptEncryption = NO` no Info.plist (evita a pergunta de criptografia a cada build).
- [ ] `PrivacyInfo.xcprivacy` presente e atualizado.
- [ ] Exclusão de conta dentro do app, se houver login (Guideline 5.1.1(v)).
- [ ] Links de Política de Privacidade e Termos dentro do app.
- [ ] **O Xcode está aberto na pasta certa do repositório.**
  > Grocery Home: o Xcode estava aberto numa cópia duplicada e desatualizada do repositório. Os builds não refletiam as correções.

## 2. Archive e envio do build

1. Destino: **Any iOS Device (arm64)** (não um simulador, nem um iPhone com iOS abaixo do mínimo).
2. **Product → Archive.**
3. No Organizer: **Validate App** → método **Validate** (configurações recomendadas). Só segue se aparecer "successfully validated".
4. **Distribute App** → **App Store Connect** → **Upload**.
5. Espere o build sair de "Processando" na aba **TestFlight** (5 a 30 minutos, chega e-mail).

## 3. Backend e serviços (antes de enviar para revisão)

### CloudKit (Monta PDF)
- [ ] **Deploy do schema para Production:** CloudKit Console → container → **Development** → **Deploy Schema Changes…** → **Deploy**.
- [ ] Confirme em **Production → Schema → Record Types** que os tipos (ex.: `CD_Document`) aparecem.
- O schema de Development só é criado por um build **Debug rodado pelo Xcode** que salve pelo menos um registro.
- **O TestFlight e a App Store usam Production.** Sem o deploy, nada sincroniza para quem baixa da loja.
- Em Production o schema é só leitura (cadeado). O deploy sempre parte do Development.

### Push / APNs (Grocery Home)
- [ ] Chave APNs (`.p8`) criada no Apple Developer → **Keys**, com escopo **Sandbox & Production** (escolha permanente).
- O `.p8` **só pode ser baixado uma vez**. Guarde fora do repositório e anote o **Key ID** e o **Team ID**.
- [ ] Chave cadastrada no Firebase → Project Settings → Cloud Messaging → Apple app configuration.
- Sem essa chave, o envio falha com `Invalid APNs credential`, sem nenhum erro aparecendo no app.

### Segredos
- Nunca colar `.p8`, tokens ou chaves no chat, em print, em commit ou em issue. Eles vão como secret no GitHub Actions ou no Cloudflare.
- Se um token aparecer num print, **gire o token** (gere outro e revogue o antigo).

## 4. Prints da loja (Guideline 2.3.3)

- [ ] **Os prints mostram o app em uso**, não só login, cadastro ou "esqueci a senha".
  > Grocery Home foi **rejeitado** por isso: os prints eram login, criar conta e redefinir senha. Aprovou depois de trocar por lista de compras, edição de item, Modo Mercado e histórico.
- [ ] O **primeiro print** é o mais importante: ele aparece nos resultados de busca. Coloque uma tela do app funcionando.
- [ ] **Leia o tamanho aceito na própria tela do App Store Connect** antes de gerar os arquivos. A tela mudou em 2026:
  - Aba **"Prévias e capturas de tela do app"** → **"iPhone com Dynamic Island (tela média)"**: **1206 × 2622** ou **1179 × 2556** (retrato).
  - Aba **"Cabeçalho e resultados de busca"** é outra coisa: banner horizontal **3840 × 1646** ou **5244 × 2950**, opcional. Não envie prints ali.
  - Se der erro, clique em **"Mostrar detalhes"** no aviso vermelho: ele lista os tamanhos aceitos.
- [ ] Tire o print direto no aparelho (botão lateral + volume) e **não toque na miniatura**: cortar ou editar muda o tamanho e o arquivo é recusado.
- [ ] Abra o app **pela tela inicial**, não pelo TestFlight (some o "◀ TestFlight" na barra de status).
- [ ] Use **dados fictícios** (sem RG, CPF, contratos, fotos pessoais).
- [ ] Antes de importar arquivos de exemplo, dê **nomes limpos** a eles. O Monta PDF usa o nome do arquivo como título do documento.
- [ ] Sem alertas do sistema nos prints (pedido de câmera, confirmação de exclusão).
- [ ] Não precisa de prints de iPad, Apple Watch ou "iPhone Duo" se o app é só para iPhone.

## 5. Página do app no App Store Connect

- [ ] **Textos:** nome, subtítulo, texto promocional, descrição, palavras-chave, URL de suporte, copyright (em `store/app-store-texts.md`).
- [ ] **A descrição só fala do que existe no build enviado.**
  > Grocery Home: a descrição citava uma notificação push e uma função de "reatribuir admin" que ainda não existiam. Teve que ser corrigida.
- [ ] **Build:** ＋ → escolher o build processado.
- [ ] **Informações para revisão:**
  - Com login por e-mail e senha: marque "Início de sessão obrigatório" e dê uma **conta de teste que funcione**.
  - Só com Sign in with Apple: deixe desmarcado e explique nas notas que qualquer Apple ID funciona.
  - Notas com o passo a passo para testar cada recurso, avisando o que precisa de aparelho físico (ex.: câmera).
- [ ] **Lançamento da versão:** "Lançar automaticamente" (ou manual, se quiser escolher o dia).

### Itens que a Apple só cobra na hora de enviar
- [ ] **Informações do app → Direitos de conteúdo:** "Não, este app não contém, exibe ou acessa conteúdo de terceiros" (se o conteúdo é do próprio usuário).
- [ ] **Preços e disponibilidade:** escolher o preço, mesmo que seja **Grátis**.
- [ ] **Classificação etária** respondida.
- [ ] **Privacidade do app** respondida (ex.: "Não coletamos dados").
- [ ] **Status de comerciante (UE/DSA):** pessoa física com app grátis → "Não sou comerciante".
- [ ] Categoria principal (e secundária, opcional).

## 6. Envio e acompanhamento

1. **Adicionar para revisão → Enviar para revisão.**
2. Status: Aguardando revisão → Em revisão → Pronto para distribuição (ou Rejeitado).
3. **Não clique em "Cancelar envio"** (o app volta para o fim da fila), a não ser que precise trocar algo que só dá para mudar assim.
4. Se for rejeitado: leia a guideline citada, corrija só o que foi pedido e responda na Central de Resoluções.
5. Quando aprovar: crie a **tag** do commit exato do build (ex.: `v1.0-2-approved`) e a release no GitHub.

---

## Linha do tempo de referência

| App | Versão | Resultado | Motivo / observação |
|---|---|---|---|
| Grocery Home | 1.0 | Rejeitado | 2.3.3: prints só com login, cadastro e senha |
| Grocery Home | 1.0 (6) | Aprovado em 22/10/2026 | Prints com o app em uso, Info.plist limpo, descrição corrigida |
| Monta PDF | 1.0 (2) | Enviado em 02/11/2026 | Prints redimensionados para 1206 × 2622; schema do CloudKit enviado para Production antes do envio |
