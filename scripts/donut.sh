#!/usr/bin/env bash
# ✦ donut — lightweight language/runtime manager wrapper
# Supports: node (nvm), python (pyenv), rust (rustup)
# UI inspired by `eclair` (colors/icons). Minimal, safe, project-focused.

set -euo pipefail

# Accept optional leading flags: --dry-run and --yes
DRY_RUN=0
AUTO_YES=0
while [[ "${1:-}" == "--dry-run" || "${1:-}" == "--yes" ]]; do
  [[ "${1}" == "--dry-run" ]] && DRY_RUN=1
  [[ "${1}" == "--yes" ]] && AUTO_YES=1
  shift
done

COMMAND="${1:-}"
RUNTIME="${2:-}"
VERSION="${3:-}"

# --- Colors / helpers ---
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

info()    { echo -e "${CYAN}✦${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✗${RESET} $*"; }

# --- Project files ---
PROJECT_ROOT="$(pwd)"
DONUT_FILE="$PROJECT_ROOT/.donutrc"

backup_file() {
  local f="$1" ts
  ts=$(date +%Y%m%d%H%M%S)
  cp -- "$f" "$f.bak-$ts" 2>/dev/null || true
  echo "$f.bak-$ts"
}

ensure_donut_file() {
  if [[ ! -f "$DONUT_FILE" ]]; then
    cat > "$DONUT_FILE" <<'EOF'
# .donutrc — managed by donut (key=value)
# Example: node=18 python=3.11 rust=1.72
EOF
    success "Created $DONUT_FILE"
  fi
}

read_donut() {
  [[ -f "$DONUT_FILE" ]] || return 0
  grep -E "^[a-zA-Z0-9_+-]+=" "$DONUT_FILE" || true
}

get_donut_value() {
  local k="$1"
  if [[ -f "$DONUT_FILE" ]]; then
    awk -F= -v key="$k" '$1==key{print $2}' "$DONUT_FILE" || true
  fi
}

set_donut_value() {
  local k="$1" v="$2"
  ensure_donut_file
  if grep -qE "^${k}=" "$DONUT_FILE"; then
    backup_file "$DONUT_FILE"
    sed -i "s/^${k}=.*/${k}=${v}/" "$DONUT_FILE"
  else
    backup_file "$DONUT_FILE"
    echo "${k}=${v}" >> "$DONUT_FILE"
  fi
  success "Set $k=$v in .donutrc"
}

# --- Version manager checks ---
require_manager() {
  local m="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  warn "$m não encontrado no sistema. Instale-o (ex.: eclair install ${m})."
  return 1
}

# For Node we support either `nvm` (preferred) or `fnm` (fallback).
detect_node_manager() {
  if command -v nvm >/dev/null 2>&1; then
    echo "nvm"
  elif command -v fnm >/dev/null 2>&1; then
    echo "fnm"
  else
    return 1
  fi
}

# --- Global package-manager helpers (pnpm / pipx / cargo) ---
ensure_pnpm_installed_for_node() {
  local nodev="$1" mgr
  mgr=$(detect_node_manager) || { warn "nenhum gerenciador de Node disponível (nvm/fnm)"; return 1; }
  if command -v pnpm >/dev/null 2>&1; then
    info "pnpm já disponível"
    return 0
  fi

  info "Garantindo pnpm para node ${nodev} (usando ${mgr})"
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) instalar pnpm"; return 0; fi

  if command -v corepack >/dev/null 2>&1; then
    # activate pnpm via corepack in the requested node environment
    if [[ "$mgr" == "nvm" ]]; then
      bash -lic "nvm use ${nodev} >/dev/null 2>&1 || true; corepack enable >/dev/null 2>&1 || true; corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true"
    else
      bash -lic "fnm use ${nodev} >/dev/null 2>&1 || true; corepack enable >/dev/null 2>&1 || true; corepack prepare pnpm@latest --activate >/dev/null 2>&1 || true"
    fi
  else
    # fallback to global npm install for the active node
    if [[ "$mgr" == "nvm" ]]; then
      bash -lic "nvm use ${nodev} >/dev/null 2>&1 || true; npm i -g pnpm" || true
    else
      bash -lic "fnm use ${nodev} >/dev/null 2>&1 || true; npm i -g pnpm" || true
    fi
  fi

  if command -v pnpm >/dev/null 2>&1; then
    success "pnpm pronto"
  else
    warn "não foi possível instalar pnpm automaticamente — instale pnpm no sistema ou no seu node"
  fi
}

ensure_pipx_available() {
  if command -v pipx >/dev/null 2>&1; then
    info "pipx já disponível"
    return 0
  fi
  warn "pipx não encontrado — tentando instalação por usuário (fallback)"
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) python -m pip install --user pipx"; return 0; fi
  if command -v python >/dev/null 2>&1; then
    python -m pip install --user pipx || true
    python -m pipx ensurepath || true
  elif command -v pyenv >/dev/null 2>&1; then
    local pybin
    pybin=$(pyenv which python 2>/dev/null || true)
    [[ -n "$pybin" ]] && "$pybin" -m pip install --user pipx || true
  fi
  if command -v pipx >/dev/null 2>&1; then
    success "pipx instalado"
  else
    warn "pipx não pôde ser instalado automaticamente; adicione 'pipx' em systemPackages ou instale manualmente"
  fi
}

ensure_cargo_available() {
  if command -v cargo >/dev/null 2>&1; then
    info "cargo disponível"
    return 0
  fi
  warn "cargo não encontrado; certifique-se de ter instalado via rustup"
}


# --- Install / init / use implementations ---
install_node() {
  local v="$1"
  local mgr
  mgr=$(detect_node_manager) || { warn "nem nvm nem fnm disponíveis"; return 1; }
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) ${mgr} install ${v}"; return 0; fi
  if [[ "$mgr" == "nvm" ]]; then
    nvm install "${v}" || return 1
  else
    fnm install "${v}" || return 1
  fi
  success "Node ${v} instalado via ${mgr}"
}

init_node() {
  local v="$1"
  install_node "$v" || return 1
  echo "$v" > .nvmrc
  set_donut_value node "$v"
  # ensure pnpm (global package manager) is available for this node version
  ensure_pnpm_installed_for_node "$v" || true
  success "Projeto inicializado para node ${v} (wrote .nvmrc + .donutrc)"
}

use_node() {
  local v="$1"
  local mgr
  mgr=$(detect_node_manager) || { warn "nem nvm nem fnm disponíveis"; return 1; }
  if [[ -f .nvmrc ]]; then echo "Using .nvmrc -> $(cat .nvmrc)"; fi
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) ${mgr} use ${v}"; return 0; fi
  if [[ "$mgr" == "nvm" ]]; then
    bash -lic "nvm use ${v} && exec \$SHELL"
  else
    bash -lic "fnm use ${v} && exec \$SHELL"
  fi
}

install_python() {
  local v="$1"
  require_manager pyenv pyenv || return 1
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) pyenv install ${v}"; return 0; fi
  pyenv install -s "$v" || true
  success "Python ${v} (pyenv) ensured"
}

init_python() {
  local v="$1"
  install_python "$v" || return 1
  echo "$v" > .python-version
  set_donut_value python "$v"
  # create venv if python available
  if command -v pyenv >/dev/null 2>&1; then
    local pybin
    pybin=$(pyenv which python 2>/dev/null || true)
    if [[ -n "$pybin" ]]; then
      "$pybin" -m venv .venv || true
      success ".venv created (python ${v})"
    fi
  fi
  # ensure pipx (global CLI manager for Python) is available
  ensure_pipx_available || true
  success "Projeto inicializado para python ${v}"
}

use_python() {
  local v="$1"
  require_manager pyenv pyenv || return 1
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) pyenv shell ${v}"; return 0; fi
  pyenv shell "$v"
  echo "Python shell set to ${v}"
  bash -lic "pyenv shell ${v} && exec \$SHELL"
}

install_rust() {
  local v="$1"
  require_manager rustup rustup || return 1
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) rustup toolchain install ${v}"; return 0; fi
  rustup toolchain install "$v"
  success "Rust ${v} installed via rustup"
}

init_rust() {
  local v="$1"
  install_rust "$v" || return 1
  echo "$v" > rust-toolchain
  set_donut_value rust "$v"
  # ensure cargo available (rustup should provide it)
  ensure_cargo_available || true
  success "Projeto inicializado para rust ${v}"
}

use_rust() {
  local v="$1"
  require_manager rustup rustup || return 1
  if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) rustup default ${v}"; return 0; fi
  rustup default "$v"
  success "rust default set to ${v}"
  bash -lic "rustup default ${v} && exec \$SHELL"
}

list_installed() {
  case "$1" in
    node)
      if command -v nvm >/dev/null 2>&1; then nvm ls || true; elif command -v fnm >/dev/null 2>&1; then fnm list || true; else warn "nenhum gerenciador de node encontrado"; fi ;;
    python) pyenv versions || true ;;
    rust) rustup toolchain list || true ;;
    *) echo "Supported: node, python, rust" ;;
  esac
}

status() {
  echo -e "${BOLD}Project .donutrc:${RESET}"; read_donut || true
  echo
  echo -e "${BOLD}Detected files:${RESET}"
  [[ -f .nvmrc ]] && echo "  .nvmrc -> $(cat .nvmrc)"
  [[ -f .python-version ]] && echo "  .python-version -> $(cat .python-version)"
  [[ -f rust-toolchain ]] && echo "  rust-toolchain -> $(cat rust-toolchain)"
}

uninstall_runtime() {
  local r="$1" v="$2"
  case "$r" in
    node)
      local mgr
      mgr=$(detect_node_manager) || { warn "nem nvm nem fnm disponíveis"; return 1; }
      if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) ${mgr} uninstall ${v}"; return 0; fi
      if [[ "$mgr" == "nvm" ]]; then
        nvm uninstall "$v" || true
      else
        fnm uninstall "$v" || true
      fi
      success "node ${v} removed (if existed)" ;;
    python)
      require_manager pyenv pyenv || return 1
      if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) pyenv uninstall -f ${v}"; return 0; fi
      pyenv uninstall -f "$v" || true
      success "python ${v} removed (if existed)" ;;
    rust)
      require_manager rustup rustup || return 1
      if [[ "$DRY_RUN" -eq 1 ]]; then info "(dry-run) rustup toolchain remove ${v}"; return 0; fi
      rustup toolchain remove "$v" || true
      success "rust ${v} removed (if existed)" ;;
    *) error "unknown runtime: $r"; return 1 ;;
  esac
}

# --- CLI ---
if [[ -z "$COMMAND" || "$COMMAND" == "help" ]]; then
  cat <<EOF
${CYAN}✦ donut${RESET} — runtime manager helper

Usage: donut <command> [runtime] [version]

Commands:
  install <runtime> <version>   install runtime version (nvm/pyenv/rustup)
  init    <runtime> <version>   create project files + install
  use     <runtime> <version>   set version for current shell / project
  shell                         open subshell with project versions active
  list <runtime>                list installed versions for runtime
  status                        show project donut status
  uninstall <runtime> <version> remove installed version
  global <add|remove> <runtime> <pkg>  install/remove global CLI via pnpm/pipx/cargo
  help                          show this help

Supported runtimes: node, python, rust

Flags: --dry-run, --yes
EOF
  exit 0
fi


case "$COMMAND" in
  install)
    if [[ -z "$RUNTIME" || -z "$VERSION" ]]; then echo "Usage: donut install <runtime> <version"; exit 1; fi
    case "$RUNTIME" in
      node) install_node "$VERSION";;
      python) install_python "$VERSION";;
      rust) install_rust "$VERSION";;
      *) error "runtime não suportado"; exit 1;;
    esac
    ;;

  init)
    if [[ -z "$RUNTIME" || -z "$VERSION" ]]; then echo "Usage: donut init <runtime> <version"; exit 1; fi
    case "$RUNTIME" in
      node) init_node "$VERSION";;
      python) init_python "$VERSION";;
      rust) init_rust "$VERSION";;
      *) error "runtime não suportado"; exit 1;;
    esac
    ;;

  use)
    if [[ -z "$RUNTIME" || -z "$VERSION" ]]; then echo "Usage: donut use <runtime> <version"; exit 1; fi
    case "$RUNTIME" in
      node) use_node "$VERSION";;
      python) use_python "$VERSION";;
      rust) use_rust "$VERSION";;
      *) error "runtime não suportado"; exit 1;;
    esac
    ;;

  shell)
    # read .donutrc and try to activate versions, then spawn a shell
    ensure_donut_file
    # if node present, nvm use
    nd=$(get_donut_value node) || true
    pd=$(get_donut_value python) || true
    rd=$(get_donut_value rust) || true
    info "Starting shell with project runtimes: node=${nd:-n/a} python=${pd:-n/a} rust=${rd:-n/a}"
    bash -lic "$( [[ -n "$nd" ]] && echo "nvm use $nd >/dev/null 2>&1 || true;" ) $( [[ -n "$pd" ]] && echo "pyenv shell $pd >/dev/null 2>&1 || true;" ) $( [[ -n "$rd" ]] && echo "rustup default $rd >/dev/null 2>&1 || true;" ) exec \$SHELL"
    ;;

  list)
    list_installed "$RUNTIME" ;;

  status)
    status ;;

  global)
    # donut global <add|remove> <runtime> <pkg>
    op="${2:-}"
    rt="${3:-}"
    pkg="${4:-}"
    if [[ -z "$op" || -z "$rt" || -z "$pkg" ]]; then
      echo "Usage: donut global <add|remove> <runtime> <pkg>"; exit 1
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      info "(dry-run) global ${op} ${rt} ${pkg}"
    fi

    case "$rt" in
      node)
        # prefer pnpm, fallback to npm (respect DRY_RUN)
        if [[ "$op" == "add" ]]; then
          if command -v pnpm >/dev/null 2>&1; then
            [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) pnpm add -g ${pkg}" || pnpm add -g "$pkg"
          else
            # try to use node manager -> npm in that environment
            if [[ "$DRY_RUN" -eq 1 ]]; then
              info "(dry-run) npm i -g ${pkg} (in node env)"
            else
              if detect_node_manager >/dev/null 2>&1; then
                bash -lic "npm i -g ${pkg}" || warn "npm global install falhou"
              else
                warn "nenhum gerenciador de node/ npm disponível"
              fi
            fi
          fi
        else
          if command -v pnpm >/dev/null 2>&1; then
            [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) pnpm remove -g ${pkg}" || pnpm remove -g "$pkg"
          else
            [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) npm uninstall -g ${pkg}" || npm uninstall -g "$pkg" || warn "npm uninstall falhou"
          fi
        fi
        ;;
      python)
        if [[ "$op" == "add" ]]; then
          if command -v pipx >/dev/null 2>&1; then
            [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) pipx install ${pkg}" || pipx install "$pkg"
          else
            [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) python -m pipx install ${pkg}" || (python -m pipx install "$pkg" || warn "pipx não disponível")
          fi
        else
          if command -v pipx >/dev/null 2>&1; then
            [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) pipx uninstall ${pkg}" || pipx uninstall "$pkg" || true
          else
            warn "pipx não disponível"
          fi
        fi
        ;;
      rust)
        if [[ "$op" == "add" ]]; then
          [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) cargo install ${pkg}" || cargo install "$pkg"
        else
          [[ "$DRY_RUN" -eq 1 ]] && info "(dry-run) cargo uninstall ${pkg}" || cargo uninstall "$pkg" || true
        fi
        ;;
      *) error "runtime não suportado para global: $rt"; exit 1;;
    esac
    ;;

  uninstall)
    if [[ -z "$RUNTIME" || -z "$VERSION" ]]; then echo "Usage: donut uninstall <runtime> <version"; exit 1; fi
    uninstall_runtime "$RUNTIME" "$VERSION";;

  *)
    error "unknown command: $COMMAND"; exit 1;;
esac
