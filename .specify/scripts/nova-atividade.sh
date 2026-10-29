#!/usr/bin/env bash
# Opens a new activity: specs/NNN-<id>-<slug>/ from the templates, points
# .specify/feature.json at it and appends its row to the specs/ROADMAP.md register.
# The roadmap text, checklist and graph are then updated by hand (fluxo, step 1).
#
#   .specify/scripts/nova-atividade.sh E4.8 carga-e-acessibilidade "Carga e acessibilidade" roadmap
#
# Types: roadmap (E<n>.<m>), desvio (C<n>), manutencao (M<n>).
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
    echo "uso: $0 <id> <slug> \"<título>\" [roadmap|desvio|manutencao]" >&2
    exit 2
fi
id=$1 slug=$2 title=$3 kind=${4:-roadmap}
case $kind in roadmap|desvio|manutencao) ;; *) echo "tipo inválido: $kind" >&2; exit 2 ;; esac
[[ $slug =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { echo "slug deve ser minúsculo-com-hifens: $slug" >&2; exit 2; }

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
specs=$root/specs
templates=$root/.specify/templates

if grep -qE "^\| [0-9]{3} \| ${id//./\\.} \|" "$specs/ROADMAP.md"; then
    echo "a atividade $id já existe no índice" >&2
    exit 1
fi

last=$(find "$specs" -maxdepth 1 -type d -regex '.*/[0-9][0-9][0-9]-.*' -printf '%f\n' | sort | tail -n1 | cut -c1-3)
number=$(printf '%03d' $((10#${last:-0} + 1)))
name=$number-${id,,}-$slug
dir=$specs/$name
today=$(date +%F)

escape() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }
fill() {
    sed -e "s|{{ID}}|$(escape "$id")|g" -e "s|{{TITULO}}|$(escape "$title")|g" -e "s|{{DATA}}|$today|g" "$1" > "$2"
}

mkdir -p "$dir/checklists"
fill "$templates/spec-template.md" "$dir/spec.md"
fill "$templates/plan-template.md" "$dir/plan.md"
fill "$templates/tasks-template.md" "$dir/tasks.md"
fill "$templates/validacao-template.md" "$dir/checklists/validacao.md"
sed -i "s|^- \*\*Tipo:\*\* .*|- **Tipo:** $kind|" "$dir/spec.md"

printf '{\n  "feature_directory": "specs/%s"\n}\n' "$name" > "$root/.specify/feature.json"
printf '| %s | %s | [%s](%s/spec.md) | %s | rascunho | %s |\n' \
    "$number" "$id" "$title" "$name" "$kind" "$today" >> "$specs/ROADMAP.md"

echo "criada: specs/$name"
echo "ativa em .specify/feature.json"
echo "próximo passo: atualizar specs/ROADMAP.md (onde estamos, checklist e gráfico) e preencher spec.md (.specify/fluxo.md, passo 1)"
