# Estrutura, práticas e decisões — Cupcake (resumo)

Este documento descreve a organização do repositório e as principais decisões de projeto, com foco em clareza, segurança e repetibilidade.

## Visão geral da estrutura
- `configuration.nix` — orquestrador de módulos do sistema.
- `flake.nix` / `flake.lock` — entradas do flake (hosts, home-manager).
- `hardware-configuration.nix` — detecção de hardware gerada pelo instalador.
- `modules/` — módulos NixOS organizados por responsabilidade (boot, users, services, networking, desktop).
  - `modules/desktop` — módulos relacionados à sessão/DM.
  - `modules/*` são importados por `configuration.nix`.
- `hosts/` — ficheiros `nixosConfigurations` por host (desktop, laptop, default fragments).
  - `hosts/default` — fragmentos partilhados gerenciados por `eclair`.
- `home/` — configuração do Home Manager (modular por programas / desktop).
- `overlays/` — sobreposições de pacotes (overlays).
- `scripts/` — scripts utilitários (ex.: `eclair`, `check-duplicates.sh`).
- `docs/` — documentação de projeto (esta pasta).

## Princípios e decisões de design
- Modularidade: separar responsabilidades (system vs user, host-specific vs shared).
- Declaratividade: tudo que altera o sistema deve ser versionado e reproduzível (flakes + Git).
- Segurança: preferir operações seguras por padrão (não sobrescrever arquivos do usuário sem backup / confirmação).
- Minimalismo: pequenas ferramentas shell sem dependências pesadas; use `nix`/`nixos-rebuild` para ações reais.

## Convenções (onde editar)
- System-wide settings: `modules/*` e `configuration.nix`.
- Host-specific overrides: `hosts/<host>.nix`.
- Per-user config and dotfiles: `home/*` — gerenciado pelo Home Manager.
- System packages managed by `eclair`: `hosts/default/user-packages.nix`.
- User packages (home-manager): `home/programs/packages.nix`.
- Feature toggles: `hosts/default/features.nix` (use `eclair`).
- Hints / mappings: `hosts/default/package-hints.nix` (eclair learning).

## Boas práticas
- Use `eclair` para alterações de pacotes e features (ele faz backups e validações).
- Teste mudanças com `sudo nixos-rebuild test --flake /etc/nixos#nixos` antes de `switch`.
- Comite e documente mudanças importantes no `CHANGELOG.md`.
- Mantenha `home/*` para configurações por usuário e `hosts/*` para infra/serviços.

## Política de pacotes (razão para separação)
- System packages: serviços, infra, runtimes que afetam todo o sistema (ex.: Docker, PostgreSQL, Nginx).
- Home packages: aplicativos de usuário, editores, ferramentas CLI para desenvolvimento (ex.: neovim, vscode).
- Evite duplicidade — use `./scripts/check-duplicates.sh` para detectar conflitos. Use `hosts/default/package-hints.nix` para explicitar exceções.

## CI / validações
- `nix flake check` valida a flake e as `nixosConfigurations` configuradas.
- Pre‑commit hook executa `check-duplicates.sh` e `nix flake check`.
- GitHub Actions `.github/workflows/ci.yml` roda as mesmas verificações no push/PR.

## Notas operacionais rápidas
- Rebuild (test): `sudo nixos-rebuild test --flake /etc/nixos#nixos`.
- Rebuild (switch): `sudo nixos-rebuild switch --flake /etc/nixos#nixos`.
- Home‑manager: `home-manager switch` (se necessário localmente) — o flake já injeta `home-manager` nas `nixosConfigurations`.

## Racional por trás de decisões importantes
- Arquivos `hosts/default/*` foram criados para permitir automação via `eclair` e manter uma única fonte de verdade para toggles e pacotes usados em múltiplos hosts.
- Separar `home` vs `system` reduz blast radius e facilita rollback via gerações Nix.

---

(Consulte `docs/02_Eclair.md` para detalhes sobre o gerenciador `eclair`.)