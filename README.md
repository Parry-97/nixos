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

[standalone-commit]: https://github.com/Parry-97/nixos/commit/b082800

---

## Repository Structure

```
.
├── flake.nix                 # Flake entrypoint: inputs + nixos/home outputs
├── flake.lock                # Pinned input revisions
├── configuration.nix        # System-level NixOS configuration
├── hardware-configuration.nix# Filesystems, kernel modules, CPU (generated)
└── home/                     # Home Manager (standalone) user configuration
    ├── default.nix          # Home Manager entrypoint (username, stateVersion)
    ├── shell-profile.nix    # bash + eza/lazygit aliases
    ├── tools.nix            # fzf, zoxide, bat, atuin
    ├── neovim.nix           # Neovim + LSPs/formatters + lazyvim symlink
    └── dotfiles/
        └── nvim/            # LazyVim config (symlinked out-of-store)
```

---

## Features

### System

- **Latest kernel** (`linuxPackages_latest`) with `systemd-boot` EFI boot.
- Flakes & `nix-command` experimental features enabled.
- Custom **CUDA cache** substituter configured for faster Nvidia builds.
- Italian locale/timezone (`Europe/Rome`, `en_US.UTF-8` default).
- PipeWire audio (alsa, pulse, 32-bit support) with real-time kit.
- CUPS printing.
- `programs.nix-ld` enabled with a curated set of common shared libraries
  (`dbus`, `libstdc++`, `zlib`, `openssl`, `glib`, `curl`) so pre-compiled
  binaries run without patching.
- `programs.nh` enabled and pointed at this flake for ergonomic rebuilds.
- `programs.gnupg.agent`, `pass`, `gnupg` for password / GPG management.
- Fonts: `monaspace` + `nerd-fonts.symbols-only`.

### Hardware / GPU

- Intel CPU microcode, `kvm-intel` kernel module.
- Hybrid graphics: **Nvidia Prime offload** (Intel iGPU + discrete Nvidia).
  - `nvidia` driver (`legacy_580` package), modesetting enabled.
  - `intelBusId = PCI:0@0:2:0`, `nvidiaBusId = PCI:1@0:0:0`.
  - `nvidia-prime.offload.enableOffloadCmd` exposes `nvidia-offload`.

### Desktop Environment

- GNOME on X11 (`gdm` + `gnome`).
- Italian X11/console keymap (`it` / `it2`).
- Firefox, Brave and Ghostty terminals available.

### User Environment (Home Manager)

Applied standalone via `home-manager switch ... --flake .#pops`:

- **Shell**: bash with eza-powered `ls`/`l`/`ll`/`la`/`lt` aliases and a
  `lazygit` (`lg`) alias.
- **Tools**: fzf (bash integration), zoxide (bash + nushell), bat, atuin
  shell history.
- **Neovim**: managed by Home Manager with a curated set of language
  servers, formatters and build tools pulled in through `extraPackages`:
  - **LSPs**: `nixd`, `lua-language-server`, `rust-analyzer`, `pyright`, `gopls`
  - **Formatters/Linters**: `stylua`, `nixfmt`
  - **Search**: `ripgrep`, `fd`, `fzf`
  - **Build**: `gcc`, `cmake`, `tree-sitter`, `gnumake`
  - **Snacks.nvim deps**: `imagemagick`, `ghostscript`, `sqlite`
- The `~/.config/nvim` directory is **symlinked out-of-store** to
  `home/dotfiles/nvim/` (a LazyVim config), so the editor config can be edited
  live without going through a rebuild.

### Development Tooling

System packages include: `git`, `gh`, `jujutsu`, `lazygit`, `devenv`,
`opencode`, `nushell`, `jq`, `tmux`, `fastfetch`, `sioyek`, `starship`,
`ripgrep`, `fd`, `eza`, `nvd`, `nix-output-monitor`, `zip`/`unzip`, `xh`,
`xclip`, `pass`/`gnupg`.

---

## Flake Inputs & Outputs

### Inputs (`flake.nix`)

| Input         | Source                                   |
|---------------|------------------------------------------|
| `nixpkgs`     | `github:nixos/nixos-unstable`            |
| `home-manager`| `github:nix-community/home-manager` (follows `nixpkgs`) |

### Outputs

| Output path                  | Build target                    |
|------------------------------|---------------------------------|
| `nixosConfigurations.nixos`  | System closure (x86_64-linux)   |
| `homeConfigurations.pops`    | Home Manager user profile       |

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
home-manager switch --flake .#pops
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

---

## Notes

- `hardware-configuration.nix` is generated by `nixos-generate-config` and
  contains machine-specific UUIDs — fork responsibly.
- `home.stateVersion` and `system.stateVersion` are pinned to `26.05`.
- The LazyVim config under `home/dotfiles/nvim/` is a vendored copy with its
  own `LICENSE` and is symlinked (not copied) into `~/.config/nvim` so it can
  be tweaked on the fly.

---

## License

This configuration is provided as-is for personal use. The bundled LazyVim
configuration under `home/dotfiles/nvim/` retains its own upstream license.