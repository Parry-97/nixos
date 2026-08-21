# NixOS Flake Configuration

My personal, declarative NixOS system configuration managed as a Nix flake.
It pairs a system-level NixOS setup with a [Home Manager][hm] standalone user
profile, keeping both the OS and my dotfiles reproducible and version-controlled.

[hm]: https://github.com/nix-community/home-manager

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Features](#features)
  - [System](#system)
  - [Hardware / GPU](#hardware--gpu)
  - [Desktop Environment](#desktop-environment)
  - [User Environment (Home Manager)](#user-environment-home-manager)
  - [Autonomous Agent Sandboxes (docker-sbx)](#autonomous-agent-sandboxes-docker-sbx)
  - [Development Tooling](#development-tooling)
- [Flake Inputs & Outputs](#flake-inputs--outputs)
- [Usage](#usage)
  - [First-time / fresh install](#first-time--fresh-install)
  - [Applying changes](#applying-changes)
  - [Updating inputs](#updating-inputs)
- [Key Commands](#key-commands)
- [Notes](#notes)
- [License](#license)

---

## Overview

This flake builds two things from the unstable `nixpkgs` channel:

1. **`nixosConfigurations.nixos`** — the full system closure (kernel, drivers,
   services, system packages).
2. **`homeConfigurations.pops`** — a Home Manager configuration applied in
   *standalone* mode for the `pops` user (shell, editor, dotfiles).

Home Manager is intentionally **not** wired in as a NixOS module; the user
environment is built and activated separately. This keeps the system and home
layers independently rebuildable and matches the workflow used in
[`b082800`][standalone-commit] (`use home manager in standalone mode`).

The flake outputs are assembled with [flake-parts][fp] and auto-imported
from `modules/` via [import-tree][it], instead of the single flat
`configuration.nix`/`hardware-configuration.nix` pair it started with.

[standalone-commit]: https://github.com/Parry-97/nixos/commit/b082800
[fp]: https://flake.parts
[it]: https://github.com/vic/import-tree

---

## Repository Structure

```
.
├── flake.nix                    # Flake entrypoint: inputs + flake-parts outputs
├── flake.lock                   # Pinned input revisions
├── modules/                     # Auto-imported flake-parts modules (import-tree)
│   ├── parts.nix                # Target systems + home-manager flakeModule
│   ├── features/                # Reusable, machine-agnostic features
│   │   ├── niri.nix             # niri Wayland compositor (wrapped pkgs + config)
│   │   ├── noctalia.nix         # noctalia shell (bar, launcher, widgets)
│   │   ├── home-manager.nix     # homeConfigurations.pops (standalone HM output)
│   │   └── wallpapers/          # wallpaper image used by niri
│   └── hosts/
│       └── nvidiaMachine/       # This machine
│           ├── default.nix       # Wires up nixosConfigurations.nixos
│           ├── configuration.nix # System-level config (kernel, GPU, services)
│           └── hardware.nix      # Filesystems/UUIDs (machine-generated)
└── home/                        # Home Manager (standalone) user configuration
    ├── default.nix             # HM entrypoint (username, stateVersion, imports)
    ├── shell-profile.nix       # bash + eza/lazygit aliases + `v` fuzzy picker
    ├── tools.nix               # fzf, zoxide, bat, atuin
    ├── neovim.nix              # Neovim + LSPs/formatters + nvim symlink
    ├── opencode.nix            # opencode env vars (Exa search, LSP tool)
    ├── ghostty.nix             # Ghostty daemon on the dGPU (PRIME offload)
    ├── sbx.nix                 # docker-sbx helpers (sbx-run/-init/...) + kits
    └── sbx/                    # Installable agent kits (kit-spec v2)
        ├── opencode-go/        # opencode mixin (OpenCode Go + context7 + Exa)
        └── pi/                 # Pi coding agent sandbox kit
```

---

## Features

### System

- **Latest kernel** (`linuxPackages_latest`) with `systemd-boot` EFI boot.
- Flakes & `nix-command` experimental features; `pops` is a **trusted user**
  (so per-user cache/GC is allowed).
- Custom **CUDA cache** substituter (`cache.nixos-cuda.org`) for faster Nvidia
  builds.
- Italian locale/timezone (`Europe/Rome`, `en_US.UTF-8` default, `it`-family
  LC_* locale overrides).
- PipeWire audio (alsa, pulse, 32-bit support) with the real-time kit.
- CUPS printing.
- `programs.nix-ld` enabled with a curated set of common shared libraries
  (`dbus`, `libstdc++`, `zlib`, `openssl`, `glib`, `curl`) so pre-compiled
  binaries run without patching.
- `programs.nh` enabled and pointed at this flake for ergonomic rebuilds.
- `programs.gnupg.agent`, `pass`, `gnupg` for password / GPG management.
- Fonts: `monaspace`, `nerd-fonts.symbols-only`, `nunito`, and Spectral
  (via `google-fonts`).
- **Tailscale** enabled at startup.
- **Emacs** service (`emacs-gtk`).
- Single-node **k3s** cluster (`role = server`, node name `nixos`), with an
  Nvidia containerd runtime wired through the **nvidia-container-toolkit CDI**
  for GPU workloads; firewall opens TCP `6443` (k3s API). Not started at boot
  (`systemd.services.k3s.wantedBy` cleared; start with `sudo systemctl start k3s`).
  `KUBECONFIG=/etc/rancher/k3s/k3s.yaml` is set in the Home Manager session.
- **Rootless Docker**: the system-wide Docker daemon is *disabled*; a rootless
  user daemon for `pops` is configured with CDI (device enumeration), a private
  data dir (`~/.local/docker`), custom DNS and a gcr.io registry mirror.
  Needs `linger` and 65k subUID/subGID ranges, which are set for `pops`.
- **docker-sbx** (agent sandboxes) installed via a NixOS overlay pinned to
  `0.38.0` (nixpkgs lags; v0.38 carries the strict kit-spec v2 grammar used by
  our kits — see below).
- Overlay workarounds: `sioyek` forced to xcb + GLX (Qt6/Wayland EGL
  `EGL_BAD_MATCH`), plus the GTK3 `gsettings` schemas exported to
  `XDG_DATA_DIRS` so Qt apps' file chooser reads `org.gtk.Settings.FileChooser`.

### Hardware / GPU

- Intel CPU microcode, `kvm-intel` kernel module.
- Hybrid graphics: **Nvidia Prime offload** (Intel iGPU + discrete Nvidia).
  - `nvidia` driver (`legacy_580` package), modesetting + **power management**
    enabled.
  - `intelBusId = PCI:0@0:2:0`, `nvidiaBusId = PCI:1@0:0:0`.
  - `nvidia-prime.offload.enableOffloadCmd` exposes `nvidia-offload`.
- Touchpad support (libinput) enabled at the X11 level.

### Desktop Environment

- **niri** — the Wayland compositor, built through
  [nix-wrapper-modules][wm] (`myNiri`) with a full config:
  - Spawns the **noctalia** shell at startup (launcher, top bar with
    control-center/workspace/notification/battery/keyboard/clock/tray widgets,
    notifications, OSD, lock screen) and sets a wallpaper at boot.
  - Vim-style focus (`Alt+H/J/K/L`), move, workspace, and column keybindings;
    `Alt+Return` opens **Ghostty on the dGPU** (`nvidia-offload ghostty`);
    `Alt+S` toggles the launcher; `Print` screenshots (window/screen);
    XF86 media/brightness keys via `wpctl`/`playerctl`/`brightnessctl`.
  - xwayland-satellite for X11 apps, 5px gaps, `us,it` keymap, tap-to-click
    touchpad.
- **GNOME on X11** (`gdm` + `gnome`) also remains configured.
- Italian X11/console keymap (`it` / `it2`).
- Firefox, Brave and Ghostty terminals available (Ghostty daemon runs on the
  dGPU via a systemd user override — see below).

### User Environment (Home Manager)

Applied standalone via `home-manager switch ... --flake .#pops`:

- **Shell**: bash with eza-powered `ls`/`l`/`ll`/`la`/`lt` aliases, a `lazygit`
  (`lg`) alias, a `rip` (secure shred) alias, and a `v` function that fuzzy-picks
  files with `fd` + `fzf` + bat preview and opens them in Neovim.
- **Tools**: fzf (bash integration), zoxide (bash + nushell), bat, atuin
  shell history (Ctrl-R rebinding **disabled**).
- **Session**: `~/.local/bin` is added to `PATH`; `KUBECONFIG` points at the
  k3s kubeconfig.
- **Neovim**: managed by Home Manager with a curated set of language servers,
  formatters and build tools pulled in through `extraPackages` (Mason is
  disabled — everything comes from Nix):
  - **LSPs**: `nixd` (flake-aware: resolves the options of *this* flake's
    `nixos` and `pops` configs), `lua-language-server`, `rust-analyzer`,
    `pyright`, `ruff`, `gopls`, `golangci-lint`, `markdownlint-cli2`,
    `vscode-json-languageserver`, `markdown-toc`, `yaml-language-server`, `tombi`
  - **Formatters/Linters**: `stylua`, `nixfmt`
  - **Search**: `ripgrep`, `fd`, `fzf`
  - **Build**: `gcc`, `cmake`, `tree-sitter`, `gnumake`
  - **Snacks.nvim deps**: `imagemagick`, `ghostscript`, `sqlite`
  - LazyVim plugins include **mojo.nvim** (Mojo LSP/master/terminal) and a
    **nix.lua** plugin wiring nixd/treesitter; custom `nix` and `mojo` snippets.
  - The `~/.config/nvim` directory is **symlinked out-of-store** to
    `home/dotfiles/nvim/` (a LazyVim config), so the editor config can be edited
    live without going through a rebuild.
- **Ghostty** runs on the NVIDIA GPU: a systemd user drop-in sets
  `__NV_PRIME_RENDER_OFFLOAD=1` / `__GLX_VENDOR_LIBRARY_NAME=nvidia` on the
  Ghostty user service.
- **opencode**: environment variables set in `home/opencode.nix`
  (`OPENCODE_ENABLE_EXA=1`, `OPENCODE_EXPERIMENTAL_LSP_TOOL=1`,
  `OPENCODE_WEBSEARCH_PROVIDER=exa`).

### Autonomous Agent Sandboxes (docker-sbx)

Autonomous agent work runs inside Docker `sbx` microVM sandboxes rather than
directly on the host (`pops` is in the `kvm` group; the rootless host daemon is
not involved). Helpers defined in `home/sbx.nix`:

- `sbx-run <agent> [-- AGENT_ARGS...]` — launch an agent (`opencode`, `pi`,
  claude, codex, gemini, ...) in a `--clone` sandbox capped at
  `SBX_DEFAULT_MEMORY=4g` / `SBX_DEFAULT_CPUS=2` (tunable per run). `opencode`
  and `pi` automatically get their matching kit.
- `sbx-init` — one-time setup: global network policy to `deny-all` + store the
  OpenCode Go subscription API key in the OS keychain (`opencode-go` service).
- `sbx-ls-mem` / `sbx-cleanup` — sandbox listing with RAM summary / interactive
  removal.
- `sbx-policy-allow-code` — *opt-in*: add github + npm + pypi for projects that
  need public deps (not needed for a pure opencode+context7 workflow).

Two kit-spec **v2** kits are installed to `~/.config/sbx/kits/` via `home.file`:

- **opencode-go** (`kind: mixin`) — wires Exa + the experimental LSP tool,
  a **proxy-managed `OPENCODE_API_KEY`** (real key never enters the sandbox),
  egress locked to `opencode.ai`/`mcp.context7.com`/`mcp.exa.ai`, and
  auto-configures the unauthenticated **context7** remote MCP in
  `~/.config/opencode/opencode.jsonc`.
- **pi** (`kind: sandbox`) — the Pi coding agent (`@earendil-works/pi-coding-agent`)
  authenticating to OpenCode Go via the *shared* `opencode-go` credential,
  egress locked to the npm registry + opencode.ai.

Sandboxes persist across `sbx stop`/`start`; the host repo's `.git` is mounted
read-only and the agent's commits come back via `git fetch sandbox-<name>`
(fetched refs are mirrored to `refs/sandboxes/<name>/*` and survive `sbx rm`).

### Development Tooling

System packages include: `git`, `gh`, `jujutsu`, `lazygit`, `devenv`,
`opencode`, `nushell`, `jq`, `tmux`, `fastfetch`, `sioyek`, `starship`,
`ripgrep`, `fd`, `eza`, `nvd`, `nix-output-monitor`, `zip`/`unzip`, `xh`,
`xclip`, `pass`/`gnupg`, `ghostty`, `brave`, `docker-sbx`, `kubernetes-helm`,
`dust`, `k9s`, `tuicr`, `gnumake`, `telegram-desktop`, `obsidian` and `vim`
(default editor).

[wm]: https://github.com/BirdeeHub/nix-wrapper-modules

---

## Flake Inputs & Outputs

### Inputs (`flake.nix`)

| Input           | Source                                            |
|-----------------|---------------------------------------------------|
| `nixpkgs`       | `github:nixos/nixpkgs/nixos-unstable`             |
| `home-manager`  | `github:nix-community/home-manager` (follows `nixpkgs`) |
| `flake-parts`   | `github:hercules-ci/flake-parts`                  |
| `import-tree`   | `github:vic/import-tree` (auto-import `modules/`) |
| `wrapper-modules` | `github:BirdeeHub/nix-wrapper-modules` (niri, noctalia-shell) |

### Outputs

| Output path                   | Build target                          |
|-------------------------------|---------------------------------------|
| `nixosConfigurations.nixos`   | System closure (x86_64-linux)         |
| `homeConfigurations.pops`     | Home Manager user profile             |
| `packages.<sys>.myNiri`       | niri wrapped with this config         |
| `packages.<sys>.myNoctalia`   | noctalia shell wrapped with settings  |

---

## Usage

> `nh` is enabled and configured with `flake = "/home/pops/.config/nixos"`,
> so the commands below can run from anywhere.

### First-time / fresh install

```bash
# 1. (on a live NixOS ISO) partition & mount, then:
sudo nixos generate-config --root /mnt                # optional reference
sudo nixos-install --flake github:Parry-97/nixos#nixos  # or local: .#nixos

# 2. After first boot, as the `pops` user:
nix run home-manager -- switch --flake .#pops
```

### Applying changes

```bash
# Rebuild the OS (uses nh, set in configuration.nix)
sudo nh os switch                    # or: sudo nixos-rebuild switch --flake .#nixos

# Apply home-manager user changes
home-manager switch --flake .#pops   # or: nh home switch
```

### Updating inputs

```bash
nix flake update                       # bumps flake.lock
sudo nh os switch                      # apply the bumped system
home-manager switch --flake .#pops     # apply the bumped home
```

---

## Key Commands

| Action                       | Command                                   |
|------------------------------|-------------------------------------------|
| Rebuild + switch system      | `sudo nh os switch`                       |
| Rebuild + switch home        | `home-manager switch --flake .#pops`      |
| Update flake inputs          | `nix flake update`                         |
| Garbage collect old gens    | `sudo nh clean all` / `nix-collect-garbage -d` |
| Show diff between builds    | `nvd diff /run/current-system result-system` |
| Run Nvidia app on dGPU       | `nvidia-offload <command>`                 |
| Start k3s                    | `sudo systemctl start k3s`                 |
| Verify flake (eval/build)   | `nix flake check` / `home-manager build --flake .#pops` |
| Run an agent sandbox         | `sbx-run opencode -- "prompt"`             |

---

## Notes

- `modules/hosts/nvidiaMachine/hardware.nix` is the machine-generated
  hardware config (filesystem UUIDs, split `/` `/boot` `/home` partitions and
  a swap device) — fork responsibly.
- `home.stateVersion` and `system.stateVersion` are pinned to `26.05`.
- The LazyVim config under `home/dotfiles/nvim/` is a vendored copy with its
  own `LICENSE` and is symlinked (not copied) into `~/.config/nvim` so it can
  be tweaked on the fly.
- `docker-sbx` is overlaid to `0.38.0` because the strict kit-spec v2 grammar
  used by `home/sbx/*` needs it; bump the overlay once nixpkgs catches up.

---

## License

This configuration is provided as-is for personal use. The bundled LazyVim
configuration under `home/dotfiles/nvim/` retains its own upstream license.
