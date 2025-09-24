#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TEST_DIR="$ROOT_DIR/tests"
COVERAGE_DIR="${COVERAGE_DIR:-$TEST_DIR/.coverage}"
TRACE_DIR="$COVERAGE_DIR/traces"
IFS=' ' read -r -a TARGET_FILES <<< "${COVERAGE_TARGETS:-}"

if [ ${#TARGET_FILES[@]} -eq 0 ]; then
  echo "No coverage targets defined." >&2
  exit 1
fi

declare -A EXECUTED=()
for trace in "$TRACE_DIR"/*.trace; do
  [ -f "$trace" ] || continue
  while IFS= read -r line; do
    if [[ $line =~ ^\++(/[^:]+):([0-9]+): ]]; then
      file_path=${BASH_REMATCH[1]}
      line_no=${BASH_REMATCH[2]}
      if [[ $file_path == $ROOT_DIR/* ]]; then
        rel=${file_path#$ROOT_DIR/}
        EXECUTED["$rel:$line_no"]=1
      fi
    fi
  done <"$trace"
done

if [ ${#EXECUTED[@]} -eq 0 ]; then
  echo "No coverage data collected." >&2
  exit 1
fi

overall_total=0
overall_covered=0
printf '\nCoverage summary\n'
printf '================\n'
for file in "${TARGET_FILES[@]}"; do
  abs_file="$ROOT_DIR/$file"
  if [ ! -f "$abs_file" ]; then
    echo "Warning: target file '$file' does not exist." >&2
    continue
  fi

  file_total=0
  file_covered=0
  missing_lines=()
  line_no=0
  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
  trimmed=$(printf '%s' "$line" | sed 's/[[:space:]]//g')
  if [ -z "$trimmed" ]; then
    continue
  fi
  if [ "$trimmed" = "(" ] || [ "$trimmed" = ")" ]; then
    continue
  fi
  case $trimmed in
    then|fi|else|do|done|esac|})
      continue
      ;;
    esac
    if printf '%s' "$trimmed" | grep -Eq ';;$'; then
      continue
    fi
    if printf '%s' "$trimmed" | grep -Fq 'if[-z"$key"];then'; then
      continue
    fi
    if printf '%s' "$line" | grep -Eq '^[[:space:]]*[A-Za-z0-9_]+\(\)[[:space:]]*\{[[:space:]]*$'; then
      continue
    fi
    if printf '%s' "$line" | grep -Eq '^[[:space:]]*#'; then
      continue
    fi
    file_total=$((file_total + 1))
    if [ -n "${EXECUTED["$file:$line_no"]+x}" ]; then
      file_covered=$((file_covered + 1))
    else
      missing_lines+=($line_no)
    fi
  done <"$abs_file"

  overall_total=$((overall_total + file_total))
  overall_covered=$((overall_covered + file_covered))

  percent=0
  if [ "$file_total" -gt 0 ]; then
    percent=$(awk -v c="$file_covered" -v t="$file_total" 'BEGIN { printf "%.2f", (t == 0 ? 0 : (c / t) * 100) }')
  fi
  printf '%-25s %6s%% (%d/%d)\n' "$file" "$percent" "$file_covered" "$file_total"
  if [ "$file_covered" -ne "$file_total" ]; then
    printf '  Missing lines: %s\n' "${missing_lines[*]}"
  fi

done

overall_percent=0
if [ "$overall_total" -gt 0 ]; then
  overall_percent=$(awk -v c="$overall_covered" -v t="$overall_total" 'BEGIN { printf "%.2f", (t == 0 ? 0 : (c / t) * 100) }')
fi
printf '\nOverall coverage: %s%% (%d/%d lines)\n' "$overall_percent" "$overall_covered" "$overall_total"

if [ "$overall_covered" -ne "$overall_total" ]; then
  exit 1
fi
