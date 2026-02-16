# Eclair — package & feature manager (documentação)

Resumo: `eclair` é um utilitário leve (shell) que facilita gerenciar *features* e pacotes declarativos no repositório Cupcake. Ele opera sobre arquivos versionados: `hosts/default/features.nix`, `hosts/default/user-packages.nix`, `hosts/default/package-hints.nix` e `home/programs/packages.nix`.

## Objetivos
- Tornar seguro e simples adicionar/remover pacotes e alternar features.
- Aprender escolhas do utilizador (onde instalar: system vs home) e persistir decisão.
- Manter tudo declarativo e verificável por CI.

## Arquivos controlados
- `hosts/default/features.nix` — boolean toggles (ex.: `services.openssh.enable = true;`).
- `hosts/default/user-packages.nix` — lista Nix de `systemPackages` (strings).
- `hosts/default/package-hints.nix` — mapeamentos `"pkg" = "home"|"system"` (persistência de escolha).
- `home/programs/packages.nix` — `home.packages` (user-level).

## Principais comandos
- `eclair list` — mostra features e pacotes (system + home list).
- `eclair enable <feature>` / `eclair disable <feature>` — alterna o booleano em `features.nix`.
- `eclair install <pkg>` — instala **inteligentemente** (usa hints, heurística, prompt); atualiza `hosts/default/*` ou `home/*` conforme decisão.
- `eclair remove <pkg>` — remove de onde estiver (uso de hints/checagens).
- `eclair update` — valida a flake e executa `nixos-rebuild switch --flake .` (usa sudo/pkexec).
- `eclair clean` — `nix-collect-garbage -d` (privilegiado).
- `eclair search <query>` — `nix search nixpkgs <query>`.

Flags úteis
- `--dry-run` — mostra ação sem efetuar alterações.
- `--git` — commit automático do ficheiro alterado.
- `--force` — ignora marcação `MANAGED BY:` e força a alteração.
- `--no-learn` — não persiste escolha em `package-hints.nix`.
- `--no-validate` — pula validação de pacote (útil para overlays / pacotes locais).
- `--validate-strict` — validação estrita (tenta `nix build` do atributo encontrado; pode ser lenta).
- `--assume-home` / `--assume-system` — define destino sem prompt e grava (quando aplicável).
- `--yes` — assume escolha definida por `--assume-*` sem confirmar.

## Fluxo de decisão para `install <pkg>`
1. Consulta `hosts/default/package-hints.nix` — se existir, aplica.
2. Executa heurísticas (listas internas `likely_home` / `likely_system`).
3. Se ambíguo, pergunta interativamente ao utilizador e grava a resposta por padrão (lembrar escolha).
4. Atualiza `home/programs/packages.nix` ou `hosts/default/user-packages.nix` conforme selecionado.

Política padrão: quando em dúvida, preferir `home` (menor privilégio); mas `package-hints.nix` permite explicitar exceções.

## Segurança e robustez
- Backups automáticos: antes de editar um ficheiro, `eclair` cria `*.bak-<timestamp>`.
- Proteção `MANAGED BY:`: `eclair` só altera ficheiros marcados por `MANAGED BY: eclair` (ou `home-manager` para `home/*`) — evita edições acidentais.
- Validação: `eclair` executa `nix flake check` antes de `update`; reverte mudanças em caso de falha.
- Escalonamento: `update/clean` usam sudo (preferido) e fallback para pkexec quando aplicável.

## Integração com CI / Git
- `--git` faz commit automático com mensagem padronizada.
- Pre-commit hook roda `check-duplicates.sh` e `nix flake check`.
- `scripts/check-duplicates.sh` respeita `package-hints.nix` ao detectar duplicatas.

## Exemplos rápidos
- `eclair install neovim` — adiciona a `home/programs/packages.nix` (neovim está no `package-hints`).
- `eclair install docker` — adiciona a `hosts/default/user-packages.nix` (docker está mapeado para `system`).
- `eclair install htop` — sem mapping: prompta, grava escolha por padrão.
- `eclair --dry-run install spotify` — mostra a ação; não altera ficheiros.

## Desenvolvimento / Extensão
- Para ajustar heurísticas ou a lista de pacotes “prováveis”, edite `scripts/eclair.sh` (arrays `likely_home` / `likely_system`).
- Para adicionar verificações extra, atualize `scripts/check-duplicates.sh` e o workflow em `.github/workflows/ci.yml`.

## Perguntas frequentes (curtas)
- Onde o `eclair` grava decisões? → `hosts/default/package-hints.nix` (commitável).
- Posso desativar o “learn by default”? → use `--no-learn`.
- `eclair` sobrescreve meus ficheiros do usuário? → não sem backup e confirmação; `MANAGED BY:` protege arquivos.

---

Guia rápido de uso: `eclair list`, `eclair install <pkg>`, `eclair update` — e tudo fica versionado e validado pelo flake/CI.
