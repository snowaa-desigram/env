#!/usr/bin/env bash
# Собирает графы в /out (var/archviz на хосте) из /src (backend). Сервисы находит сам: cmd/* и members pyproject.toml.
# Падение одного генератора не останавливает остальные: лог — рядом с графом (<name>.log), код выхода ненулевой.
set -u

SRC=${SRC:-/src}
OUT=${OUT:-/out}
fail=0

mkdir -p "$OUT/core" "$OUT/go" "$OUT/python"

# run <log> <cmd...>: успех — лог удаляется; провал — лог остаётся, fail=1
run() {
  local log=$1; shift
  printf '==> %s\n' "$*"
  if "$@" >"$log" 2>&1; then rm -f "$log"; return 0; fi
  fail=1; printf '   FAILED, см. %s\n' "${log#"$OUT"/}"; return 1
}

# ---------- core: layers.dot (deptrac, рендерит контейнер core) → svg ----------
if [[ -f "$OUT/core/layers.dot" ]]; then
  run "$OUT/core/layers.log" dot -Tsvg -o "$OUT/core/layers.svg" "$OUT/core/layers.dot"
else
  echo "core: нет $OUT/core/layers.dot (make archviz запускает deptrac в core до render)" >"$OUT/core/layers.log"; fail=1
fi

# ---------- go: граф пакетов модуля + граф вызовов по каждому cmd/<name> ----------
cd "$SRC/services/go" || exit 1
MOD=$(sed -n 's/^module //p' go.mod)
# только пакеты модуля (без зависимостей и stdlib), кластеры по каталогам
run "$OUT/go/packages.log" bash -c "goda graph -cluster -short '$MOD/...' | dot -Tsvg -o '$OUT/go/packages.svg'"
for d in cmd/*/; do
  n=$(basename "$d")
  # go-callvis пишет <file>.svg; -focus '' — весь граф, -limit — только код сервиса, -nostd — без stdlib, кластеры по пакетам/типам
  run "$OUT/go/$n.log" go-callvis -nostd -focus '' -limit "$MOD/cmd/$n,$MOD/internal/$n" -group pkg,type -format svg -file "$OUT/go/$n" "./cmd/$n"
done

# ---------- python: граф модулей по каждому member uv-workspace ----------
cd "$SRC/services/python" || exit 1
if run "$OUT/python/uv-sync.log" uv sync --frozen --all-packages -q; then
  for m in $(sed -n 's/^members *= *\[\(.*\)\]/\1/p' pyproject.toml | tr -d '",'); do
    pkg=$(find "$m" -maxdepth 2 -name __init__.py -not -path '*/tests/*' -not -path '*/gen/*' -exec dirname {} \; | head -1)
    [[ -n "$pkg" ]] || continue
    n=$(basename "$pkg")
    run "$OUT/python/$n.log" uv run --no-sync --with 'pydeps==3.0.8' pydeps "$pkg" --noshow -T svg -o "$OUT/python/$n.svg" \
      --cluster --max-bacon 2 -x 'grpc*' 'google*' 'desigram.*'
  done
fi

# ---------- index.html ----------
item() { # <title> <path-to-html-or-svg> [<log>]
  local title=$1 file=$2 log=${3:-}
  if [[ -e "$OUT/$file" ]]; then
    printf '<li><a href="%s">%s</a></li>\n' "$file" "$title"
  else
    printf '<li>%s — <b>не собран</b>%s</li>\n' "$title" "${log:+ (<a href=\"$log\">$log</a>)}"
  fi
}
{
  cat <<'HTML'
<!doctype html><meta charset="utf-8"><title>archviz</title>
<style>body{font:15px/1.5 system-ui;max-width:60rem;margin:2rem auto;padding:0 1rem}li{margin:.25rem 0}code{background:#eee;padding:0 .3em}</style>
<h1>Граф кода</h1>
<p>Собрано <code>make archviz</code>. Слои и нейминг — <code>openspec/specs/architecture-*</code>.</p>
HTML
  echo "<p><small>$(date -u +'%Y-%m-%d %H:%M UTC')</small></p>"
  echo '<h2>core (Symfony)</h2><ul>'
  item 'Слои DDD (deptrac)' core/layers.svg core/layers.log
  item 'Классы: связанность, сложность, граф зависимостей (phpmetrics)' core/metrics/index.html
  echo '</ul><h2>Go</h2><ul>'
  item 'Пакеты модуля (goda)' go/packages.svg go/packages.log
  for d in "$SRC"/services/go/cmd/*/; do n=$(basename "$d"); item "Вызовы: $n (go-callvis)" "go/$n.svg" "go/$n.log"; done
  echo '</ul><h2>Python</h2><ul>'
  for f in "$OUT"/python/*.svg "$OUT"/python/*.log; do
    [[ -e "$f" ]] || continue; n=$(basename "${f%.*}"); [[ $n == uv-sync ]] && continue
    item "Модули: $n (pydeps)" "python/$n.svg" "python/$n.log"
  done
  [[ -e "$OUT/python/uv-sync.log" ]] && echo '<li>uv sync — <b>упал</b> (<a href="python/uv-sync.log">лог</a>)</li>'
  echo '</ul>'
} >"$OUT/index.html"

echo "index: $OUT/index.html"
exit $fail
