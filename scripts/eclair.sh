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
    --no-learn) NO_LEARN=1; shift ;;
    --assume-home) ASSUME=home; ASSUME_YES=1; shift ;;
    --assume-system) ASSUME=system; ASSUME_YES=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --help) echo "Usage: eclair [--dry-run] [--git] [--force] [--no-learn] [--assume-home|--assume-system] <command> [arg]"; exit 0 ;;
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

  # package-hints file (optional mapping for package placement)
  HINTS_FILE="$BASE_DIR/hosts/default/package-hints.nix"
  if [[ ! -f "$HINTS_FILE" ]]; then
    mkdir -p "$(dirname "$HINTS_FILE")"
    cat > "$HINTS_FILE" <<'NIX'
{ }:

{
  mappings = {
    # "pkg-name" = "home" | "system";
  };
}
NIX
    success "Created template $HINTS_FILE"
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
  if ! grep -qE "MANAGED BY: (eclair|home-manager)" "$f" 2>/dev/null; then
    error "$f is not marked as 'MANAGED BY: eclair' or 'MANAGED BY: home-manager' — aborting. Add the header or use --force to override."
    exit 1
  fi
}

# ---------------------------
# Package-hints helpers
# - persistent mapping in hosts/default/package-hints.nix
# - lightweight heuristics and interactive prompt (learn by default)
# ---------------------------
HINTS_LOADED=0
declare -A HINTMAP

load_hints() {
  if [[ $HINTS_LOADED -eq 1 ]]; then return; fi
  HINTS_LOADED=1
  HINTMAP=()
  local f="$BASE_DIR/hosts/default/package-hints.nix"
  if [[ ! -f "$f" ]]; then return; fi
  while IFS= read -r l; do
    if [[ $l =~ \"([^\"]+)\"[[:space:]]*=[[:space:]]*\"(home|system)\" ]]; then
      name="${BASH_REMATCH[1]}"
      side="${BASH_REMATCH[2]}"
      HINTMAP["$name"]="$side"
    fi
  done < <(grep -nE '\"[^\"]+\"\s*=\s*\"(home|system)\"' "$f" 2>/dev/null || true)
}

get_hint() {
  local pkg="$1"
  load_hints
  echo "${HINTMAP[$pkg]-}"
}

save_hint() {
  local pkg="$1" side="$2" f="$BASE_DIR/hosts/default/package-hints.nix"
  # already present?
  if grep -qE "\"$pkg\"\s*=\s*\"(home|system)\"" "$f" 2>/dev/null; then return 0; fi

  # insert just before the end of the mappings block
  awk -v pkg="$pkg" -v side="$side" '
    { print }
    /^\s*mappings = \{/ { inmap=1; next }
    inmap && /^\s*\};/ { printf("    \"%s\" = \"%s\";\n", pkg, side); inmap=0 }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  # update runtime cache
  HINTMAP["$pkg"]="$side"
  success "Saved mapping: $pkg -> $side"
}

# heuristics: quick lists
likely_system=(docker docker-compose podman containerd nginx postgresql postgres mysql mariadb redis rabbitmq qemu virtualbox libvirt wireguard openvpn)
likely_home=(neovim vim tmux kitty alacritty alacritty-terminfo ripgrep rg fd bat git vscode code microsoft-edge discord firefox slack spotify)

decide_target() {
  local pkg="$1"
  # hints first
  local hint=$(get_hint "$pkg")
  if [[ -n "$hint" ]]; then echo "$hint"; return; fi

  # explicit CLI overrides
  if [[ ${ASSUME_YES-0} -eq 1 ]]; then
    if [[ -n "$ASSUME" ]]; then
      if [[ ${NO_LEARN-0} -ne 1 ]]; then save_hint "$pkg" "$ASSUME"; fi
      echo "$ASSUME"; return; fi
  fi

  for x in "${likely_system[@]}"; do [[ "$pkg" == "$x" ]] && { echo system; return; }; done
  for x in "${likely_home[@]}"; do [[ "$pkg" == "$x" ]] && { echo home; return; }; done

  # default suggestion
  local default=home

  if [[ -t 0 && -t 1 ]]; then
    # interactive prompt — default: home — remember by default
    echo "Where should '$pkg' be installed?"
    select choice in "home (per-user)" "system (global)" "cancel"; do
      case $REPLY in
        1) target=home; break;;
        2) target=system; break;;
        *) echo "Canceled."; return 1;;
      esac
    done

    # remember by default
    if [[ ${NO_LEARN-0} -ne 1 ]]; then
      save_hint "$pkg" "$target"
    fi
    echo "$target"; return
  fi

  # non-interactive: choose default (home) and remember (learn by default)
  if [[ ${NO_LEARN-0} -ne 1 ]]; then
    save_hint "$pkg" "$default"
  fi
  echo "$default"
}

# ---------------------------

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
      info "(dry-run) would $COMMAND '$FEATURE'"
      exit 0
    fi

    # determine files
    USER_PKGS_FILE="$BASE_DIR/hosts/default/user-packages.nix"
    HOME_PKGS_FILE="$BASE_DIR/home/programs/packages.nix"

    # helper: add to home.packages (inserts above placeholder comment)
    add_to_home() {
      local pkg="$1" f="$HOME_PKGS_FILE"
      require_managed_by_eclair "$f"
      bak=$(backup_file "$f")
      if grep -qE "^[[:space:]]*${pkg}[[:space:]]*$" "$f"; then
        warn "Package '$pkg' already present in $f"
        return 0
      fi
      sed -i "/# add your user packages here/i \    ${pkg}" "$f"
      success "Added package '$pkg' to $f (backup: $(basename \"$bak\"))"
    }

    remove_from_home() {
      local pkg="$1" f="$HOME_PKGS_FILE"
      require_managed_by_eclair "$f"
      bak=$(backup_file "$f")
      sed -i "/^[[:space:]]*${pkg}[[:space:]]*$/d" "$f" || true
      success "Removed package '$pkg' from $f (backup: $(basename \"$bak\"))"
    }

    # helper: add/remove system package (hosts/default/user-packages.nix)
    add_to_system() {
      local pkg="$1" f="$USER_PKGS_FILE"
      require_managed_by_eclair "$f"
      bak=$(backup_file "$f")
      if grep -qE "\"${pkg}\"" "$f" || grep -qE "^[[:space:]]*${pkg}[[:space:]]*$" "$f"; then
        warn "Package '${pkg}' already exists in $f"
        return 0
      fi
      sed -i "/# ---------------------------/i \  \"${pkg}\"" "$f"
      success "Added package '${pkg}' to $f (backup: $(basename \"$bak\"))"
    }

    remove_from_system() {
      local pkg="$1" f="$USER_PKGS_FILE"
      require_managed_by_eclair "$f"
      bak=$(backup_file "$f")
      sed -i "/\"${pkg}\"/d" "$f" || true
      sed -i "/^[[:space:]]*${pkg}[[:space:]]*$/d" "$f" || true
      success "Removed package '${pkg}' from $f (backup: $(basename \"$bak\"))"
    }

    if [[ "$COMMAND" == "install" ]]; then
      # decide target (home/system) using hints/heuristics/prompt
      target=$(decide_target "$FEATURE") || exit 1

      if [[ "$target" == "system" ]]; then
        add_to_system "$FEATURE"
      else
        add_to_home "$FEATURE"
      fi

      if [[ $AUTO_COMMIT -eq 1 && -d "$BASE_DIR/.git" ]]; then
        if [[ "$target" == "system" ]]; then
          git -C "$BASE_DIR" add "$USER_PKGS_FILE" && git -C "$BASE_DIR" commit -m "eclair: install $FEATURE (system)" || true
        else
          git -C "$BASE_DIR" add "$HOME_PKGS_FILE" && git -C "$BASE_DIR" commit -m "eclair: install $FEATURE (home)" || true
        fi
        success "Committed change to git"
      fi

      info "Run 'eclair update' (system) or 'home-manager switch' (user) to apply changes."
      exit 0
    fi

    # --- remove ---
    if [[ "$COMMAND" == "remove" ]]; then
      # check hints first (allow override via --assume-home/--assume-system)
      hint=$(get_hint "$FEATURE")
      if [[ ${ASSUME_YES-0} -eq 1 && -n "$ASSUME" ]]; then hint="$ASSUME"; fi
      if [[ -n "$hint" ]]; then
        if [[ "$hint" == "system" ]]; then
          remove_from_system "$FEATURE"
        else
          remove_from_home "$FEATURE"
        fi
        exit 0
      fi

      # not hinted: check both files
      in_system=0; in_home=0
      if grep -qE "\"${FEATURE}\"" "$USER_PKGS_FILE" || grep -qE "^[[:space:]]*${FEATURE}[[:space:]]*$" "$USER_PKGS_FILE"; then in_system=1; fi
      if grep -qE "^[[:space:]]*${FEATURE}[[:space:]]*$" "$HOME_PKGS_FILE"; then in_home=1; fi

      if [[ $in_system -eq 1 && $in_home -eq 1 ]]; then
        echo "Package found in both system and home. Where remove?"
        select choice in "system" "home" "both" "cancel"; do
          case $REPLY in
            1) remove_from_system "$FEATURE"; break;;
            2) remove_from_home "$FEATURE"; break;;
            3) remove_from_system "$FEATURE"; remove_from_home "$FEATURE"; break;;
            *) echo "Canceled"; exit 1;;
          esac
        done
      elif [[ $in_system -eq 1 ]]; then
        remove_from_system "$FEATURE"
      elif [[ $in_home -eq 1 ]]; then
        remove_from_home "$FEATURE"
      else
        warn "Package '$FEATURE' not found in either system or home package lists."
      fi

      if [[ $AUTO_COMMIT -eq 1 && -d "$BASE_DIR/.git" ]]; then
        git -C "$BASE_DIR" add "$USER_PKGS_FILE" "$HOME_PKGS_FILE" && git -C "$BASE_DIR" commit -m "eclair: remove $FEATURE" || true
        success "Committed change to git"
      fi

      info "Run 'eclair update' or 'home-manager switch' to apply changes." 
      exit 0
    fi
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