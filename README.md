<div align="center">
  <h1>✦ Cupcake</h1>
  <p><strong>A modern, modular NixOS distribution</strong></p>
  <p>
    <em>Hyprland • Candies • Declarative Config • "Pancake" Desktop</em>
  </p>
  <p>🚧 <strong>STATUS: UNDER CONSTRUCTION / EM CRIAÇÃO</strong> 🚧</p>
</div>

## ✦ Eclair — package & feature manager

`eclair` is a small, repository-local helper script that:

- toggles simple boolean "features" inside `hosts/default/features.nix` (lines like `something.enable = true;`)
- manages a minimal list of system packages in `hosts/default/user-packages.nix`
- optionally runs `nixos-rebuild switch` to apply changes (via `pkexec`)

Usage examples:

- Show features and packages: `eclair list`
- Enable a feature: `eclair enable networkmanager`
- Add a package: `eclair install neovim`
- Apply changes: `eclair update`

Flags:

- `--dry-run` — show the change without modifying files
- `--git` — automatically commit the edited file(s) in the repo

Design goals:

- Minimal and readable (shell-only, no external deps)
- Safe: creates `.bak-<ts>` backups before edits and validates flake
- Integrates with `hosts/default/*` so changes are declarative and reproducible

See `hosts/default/features.nix` and `hosts/default/user-packages.nix` for the files `eclair` edits.

## ✦ Managed-files policy

- `hosts/default/*` — MANAGED BY: `eclair` (system-wide toggles & packages).
- `home/*` — MANAGED BY: `home-manager` (per-user packages & dotfiles).

Do not edit `hosts/default/*` manually unless you know what you are doing — use `eclair` or add `# MANAGED BY: eclair` to the file if you intentionally want to bypass checks.

## ✦ CI / pre-commit checks

- A GitHub Actions workflow (`.github/workflows/ci.yml`) runs `nix flake check` and checks for duplicate packages between `hosts/default/user-packages.nix` and `home/programs/packages.nix`.
- A local `scripts/check-duplicates.sh` script performs the same check and is used by the repository `pre-commit` hook (installed when you initialize the repo).
