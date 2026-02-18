# Donut — runtime & project helper

Resumo
- `donut` é um utilitário leve para gerenciar versões por‑projeto de Node / Python / Rust.
- Garante que, quando possível, *os gerenciadores globais de pacotes* sejam usados para instalar CLIs e ferramentas (ex.: `pnpm` para Node, `pipx` para Python, `cargo` para Rust).

Principais funcionalidades
- Instalar / garantir versões de runtime: `donut install|init|use` (nvm/fnm, pyenv, rustup). Use `latest` para a versão mais recente (ou stable para Rust).
- Criar arquivos por‑projeto: `.nvmrc`, `.python-version`, `rust-toolchain`
- Ativar ambiente por‑projeto: `donut shell` (ativa as versões listadas em `.donutrc`)
- Gerenciar ferramentas globais por runtime: `donut global add|remove <runtime> <pkg>`
- Ver status: `donut status`

Garantia de pacotes globais (o que foi implementado)
- Node
  - Donut tenta garantir que `pnpm` esteja disponível para a versão Node do projeto (usa `corepack` quando possível, ou `npm i -g pnpm` no ambiente do Node gerenciado).
  - Preferência de instalação de CLIs via `pnpm -g`, com fallback para `npm -g`.
- Python
  - Donut verifica/instala `pipx` (usuário) quando possível e usará `pipx` para instalar CLIs globais.
- Rust
  - Donut verifica se `cargo` está disponível (através de `rustup`) e usará `cargo install`/`cargo uninstall` para ferramentas globais.

Comandos úteis (exemplos)
- Inicializar projeto Node 18 e garantir `pnpm`:
  - `donut init node 18`
- Inicializar projeto Python 3.11 (cria `.venv`) e verifica `pipx`:
  - `donut init python 3.11`
- Iniciar um shell com as versões do projeto:
  - `donut shell`
- Instalar uma ferramenta CLI global com a estratégia apropriada:
  - `donut global add node eslint`  # usa pnpm ou npm
  - `donut global add python ruff` # usa pipx
  - `donut global add rust ripgrep`# usa cargo
- Remover global:
  - `donut global remove node eslint`

Notas operacionais
- O sistema já adiciona `fnm`, `pyenv`, `rustup`, `pnpm` e `pipx` a `environment.systemPackages` — portanto, a maioria das máquinas terá os gerenciadores globais disponíveis.
- `donut` faz tentativas "best-effort" para instalar ferramentas globais quando possível; se uma instalação automática falhar será exibida uma mensagem com instruções manuais.
- Use `donut --dry-run ...` para ver as ações sem executá‑las.

Boas práticas
- Prefira gerenciar dependências do projeto (dev/prod) via `pnpm`/`poetry`/`cargo` e usar `pipx`/`pnpm -g`/`cargo install` apenas para CLIs globais.
- Commite os arquivos por‑projeto para garantir reprodutibilidade: ` .nvmrc`, `.python-version`, `rust-toolchain`.
  **`.donutrc` é local e é ignorado por padrão** — mantenha-o fora do repositório quando desejar configurações de máquina/específicas do desenvolvedor.

### Exemplo `.donutrc`
Formato: `chave=valor` (arquivo local gerido por `donut`). Exemplo mínimo:

```
# .donutrc — project runtimes (local)
node=18
python=3.11
rust=1.72
```

- `donut init <runtime> <version>` escreve o arquivo de runtime correspondente (por exemplo `.nvmrc`) e atualiza `.donutrc` automaticamente.
- `donut shell` lê `.donutrc` para ativar as versões definidas para o projeto.
- Recomenda-se commitar os arquivos por‑projeto (`.nvmrc`, `.python-version`, `rust-toolchain`) e manter `.donutrc` local.

Vicinae (launcher)
- `vicinae` foi adicionado aos `home.packages` e o atalho `Super+Space` abre o launcher no Hyprland.
- A configuração foi migrada para um módulo local `services.vicinae` (gerencia o `systemd --user` unit, autostart e `settings.json`).
- O `vicinae` oficial flake foi adicionado aos `inputs` do `flake.nix`; se preferir usar o flake oficial em vez do wrapper local, adicione/atualize `inputs.vicinae` conforme a documentação upstream.

Example: enable the official flake + Cachix (optional)

1) add the flake input to `flake.nix`:

``nix
inputs.vicinae.url = "github:vicinae/vicinae";
``

2) (optional) add the project's Cachix cache to `nix.binaryCaches` in your `configuration.nix` — refer to the official Vicinae docs for the exact cache name/key.

Notes: the repository ships a small `services.vicinae` wrapper that is enabled by default so the launcher works out‑of‑the‑box; switching to the official flake is supported and documented upstream.


Feedback / extensões possíveis
- Posso adicionar detecção automática de ferramentas comuns (ex.: `eslint`, `prettier`, `ruff`) e instalá‑las ao rodar `donut init`.
- Posso também adicionar testes/CI para as rotinas `global add/remove` se desejar.

---
Documentação gerada automaticamente por `donut` — mantenha este arquivo ao lado do README principal para referência rápida.
