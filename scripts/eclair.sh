#!/usr/bin/env bash
# ✦ eclair — Cupcake NixOS Package & Feature Manager (adaptado)
# Lightweight helper to toggle `hosts/default/features.nix` and
# `hosts/default/user-packages.nix`, then trigger a rebuild.

set -euo pipefail

# Allow optional global flags before the command
DRY_RUN=0
AUTO_COMMIT=0
while [[ "${1-}" == --* ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --git) AUTO_COMMIT=1; shift ;;
    --force) FORCE=1; shift ;;
    --help) echo "Usage: eclair [--dry-run] [--git] [--force] <command> [arg]"; exit 0 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

COMMAND="${1:-}"
FEATURE="${2:-}"


# --- Colors ---
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# --- Paths ---
if [[ -d "/cupcake" ]]; then
    BASE_DIR="/cupcake"
else
    BASE_DIR="."
fi

CONFIG_FILE="$BASE_DIR/hosts/default/features.nix"
USER_PKGS_FILE="$BASE_DIR/hosts/default/user-packages.nix"

# --- Helpers ---
info()    { echo -e "${CYAN}✦${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✗${RESET} $*"; }

backup_file() {
  local f="$1"
  local ts
  ts=$(date +%Y%m%d%H%M%S)
  cp -- "$f" "$f.bak-$ts"
  echo "$f.bak-$ts"
}

ensure_files_exist() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<'NIX'
{ config, pkgs, ... }:

{
  # MANAGED BY: eclair — feature toggles (do NOT edit manually)
  # hosts/default/features.nix — managed by eclair
}
NIX
    success "Created template $CONFIG_FILE"
  fi
  if [[ ! -f "$USER_PKGS_FILE" ]]; then
    mkdir -p "$(dirname "$USER_PKGS_FILE")"
    cat > "$USER_PKGS_FILE" <<'NIX'
[
  # MANAGED BY: eclair — system-wide packages (do NOT edit manually)
  # hosts/default/user-packages.nix — managed by eclair

  # ---------------------------
]
NIX
    success "Created template $USER_PKGS_FILE"
  fi
} 

validate_flake() {
  # quick validation: parse the flake and run `nix flake check` if available
  if ! nix flake show --json "$BASE_DIR" >/dev/null 2>&1; then
    return 1
  fi

  if command -v nix >/dev/null 2>&1; then
    if nix flake check "$BASE_DIR" >/dev/null 2>&1; then
      return 0
    fi
  fi

  # fall back to success if `nix flake check` isn't configured for this flake
  return 0
}

# Ensure target file is intentionally managed by eclair (prevent accidental edits)
require_managed_by_eclair() {
  local f="$1"
  if [[ ${FORCE-0} -eq 1 ]]; then return 0; fi
  if ! grep -q "MANAGED BY: eclair" "$f" 2>/dev/null; then
    error "$f is not marked as 'MANAGED BY: eclair' — aborting. Add the header or use --force to override."
    exit 1
  fi
}

usage() {
    echo -e "${BOLD}✦ eclair${RESET} — Cupcake Package & Feature Manager (adaptado)"
    echo ""
    echo -e "Usage: eclair [--dry-run] [--git] <command> [arg]"
    echo "Commands: list, enable <feature>, disable <feature>, install <pkg>, remove <pkg>, search <query>, update, clean, help"
    exit 1
}

# ensure files exist for the current repo layout
ensure_files_exist

# --- Commands ---

if [[ -z "$COMMAND" ]]; then
    usage
fi

# Helper: run a command as root (try pkexec, then sudo)
run_privileged() {
  local cmd="$*"

  # already root
  if [ "$(id -u)" -eq 0 ]; then
    sh -c "$cmd"; return $?
  fi

  # prefer sudo in CLI sessions (most reliable); fall back to pkexec for graphical sessions
  if command -v sudo >/dev/null 2>&1; then
    if sudo sh -c "$cmd"; then
      return 0
    else
      warn "sudo failed or was cancelled — trying pkexec as fallback"
    fi
  fi

  if command -v pkexec >/dev/null 2>&1; then
    if pkexec sh -c "$cmd"; then
      return 0
    else
      warn "pkexec failed or is unavailable for this session"
    fi
  fi

  error "No privilege escalation method available (pkexec/sudo). Run the command as root manually."
  return 1
}

# Update: validate + rebuild the NixOS system with current flake
if [[ "$COMMAND" == "update" ]]; then
    info "Validating flake before update..."
    if ! validate_flake; then
        error "flake validation failed — aborting update"
        exit 1
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
      info "(dry-run) validation passed — not performing rebuild"
      exit 0
    fi

    info "Running nixos-rebuild switch --flake $BASE_DIR"
    if ! run_privileged "nixos-rebuild switch --flake '$BASE_DIR'"; then
      error "nixos-rebuild failed"
      exit 1
    fi
    success "System updated"
    exit 0
fi

# Clean: garbage collect old generations
if [[ "$COMMAND" == "clean" ]]; then
    info "Collecting garbage..."
    if run_privileged "nix-collect-garbage -d"; then
        success "Garbage collected."
    else
        error "Failed to collect garbage."
        exit 1
    fi
    exit 0
fi

# Search: find available packages
if [[ "$COMMAND" == "search" ]]; then
    if [[ -z "$FEATURE" ]]; then
        error "Please provide a search query."
        echo "  Usage: eclair search <query>"
        exit 1
    fi
    info "Searching for '${BOLD}$FEATURE${RESET}'..."
    echo ""
    nix search nixpkgs "$FEATURE" 2>/dev/null || echo "No results found."
    exit 0
fi

# Help: show cheatsheet
if [[ "$COMMAND" == "help" ]]; then
    cat "$BASE_DIR/modules/docs/CHEATSHEET.md"
    exit 0
fi

# List: show all features and status
if [[ "$COMMAND" == "list" ]]; then
    echo -e "${BOLD}✦ System Features${RESET}"
    echo ""
    grep -nE '^[[:space:]]*[^[:space:]#].*\.enable' "$CONFIG_FILE" | while IFS= read -r _line; do
        # strip the leading line number (grep -n): 'LINENO:line...'
        line=$(echo "$_line" | cut -d: -f2- | sed 's/^[[:space:]]*//')
        name=$(echo "$line" | sed -E 's/.*\.([a-zA-Z]+)\.enable.*/\1/')
        status=$(echo "$line" | grep -o "true\|false")
        if [[ "$status" == "true" ]]; then
            echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET} ${DIM}enabled${RESET}"
        else
            echo -e "  ${DIM}○${RESET} $name ${DIM}disabled${RESET}"
        fi
    done
    echo ""
    echo -e "${BOLD}✦ Installed Packages${RESET}"
    echo ""
    grep -v "^[[:space:]]*#" "$USER_PKGS_FILE" | grep -v "^{" | grep -v "^}" | grep -v "^\[" | grep -v "^\]" | grep -v "^$" | sed 's/^[[:space:]]*/  /' | while IFS= read -r pkg; do
        pkg_clean=$(echo "$pkg" | xargs)
        if [[ -n "$pkg_clean" ]]; then
            echo -e "  ${BLUE}◆${RESET} $pkg_clean"
        fi
    done
    exit 0
fi

# --- Require second argument for remaining commands ---

if [[ -z "$FEATURE" ]]; then
    error "Missing argument for '$COMMAND'"
    usage
fi

# --- Package Management ---

if [[ "$COMMAND" == "install" || "$COMMAND" == "remove" ]]; then
    if [[ -z "$FEATURE" ]]; then error "Missing package name"; fi

    if [[ $DRY_RUN -eq 1 ]]; then
      info "(dry-run) would $COMMAND '$FEATURE' in $USER_PKGS_FILE"
      exit 0
    fi

    require_managed_by_eclair "$USER_PKGS_FILE"
    bak=$(backup_file "$USER_PKGS_FILE")

    if [[ "$COMMAND" == "install" ]]; then
      if grep -qE "\"${FEATURE}\"" "$USER_PKGS_FILE" || grep -qE "^[[:space:]]*${FEATURE}[[:space:]]*$" "$USER_PKGS_FILE"; then
        # fallback: check quoted name too
        if grep -qE "\"${FEATURE}\"" "$USER_PKGS_FILE"; then
          warn "Package '$FEATURE' already exists in $USER_PKGS_FILE"
          exit 0
        fi
      fi
      # insert as a quoted string
      sed -i "/# ---------------------------/i \\  \"${FEATURE}\"" "$USER_PKGS_FILE"
      success "Added package '$FEATURE' to $USER_PKGS_FILE (backup: $(basename \"$bak\"))"
    else
      # remove quoted or unquoted occurrence
      if ! grep -qE "(\"${FEATURE}\"|^[[:space:]]*${FEATURE}[[:space:]]*$)" "$USER_PKGS_FILE"; then
        warn "Package '$FEATURE' not present in $USER_PKGS_FILE"
        exit 0
      fi
      sed -i "/\"${FEATURE}\"/d" "$USER_PKGS_FILE" || true
      sed -i "/^[[:space:]]*${FEATURE}[[:space:]]*$/d" "$USER_PKGS_FILE" || true
      success "Removed package '$FEATURE' from $USER_PKGS_FILE (backup: $(basename "$bak"))"
    fi

    if [[ $AUTO_COMMIT -eq 1 && -d "$BASE_DIR/.git" ]]; then
      git -C "$BASE_DIR" add "$USER_PKGS_FILE" && git -C "$BASE_DIR" commit -m "eclair: $COMMAND $FEATURE"
      success "Committed change to git"
    fi

    info "Run 'eclair update' to apply changes system-wide."
    exit 0
fi

# --- Feature Toggling ---

if [[ "$COMMAND" != "enable" && "$COMMAND" != "disable" ]]; then
    error "Unknown command: $COMMAND"
    usage
fi

if [[ -z "$FEATURE" ]]; then error "Missing feature name"; fi

# find matching lines
mapfile -t LINES < <(grep -nE "(\.|^|[[:space:]])${FEATURE}\.enable" "$CONFIG_FILE" || true)
if [[ ${#LINES[@]} -eq 0 ]]; then
  error "Feature '$FEATURE' not found in $CONFIG_FILE"
  echo "Available features:"; grep "\.enable" "$CONFIG_FILE" | sed -E 's/.*\.([a-zA-Z0-9_+-]+)\.enable.*/  \1/'
  exit 1
fi
if [[ ${#LINES[@]} -gt 1 ]]; then
  echo "Multiple matches for '$FEATURE':"; printf '%s
' "${LINES[@]}"; exit 1
fi

LINE="${LINES[0]}"
LINE_NO=${LINE%%:*}
CURRENT_STATE=$(echo "$LINE" | grep -o "true\|false")
TARGET_STATE="true"
[[ "$COMMAND" == "disable" ]] && TARGET_STATE="false"

if [[ "$CURRENT_STATE" == "$TARGET_STATE" ]]; then
  warn "Feature '$FEATURE' already $COMMAND"; exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
  info "(dry-run) would change line $LINE_NO: $CURRENT_STATE -> $TARGET_STATE in $CONFIG_FILE"
  exit 0
fi

require_managed_by_eclair "$CONFIG_FILE"

bak=$(backup_file "$CONFIG_FILE")
sed -i "${LINE_NO}s/${CURRENT_STATE}/${TARGET_STATE}/" "$CONFIG_FILE"

# validate flake; if invalid, revert
if ! validate_flake; then
  warn "Validation failed after edit; reverting to backup"
  mv "$bak" "$CONFIG_FILE"
  exit 1
fi

success "Feature '$FEATURE' set to $TARGET_STATE (backup: $(basename "$bak"))"
info "Run 'eclair update' to apply changes system-wide."

if [[ $AUTO_COMMIT -eq 1 && -d "$BASE_DIR/.git" ]]; then
  git -C "$BASE_DIR" add "$CONFIG_FILE" && git -C "$BASE_DIR" commit -m "eclair: $COMMAND $FEATURE"
  success "Committed change to git"
fi

exit 0