# M2 — Revisão arquitetural do editor visual unificado

- **Tipo:** manutencao
- **Estado:** aprovada
- **Aberta em:** 2026-10-30
- **Origem:** pedido explícito do dono do produto sobre a base E4.7, HEAD `25f20a2`; M1 aprovada, ainda não fechada.
- **Documentos donos:** 22 (arquitetura proposta), 20 (Marco 3), 21 (E6), EX1 (protocolo); contratos vigentes continuam em 02, 03, 06, 10, 13, 14 e 16.

## Problema e objetivo

Confrontar o editor implementado com a integração de texto rico, diagramas e tinta. Entregar contratos, alternativas e uma sequência incremental rastreáveis ao código, sem implementar nem aprovar mudanças de produto.

## Histórias e critérios de aceite

### US1 — Arquitetura verificável (P1)

1. Mapear modelo, coordenadas, entrada, seleção, renderização e histórico com arquivos e símbolos; distinguir implementado, testado anteriormente e não comprovado nesta sessão.
2. Comparar alternativas e registrar decisões estruturadas com riscos, confiança e experimentos.
3. Exercitar o desenho nos cenários A–D do pedido, com invariantes e falhas.

### US2 — Plano de engenharia (P1)

1. Derivar Marco 3 com formato proposto, compatibilidade, etapas pequenas, aceitação e roteiro futuro de galeria.
2. Definir EX1 reproduzível sem protótipo, números inventados ou escolha definitiva de motor.
3. Auditar E6 com evidência, cenários de falha, severidade, mitigação e testes necessários.

### US3 — Governança e entrega (P1)

1. Preservar os contratos aprovados e pendências da M1; atualizar os documentos donos por referências explícitas às propostas.
2. Manter código, testes, build e CI intactos; registrar verificações executadas e impedimentos.
3. Deixar M2 em validação documental, com aprovações abertas e divergências dos portões técnicos visíveis.

## Casos de borda

Formato futuro; persistência parcial; falha após edição em memória; seleção mista com texto em composição; grupo com conectores externos; DPI misto; limites de tinta; concorrência externa.

## Fora de escopo

Código de produção, testes, build, CI, dependências, protótipos, migrações executadas, commits, redesign e fechamento da M1.

## Esclarecimentos

- 30/10/2026: escopo documental explícito autoriza abrir M2 sem fechar M1; nenhuma sobreposição de arquivos de implementação. Árvore inicialmente limpa.
- A revisão não aprova atalhos, formato novo, suporte de plataforma ou troca de motor. Perguntas de produto ficam no documento 22 para validação final.
- Os nomes 20, 21 e 22 estavam livres; não havia EX1.md, apenas o catálogo no 14. Criar o registro seguindo seu §6.
- Resultado técnico: check.sh passou; suíte completa não iniciou porque cmake não está no PATH. O checklist conserva esse portão aberto. Validação documental não aprova implementação nem resolve automaticamente conflitos de contrato.

## Critérios de sucesso

US1–US3 cobertas por tarefas e documentos cruzados; conclusões relevantes ligadas ao código; nenhuma alteração executável; EX1 preliminar; aprovação exclusivamente humana. Falhas de ferramentas ou portões não serão registradas como aprovação.
