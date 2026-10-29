#!/usr/bin/env bash
# Checks the rules of .specify/memory/constitution.md that a script can verify.
# Run before asking for validation and before closing an activity; CI runs it
# too. Prints every violation and exits 1 if there is any.
#
#   .specify/scripts/check.sh
set -uo pipefail

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$root" || exit 2
failures=0
fail() { echo "FALHA: $*"; failures=$((failures + 1)); }

# II. The active activity exists and is listed as in progress in the roadmap.
active=$(sed -n 's/.*"feature_directory": *"\([^"]*\)".*/\1/p' .specify/feature.json)
if [[ -n $active ]]; then
    [[ -d $active ]] || fail "feature.json aponta para pasta inexistente: $active"
    for file in spec.md plan.md tasks.md checklists/validation.md; do
        [[ -f $active/$file ]] || fail "$active sem $file"
    done
    id=$(sed -n '1s/^# \([^ ]*\) .*/\1/p' "$active/spec.md" 2>/dev/null)
    sed -n '/^### Em andamento/,/^### /p' specs/ROADMAP.md | grep -q "\*\*$id " ||
        fail "a atividade ativa $id não está em “Em andamento” no roadmap"
fi

# II. An activity past "rascunho"/"especificada" has no open clarification.
for spec in specs/[0-9][0-9][0-9]-*/spec.md; do
    [[ -f $spec ]] || continue
    state=$(sed -n 's/^- \*\*Estado:\*\* *//p' "$spec")
    case $state in rascunho*|especificada*|descartada*) continue ;; esac
    grep -q 'PRECISA ESCLARECER:' "$spec" && fail "$spec está “$state” com [PRECISA ESCLARECER] aberto"
done

# II. Every registered activity appears in the roadmap checklist and graph.
graph=$(sed -n '/^## Caminho percorrido/,/^## Caminho à frente/p' specs/ROADMAP.md)
checklist=$(sed -n '/^## Checklist/,/^## Como atualizar/p' specs/ROADMAP.md)
while IFS='|' read -r _ _ id _; do
    id=$(echo "$id" | xargs)
    [[ -z $id ]] && continue
    grep -q "\*\*$id " <<<"$checklist" || fail "$id está no registro, mas não no checklist do roadmap"
    grep -qE "(branch |commit id: \")$id[- ]" <<<"$graph" || fail "$id está no registro, mas não no gráfico do roadmap"
done < <(sed -n '/^## Registro/,$p' specs/ROADMAP.md | grep -E '^\| [0-9]{3} \|')

# III. Only the documented command-line options and environment variables.
allowed_options='--gallery --gallery= --scale='
for option in $(grep -ohE '"--[a-z][a-z-]*=?' apps/desktop/main.cpp | tr -d '"' | sort -u); do
    [[ " $allowed_options " == *" $option "* ]] || fail "opção não documentada em main.cpp: $option"
done
allowed_variables='MTN_PROFILE_DIR MTN_CAPTURE_DIR MTN_QT_LOG MTN_V1_FIXTURE_PATH'
for variable in $(git grep -ohE 'MTN_[A-Z0-9_]+' -- apps tests CMakeLists.txt CMakePresets.json | sort -u); do
    [[ " $allowed_variables " == *" $variable "* ]] || fail "variável não documentada: $variable"
done
for variable in MTN_PROFILE_DIR MTN_CAPTURE_DIR MTN_QT_LOG; do
    grep -q "$variable" BUILDING.md || fail "$variable não está no BUILDING.md"
done

# III. UI tests do not depend on run order or pass silently offscreen.
git grep -nE 'function test_z' -- tests/qml && fail "nome de teste ordenado por prefixo z"
git grep -nE '!\s*(input|keyboard)Driver\.isOffscreen\(' -- tests/qml &&
    fail "checagem desviada em silêncio no offscreen; use skip() com motivo"

# IV. build/ holds only preset directories.
if [[ -d build ]]; then
    presets=$(grep -oE '"name": *"[a-z]+"' CMakePresets.json | sed 's/.*"\([a-z]*\)"/\1/' | sort -u)
    for dir in build/*/; do
        name=$(basename "$dir")
        grep -qx "$name" <<<"$presets" || fail "build/$name não pertence a nenhum preset"
    done
fi

# Commits not yet on origin/main start with an activity ID.
if git rev-parse -q --verify origin/main >/dev/null; then
    while read -r hash subject; do
        [[ $subject =~ ^(E[0-9]+(\.[0-9]+)?|C[0-9]+|M[0-9]+):\  ]] ||
            fail "commit $hash sem ID de atividade: $subject"
    done < <(git log --no-merges --format='%h %s' origin/main..HEAD)
fi

if ((failures)); then
    echo "$failures violação(ões) das regras da constituição."
    exit 1
fi
echo "ok: regras verificáveis da constituição atendidas."
