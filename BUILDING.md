# Compilar, testar e validar

Guia único para compilar, testar e validar o more-than-a-note. Vale do mesmo jeito para pessoas e agentes, em Linux, Windows e macOS. Os comandos são os mesmos nos três sistemas; só a instalação das ferramentas muda. Não use outros diretórios de build, opções `-D` avulsas ou scripts próprios: se algo faltar, ele entra aqui, por uma atividade (constituição IV).

## Requisitos

- CMake 3.25 ou mais novo e Ninja
- Compilador C++20: GCC 11+, Clang 14+ ou MSVC 2022
- Qt 6.8 ou mais novo, com Base (Core, Gui, Sql com driver SQLite, Test), Declarative (Qml, Quick, QuickControls2, QuickTest) e Svg

Fontes e ícones vêm no repositório; nada é baixado durante o build.

## O ciclo

Um comando configura, compila e roda a suíte completa:

```sh
cmake --workflow --preset release
```

| Preset | O que faz | Pasta |
| --- | --- | --- |
| `release` | App e todos os testes, otimizado | `build/release` |
| `core` | Só o núcleo e seus testes, sem Qt | `build/core` |
| `asan` | App e testes com AddressSanitizer e UBSan (Linux e macOS) | `build/asan` |
| `debug` | App e testes sem otimização, para depurar (sem workflow) | `build/debug` |

No dia a dia, depois do primeiro workflow:

```sh
cmake --build --preset release   # compila o que mudou
ctest --preset release           # suíte completa
```

Configure de novo (`cmake --preset release`) só ao acrescentar ou remover arquivos QML, fontes ou ícones. A evidência de que uma atividade terminou é a **suíte completa** do preset. Um teste isolado serve para depurar.

## Validar na galeria

A galeria é o ambiente de validação do dono do produto. O mesmo caminho serve para o agente e para a pessoa (constituição III):

```sh
cmake --build --preset release --target gallery    # abre a galeria
cmake --build --preset release --target evidence   # gera todas as capturas
```

- **`gallery`** abre a galeria num perfil isolado, em `build/release/sandbox`, que nunca toca seus cadernos nem suas preferências. O índice à esquerda leva a cada seção. A seção **Em validação** lista o que espera aprovação, e a seção **Editor** abre a janela principal num caderno de amostra.
- **`evidence`** apaga e regenera `build/release/evidence/`:
  - `tests/`: uma imagem por ponto de captura dos testes de interface;
  - `gallery/`: cada seção, como `<seção>-<graphite|light>-<100|150>.png`.

  Tudo é renderizado fora da tela, então o resultado não depende de janelas abertas. Só a checagem de tinta (`tst_native_ink.qml`) roda na sessão gráfica, porque o renderizador de software não desenha a tinta; sem sessão gráfica, ela aparece como `SKIP`.

Para abrir direto numa seção, rode o executável com o mesmo perfil:

```sh
MTN_PROFILE_DIR=build/release/sandbox ./build/release/more_than_a_note --gallery=text-card
```

No PowerShell:

```powershell
$env:MTN_PROFILE_DIR = "build/release/sandbox"
.\build\release\more_than_a_note.exe --gallery=text-card
```

Seções: `pending`, `editor`, `components`, `toolbar`, `text-card`, `index`, `islands`, `typography`, `icons` e `colors`.

## Opções do app e variáveis de ambiente

Esta é a lista fechada; criar outra exige atividade e emenda da constituição. O `.specify/scripts/check.sh` recusa o que não estiver aqui.

| Entrada | Efeito |
| --- | --- |
| `--gallery` | Abre a galeria ao lado do app |
| `--gallery=<seção>` | Abre a galeria já na seção indicada |
| `--scale=<fator>` | Simula outra escala de tela, por exemplo `--scale=1.5` |
| `MTN_PROFILE_DIR` | Pasta de um perfil isolado: cadernos e preferências ficam nela, e não nas pastas do usuário. É usada pelos alvos `gallery` e `evidence` e pelos testes |
| `MTN_CAPTURE_DIR` | Liga a captura roteirizada: com `--gallery`, salva todas as seções e encerra; nos testes, salva cada ponto de captura |
| `MTN_QT_LOG` | Arquivo que recebe as mensagens do Qt, para diagnóstico |

## Ambiente por máquina

Se o Qt ou o Ninja não estiverem nos caminhos do sistema, por exemplo num Qt SDK instalado na pasta pessoal, copie `cmake/local.cmake.example` para `cmake/local.cmake` e preencha. Esse arquivo fica fora do git e é lido por todos os presets. Nunca passe esses caminhos como `-D` na linha de comando: eles ficariam presos num único cache e outra sessão não os encontraria.

## Instalar as ferramentas

### Linux

O Qt precisa ser 6.8 ou mais novo. O Debian 13 e o Ubuntu 25.04 trazem essa versão nos pacotes. Distribuições mais antigas, como Ubuntu 24.04 e elementary OS 8, trazem 6.4: nelas, instale o Qt pelo instalador oficial e aponte-o em `cmake/local.cmake`.

Debian 13 (verificado em Docker e no CI):

```sh
sudo apt install build-essential cmake ninja-build \
    qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-svg-dev \
    libqt6sql6-sqlite libgl-dev \
    qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
    qml6-module-qtquick-window qml6-module-qtqml-workerscript qml6-module-qtquick-templates
```

- **Fedora 41+ (não verificado):** `sudo dnf install gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel`
- **Arch (não verificado):** `sudo pacman -S --needed base-devel cmake ninja qt6-base qt6-declarative qt6-svg`
- **Qualquer sistema com Docker:** `docker build -t more-than-a-note .` compila e roda as suítes `release` e `core` num Debian limpo. Ele não abre o app.

### Windows: MSYS2 (verificado)

1. Instale o [MSYS2](https://www.msys2.org/) em `C:\msys64`.
2. No terminal **MSYS2 UCRT64**:

   ```sh
   pacman -S --needed mingw-w64-ucrt-x86_64-toolchain mingw-w64-ucrt-x86_64-cmake \
       mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-qt6-base \
       mingw-w64-ucrt-x86_64-qt6-declarative mingw-w64-ucrt-x86_64-qt6-svg
   ```

3. No PowerShell, na raiz do repositório, ponha `C:\msys64\ucrt64\bin` **primeiro** no `PATH` (`$env:PATH = "C:\msys64\ucrt64\bin;$env:PATH"`) e use os mesmos comandos do ciclo. Se outro MinGW vier antes no `PATH`, as ferramentas do Qt carregam DLLs erradas e falham com `0xc0000139`.

O alvo `gallery` acrescenta a pasta do Qt ao `PATH` do processo, então a galeria abre a partir de `build\release` também. No Windows, os alvos `gallery` e `evidence` abrem as janelas por `cmake/run-windowed.cmd`, porque o CMake inicia os programas com a janela oculta. Sem isso, a galeria fica invisível e a checagem de tinta espera para sempre. Verificado com Qt 6.12 (MSYS2) em 29/10/2026.

### Windows: instalador do Qt e Visual Studio (não verificado)

Instale o Visual Studio 2022 com "Desktop development with C++" e o Qt 6.8+ para MSVC 2022 64-bit, com Qt Svg. Em `cmake/local.cmake`, aponte `CMAKE_PREFIX_PATH` para o Qt, por exemplo `C:/Qt/6.8.3/msvc2022_64`. Depois, no **x64 Native Tools Command Prompt for VS 2022**, use os comandos do ciclo.

### macOS (não verificado)

```sh
xcode-select --install
brew install cmake ninja qt
```

Em `cmake/local.cmake`, aponte `CMAKE_PREFIX_PATH` para a saída de `brew --prefix qt`. No macOS o app usa a barra de menus do sistema.

## Pacotes

| Sistema | Comando | Resultado |
| --- | --- | --- |
| Windows | `cmake --install build/release --prefix build/dist` | Pasta com o app e todas as DLLs; roda num PC sem MSYS2 |
| Windows | `cmake --build --preset release --target package` | ZIP com o Qt em `build/release/`; teste em PC limpo pendente |
| Linux | `cmake --build --preset release --target package` | `.tar.gz` só com o app; exige Qt 6.8+ instalado |
| macOS | `cmake --install build/release --prefix build/dist` | `.app` com o Qt dentro (não verificado) |

Um pacote Linux portátil (AppImage, Flatpak ou `.deb` com Qt) é a etapa E8.

## CI

O workflow Linux roda `.specify/scripts/check.sh` e, num Debian em Docker, as suítes `release` (GCC), `asan` e `core` (Clang). O workflow Windows roda o workflow `release` com MSYS2 UCRT64. Os dois publicam as capturas de `evidence` como artefato. Um CI verde cobre build e testes automáticos; ele não substitui leitor de tela, DPI misto nem o teste do ZIP num PC limpo.

## Problemas comuns

| Problema | Causa e solução |
| --- | --- |
| `Qt 6.8+ was not found` | O Qt não está nos caminhos. Aponte-o em `cmake/local.cmake` ou use o preset `core`. |
| `0xc0000139` no Windows | DLLs erradas no `PATH`. Ponha `C:\msys64\ucrt64\bin` primeiro. |
| O app pisca e fecha no Windows | O exe foi aberto fora do terminal configurado. Use o alvo `gallery` ou `build\dist`. |
| Ícones não aparecem | Falta o módulo Qt Svg. |
| `module "QtQuick.Controls" is not installed` no Linux | Instale os pacotes `qml6-module-*` da sua distribuição. |
| A janela não aparece | Ela pode ter aberto em outro monitor; confira a barra de tarefas. |
