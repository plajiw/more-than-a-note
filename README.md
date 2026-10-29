# more-than-a-note

more-than-a-note é o nome provisório de um caderno digital para desktop, voltado a estudantes e professores e planejado como software livre. Ele combina texto móvel, escrita à mão, imagens e diagramas em páginas organizadas em cadernos e seções. Funciona sem internet, com arquivos locais e opções de exportação.

## Comece por aqui

- **Compilar, testar e validar:** [BUILDING.md](BUILDING.md). O mesmo fluxo vale em Linux, Windows e macOS:

  ```sh
  cmake --workflow --preset release                  # configura, compila e roda os testes
  cmake --build --preset release --target gallery    # abre a galeria de validação
  cmake --build --preset release --target evidence   # gera as capturas roteirizadas
  ```

- **Onde o projeto está e o que vem a seguir:** [roadmap vivo](specs/ROADMAP.md)
- **Regras de trabalho para pessoas e agentes:** [AGENTS.md](AGENTS.md), [constituição](.specify/memory/constitution.md) e [fluxo de uma atividade](.specify/workflow.md)
- **Documentos de produto, arquitetura e visual:** [docs/](docs/README.md)

## Estrutura

| Pasta | Conteúdo |
| --- | --- |
| `apps/desktop/` | Aplicativo Qt: backend C++, `Main.qml` e componentes em `ui/` |
| `core/model/` | Núcleo C++20 sem Qt: cadernos, páginas, histórico e codecs |
| `tests/` | Testes do núcleo e do backend; `tests/qml/` tem os testes de interface |
| `docs/` | Documentos de produto, arquitetura e visual (pt-BR); `images/` e `experiments/` |
| `specs/` | Uma pasta por atividade (spec, plano, tarefas, validação) e o roadmap |
| `.specify/` | Constituição, fluxo, modelos e scripts do processo |
| `cmake/` | `local.cmake.example`, para caminhos específicos de cada máquina |
