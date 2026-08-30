#!/usr/bin/env bash
set -euo pipefail

REPO="${OMP_GITHUB_REPO:-riverai7z/omp}"
REF="${OMP_GITHUB_REF:-master}"
RAW_BASE="${OMP_RAW_BASE:-https://raw.githubusercontent.com/${REPO}/${REF}}"
TTY=/dev/tty

if ! command -v pi >/dev/null 2>&1; then
  printf 'Error: pi is not installed or is not in PATH.\n' >&2
  exit 1
fi

if [[ ! -r "$TTY" || ! -w "$TTY" ]]; then
  printf 'Error: interactive installation requires a terminal.\n' >&2
  exit 1
fi

names=(
  "@juicesharp/rpiv-ask-user-question"
  "@narumitw/pi-btw"
  "@narumitw/pi-goal"
  "@narumitw/pi-plan-mode"
  "@riverai7z/pi-read"
  "@riverai7z/pi-todo"
  "pi-sandbox"
  "pi-simplify"
  "pi-web-access"
  "extensions/tools.ts"
)
packages=(
  "npm:@juicesharp/rpiv-ask-user-question"
  "npm:@narumitw/pi-btw"
  "npm:@narumitw/pi-goal"
  "npm:@narumitw/pi-plan-mode"
  "npm:@riverai7z/pi-read"
  "npm:@riverai7z/pi-todo"
  "npm:pi-sandbox"
  "npm:pi-simplify"
  "npm:pi-web-access"
  ""
)

exec 3<>"$TTY"
checked=()
for name in "${names[@]}"; do
  if [[ "$name" == "@riverai7z/pi-read" ]]; then
    checked+=(0)
  else
    checked+=(1)
  fi
done
cursor=0
ui_active=0

cleanup() {
  if ((ui_active)); then
    printf '\033[?25h\033[?1049l' >&3
    ui_active=0
  fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

render_menu() {
  printf '\033[H\033[2J' >&3
  printf 'OMP plugin installer\n\n' >&3
  printf 'Use ↑/↓ to move, Space to select, Enter to install.\n' >&3
  printf 'Press a to toggle all, or q to cancel.\n\n' >&3

  for i in "${!names[@]}"; do
    marker=' '
    ((checked[i])) && marker='x'
    if ((i == cursor)); then
      printf '\033[7m> [%s] %s\033[0m\n' "$marker" "${names[$i]}" >&3
    else
      printf '  [%s] %s\n' "$marker" "${names[$i]}" >&3
    fi
  done
}

printf '\033[?1049h\033[?25l' >&3
ui_active=1
while true; do
  render_menu
  key=''
  IFS= read -rsn1 key <&3
  if [[ "$key" == $'\033' ]]; then
    sequence=''
    IFS= read -rsn2 -t 0.1 sequence <&3 || true
    key+="$sequence"
  fi

  case "$key" in
    $'\033[A')
      ((cursor > 0)) && ((cursor--)) || true
      ;;
    $'\033[B')
      ((cursor < ${#names[@]} - 1)) && ((cursor++)) || true
      ;;
    ' ')
      checked[cursor]=$((1 - checked[cursor]))
      ;;
    a|A)
      next=0
      for value in "${checked[@]}"; do
        if ((!value)); then
          next=1
          break
        fi
      done
      for i in "${!checked[@]}"; do
        checked[i]=$next
      done
      ;;
    q|Q)
      cleanup
      printf 'Installation cancelled.\n' >&3
      exit 0
      ;;
    '')
      break
      ;;
  esac
done

selected=()
for i in "${!checked[@]}"; do
  ((checked[i])) && selected+=("$i")
done

cleanup
if ((${#selected[@]} == 0)); then
  printf 'Nothing selected.\n' >&3
  exit 0
fi

printf '\n' >&3
for index in "${selected[@]}"; do
  name=${names[$index]}
  package=${packages[$index]}
  printf 'Installing %s...\n' "$name" >&3

  if [[ -n "$package" ]]; then
    pi install "$package"
  else
    if ! command -v curl >/dev/null 2>&1; then
      printf 'Error: curl is required to install Tools.\n' >&2
      exit 1
    fi
    extension_dir="${PI_AGENT_DIR:-$HOME/.pi/agent}/extensions"
    mkdir -p "$extension_dir"
    curl -fsSL "${RAW_BASE}/extensions/tools.ts" -o "$extension_dir/tools.ts"
  fi
done

printf '\nDone. Restart pi to load the selected plugins.\n' >&3
