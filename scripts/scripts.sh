#!/bin/bash
# =============================================================
# generate_headers.sh — ContextCompass
# Generuje lub sprawdza nagłówki plików TS/TSX/JS
# Użycie: ./scripts/generate_headers.sh [--check-only]
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

MISSING_COUNT=0
FOUND_COUNT=0
CHECK_ONLY=false

if [[ "$1" == "--check-only" ]]; then
  CHECK_ONLY=true
  echo -e "${CYAN}Tryb sprawdzania (--check-only): nagłówki nie będą dodawane${NC}"
fi

echo ""
echo -e "${CYAN}ContextCompass — Sprawdzanie nagłówków plików${NC}"
echo "================================================"

find packages -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/dist/*" \
  ! -path "*/.turbo/*" \
  ! -name "*.d.ts" \
  | sort \
  | while read -r file; do

  first_line=$(head -n1 "$file")

  if [[ "$first_line" == "/*"* ]]; then
    echo -e "  ${GREEN}✓${NC} $file"
    FOUND_COUNT=$((FOUND_COUNT + 1))
    continue
  fi

  MISSING_COUNT=$((MISSING_COUNT + 1))

  if [[ "$CHECK_ONLY" == true ]]; then
    echo -e "  ${RED}✗ BRAK NAGŁÓWKA${NC}: $file"
    continue
  fi

  # Wygeneruj nagłówek automatycznie
  filename=$(basename "$file")
  relative_path="${file#./}"

  # Zbierz eksporty
  exports=$(grep -E '^export (const|function|class|interface|type|enum|default)' "$file" \
    | awk '{print $2}' \
    | tr '\n' ', ' \
    | sed 's/, $//' \
    | sed 's/^$/\(none\)/')

  if [ -z "$exports" ]; then
    exports="(none)"
  fi

  # Zbierz importy
  depends=$(grep -E "^import .* from ['\"]" "$file" \
    | sed "s/.*from ['\"]\\(.*\\)['\"].*/\\1/" \
    | tr '\n' ', ' \
    | sed 's/, $//')

  if [ -z "$depends" ]; then
    depends="(none)"
  fi

  header="/*\n * File:       $filename\n * Path:       $relative_path\n * Exports:    $exports\n * Depends on: $depends\n * Purpose:    TODO — opisz funkcję tego pliku\n */"

  # Obsługa pliku z shebang
  if [[ "$first_line" == "#!"* ]]; then
    temp_file=$(mktemp)
    {
      head -n1 "$file"
      printf "%b\n" "$header"
      tail -n +2 "$file"
    } > "$temp_file"
    mv "$temp_file" "$file"
  else
    temp_file=$(mktemp)
    {
      printf "%b\n\n" "$header"
      cat "$file"
    } > "$temp_file"
    mv "$temp_file" "$file"
  fi

  echo -e "  ${YELLOW}+ DODANO NAGŁÓWEK${NC}: $file"
done

echo ""
echo "================================================"

if [[ "$CHECK_ONLY" == true ]]; then
  if [[ $MISSING_COUNT -gt 0 ]]; then
    echo -e "${RED}BŁĄD: $MISSING_COUNT plików bez nagłówka${NC}"
    exit 1
  else
    echo -e "${GREEN}OK: Wszystkie pliki mają nagłówki${NC}"
  fi
else
  echo -e "Gotowe. Pliki z nagłówkiem: ${GREEN}$FOUND_COUNT${NC} | Dodano nagłówki: ${YELLOW}$MISSING_COUNT${NC}"
fi

---

#!/bin/bash
# =============================================================
# check_file_lengths.sh — ContextCompass
# Sprawdza czy pliki nie przekraczają limitu linii
# Użycie: ./scripts/check_file_lengths.sh [--fail-on-error]
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Limity per typ pliku
COMPONENT_LIMIT=150
HOOK_LIMIT=100
SERVICE_LIMIT=150
PAGE_LIMIT=120
TYPE_LIMIT=200
EDGE_FUNCTION_LIMIT=150
DEFAULT_LIMIT=200

FAIL_ON_ERROR=false
ERRORS=0
WARNINGS=0

if [[ "$1" == "--fail-on-error" ]]; then
  FAIL_ON_ERROR=true
fi

echo ""
echo -e "${CYAN}ContextCompass — Sprawdzanie rozmiarów plików${NC}"
echo "================================================"

check_file() {
  local file="$1"
  local lines=$(wc -l < "$file")
  local limit=$DEFAULT_LIMIT
  local type="plik"

  # Określ limit na podstawie lokalizacji/nazwy
  if [[ "$file" =~ /pages/ ]]; then
    limit=$PAGE_LIMIT
    type="strona"
  elif [[ "$file" =~ /hooks/ ]]; then
    limit=$HOOK_LIMIT
    type="hook"
  elif [[ "$file" =~ /components/ ]]; then
    limit=$COMPONENT_LIMIT
    type="komponent"
  elif [[ "$file" =~ /services/ ]]; then
    limit=$SERVICE_LIMIT
    type="serwis"
  elif [[ "$file" =~ /types/ ]]; then
    limit=$TYPE_LIMIT
    type="typy"
  elif [[ "$file" =~ /functions/ ]]; then
    limit=$EDGE_FUNCTION_LIMIT
    type="edge function"
  fi

  if [[ $lines -gt $limit ]]; then
    echo -e "  ${RED}✗ PRZEKROCZONO${NC} ($lines/$limit linii) [$type]: $file"
    ERRORS=$((ERRORS + 1))
  elif [[ $lines -gt $((limit * 80 / 100)) ]]; then
    # Ostrzeżenie przy 80% limitu
    echo -e "  ${YELLOW}⚠ UWAGA${NC} ($lines/$limit linii) [$type]: $file"
    WARNINGS=$((WARNINGS + 1))
  fi
  # Pliki ok — nie wyświetlamy (za dużo szumu)
}

find packages supabase/functions -type f \( -name "*.ts" -o -name "*.tsx" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/dist/*" \
  ! -name "*.d.ts" \
  | sort \
  | while read -r file; do
  check_file "$file"
done

echo ""
echo "================================================"
echo -e "Błędy (przekroczony limit): ${RED}$ERRORS${NC}"
echo -e "Ostrzeżenia (>80% limitu):  ${YELLOW}$WARNINGS${NC}"

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GREEN}Wszystkie pliki w normie!${NC}"
fi

if [[ "$FAIL_ON_ERROR" == true && $ERRORS -gt 0 ]]; then
  echo -e "${RED}CI zakończone błędem — podziel zbyt długie pliki${NC}"
  exit 1
fi
