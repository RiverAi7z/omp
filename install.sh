#!/usr/bin/env bash
set -euo pipefail

REPO="${OMP_GITHUB_REPO:-riverai7z/omp}"
REF="${OMP_GITHUB_REF:-master}"
RAW_BASE="${OMP_RAW_BASE:-https://raw.githubusercontent.com/${REPO}/${REF}}"
TTY=/dev/tty
EXTENSION_DIR="${PI_AGENT_DIR:-$HOME/.pi/agent}/extensions"
TOOLS_PATH="${EXTENSION_DIR}/tools.ts"

if [[ ! -r "$TTY" || ! -w "$TTY" ]]; then
  printf 'Error: interactive installation requires a terminal.\n' >&2
  exit 1
fi

refresh_pi_path() {
  local candidate
  local npm_prefix
  local candidates=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/pi-node/current/bin"
    "$HOME/.local/bin"
    "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/bin"
  )

  if command -v npm >/dev/null 2>&1; then
    npm_prefix=$(npm prefix -g 2>/dev/null || npm config get prefix 2>/dev/null || true)
    [[ -n "$npm_prefix" ]] && candidates+=("$npm_prefix/bin")
  fi

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate/pi" && ":$PATH:" != *":$candidate:"* ]]; then
      PATH="$candidate:$PATH"
    fi
  done
  export PATH
  hash -r
}

if ! command -v pi >/dev/null 2>&1; then
  printf 'Pi is not installed. Install Pi now? [y/N] ' >"$TTY"
  reply=''
  IFS= read -r reply <"$TTY" || true
  case "$reply" in
    y|Y|yes|YES|Yes)
      if ! command -v curl >/dev/null 2>&1; then
        printf 'Error: curl is required to install Pi.\n' >&2
        exit 1
      fi
      curl -fsSL https://pi.dev/install.sh | sh
      refresh_pi_path
      ;;
    *)
      printf 'Installation cancelled.\n' >"$TTY"
      exit 0
      ;;
  esac

  if ! command -v pi >/dev/null 2>&1; then
    printf 'Error: Pi was installed but pi is not available in PATH. Restart your shell and try again.\n' >&2
    exit 1
  fi
fi

run_as_root() {
  if ((EUID == 0)); then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    printf 'Error: sudo is required to install system dependencies.\n' >&2
    return 1
  fi
}

install_dependencies() {
  local platform=$1
  shift
  local dependencies=("$@")

  if [[ "$platform" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      printf 'Error: Homebrew is required to install %s.\n' "${dependencies[*]}" >&2
      return 1
    fi
    brew install "${dependencies[@]}"
  elif command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y "${dependencies[@]}"
  elif command -v apk >/dev/null 2>&1; then
    run_as_root apk add --update-cache "${dependencies[@]}"
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y "${dependencies[@]}"
  elif command -v yum >/dev/null 2>&1; then
    run_as_root yum install -y "${dependencies[@]}"
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -S --needed --noconfirm "${dependencies[@]}"
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install "${dependencies[@]}"
  else
    printf 'Error: no supported package manager was found. Install manually: %s\n' "${dependencies[*]}" >&2
    return 1
  fi
}

platform=$(uname -s)
missing_dependencies=()
missing_dependency_messages=()

if [[ "$platform" == "Darwin" || "$platform" == "Linux" ]]; then
  if ! command -v rg >/dev/null 2>&1; then
    missing_dependencies+=("ripgrep")
    missing_dependency_messages+=("ripgrep (rg) not found")
  fi
fi
if [[ "$platform" == "Linux" ]]; then
  if ! command -v bwrap >/dev/null 2>&1; then
    missing_dependencies+=("bubblewrap")
    missing_dependency_messages+=("bubblewrap (bwrap) not installed")
  fi
  if ! command -v socat >/dev/null 2>&1; then
    missing_dependencies+=("socat")
    missing_dependency_messages+=("socat not installed")
  fi
fi

if ((${#missing_dependencies[@]} > 0)); then
  printf 'Missing dependencies:\n' >"$TTY"
  printf '  - %s\n' "${missing_dependency_messages[@]}" >"$TTY"
  printf 'Install them now? [Y/n] ' >"$TTY"
  reply=''
  IFS= read -r reply <"$TTY" || true
  case "$reply" in
    n|N|no|NO|No)
      printf 'Installation cancelled.\n' >"$TTY"
      exit 1
      ;;
    *)
      install_dependencies "$platform" "${missing_dependencies[@]}"
      hash -r
      ;;
  esac
fi

names=(
  "@juicesharp/rpiv-ask-user-question"
  "@narumitw/pi-btw"
  "@narumitw/pi-goal"
  "@narumitw/pi-plan-mode"
  "@riverai7z/pi-read"
  "@riverai7z/pi-todo"
  "pi-sbx"
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
  "npm:pi-sbx"
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

  if ((already_installed)) || [[ "${names[$i]}" == "@riverai7z/pi-read" || "${names[$i]}" == "@riverai7z/pi-todo" || "${names[$i]}" == "pi-simplify" ]]; then
    checked+=(0)
  else
    checked+=(1)
  fi
done

sorted_names=()
sorted_packages=()
sorted_installed=()
sorted_checked=()
for desired_checked in 1 0; do
  for i in "${!names[@]}"; do
    if ((checked[i] == desired_checked)); then
      sorted_names+=("${names[$i]}")
      sorted_packages+=("${packages[$i]}")
      sorted_installed+=("${installed[$i]}")
      sorted_checked+=("${checked[$i]}")
    fi
  done
done
names=("${sorted_names[@]}")
packages=("${sorted_packages[@]}")
installed=("${sorted_installed[@]}")
checked=("${sorted_checked[@]}")

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
