#!/usr/bin/env bash
set -euo pipefail

REPO="${OMP_GITHUB_REPO:-riverai7z/omp}"
REF="${OMP_GITHUB_REF:-master}"
RAW_BASE="${OMP_RAW_BASE:-https://raw.githubusercontent.com/${REPO}/${REF}}"
TTY=/dev/tty
EXTENSION_DIR="${PI_AGENT_DIR:-$HOME/.pi/agent}/extensions"
TOOLS_PATH="${EXTENSION_DIR}/tools.ts"

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

installed_packages=()
if list_output=$(pi list 2>/dev/null); then
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*npm:([^[:space:]]+) ]]; then
      spec=${BASH_REMATCH[1]}
      if [[ "$spec" =~ ^(@[^/]+/[^@]+|[^@]+)(@.+)?$ ]]; then
        installed_packages+=("${BASH_REMATCH[1]}")
      fi
    fi
  done <<<"$list_output"
else
  printf 'Warning: could not check installed Pi packages; continuing.\n' >&2
fi

package_is_installed() {
  local package=$1
  local installed_package
  for installed_package in "${installed_packages[@]}"; do
    [[ "$installed_package" == "$package" ]] && return 0
  done
  return 1
}

exec 3<>"$TTY"
installed=()
checked=()
for i in "${!names[@]}"; do
  package=${packages[$i]}
  already_installed=0
  if [[ -n "$package" ]] && package_is_installed "${package#npm:}"; then
    already_installed=1
  elif [[ -z "$package" && -f "$TOOLS_PATH" ]]; then
    already_installed=1
  fi
  installed+=("$already_installed")

  if ((already_installed)) || [[ "${names[$i]}" == "@riverai7z/pi-read" ]]; then
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
    label=${names[$i]}
    ((checked[i])) && marker='x'
    ((installed[i])) && label+=' (installed)'
    if ((i == cursor)); then
      printf '\033[7m> [%s] %s\033[0m\n' "$marker" "$label" >&3
    else
      printf '  [%s] %s\n' "$marker" "$label" >&3
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
      if ((!installed[cursor])); then
        checked[cursor]=$((1 - checked[cursor]))
      fi
      ;;
    a|A)
      next=0
      for i in "${!checked[@]}"; do
        if ((!installed[i] && !checked[i])); then
          next=1
          break
        fi
      done
      for i in "${!checked[@]}"; do
        if ((installed[i])); then
          checked[i]=0
        else
          checked[i]=$next
        fi
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
  printf 'Nothing to install.\n' >&3
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
    mkdir -p "$EXTENSION_DIR"
    curl -fsSL "${RAW_BASE}/extensions/tools.ts" -o "$TOOLS_PATH"
  fi
done

printf '\nDone. Restart pi to load the selected plugins.\n' >&3
