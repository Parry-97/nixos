# AGENTS.md

Personal NixOS flake. System + Home Manager (standalone) configs. The
detailed architecture lives in `README.md`; this file is the short list of
things an agent would likely get wrong.

## Two independent build targets

`flake.nix` exposes two outputs that are built and applied **separately**.
Home Manager is intentionally NOT a NixOS module — do not wire them together.

| What | Command |
|------|---------|
| System (OS) | `sudo nh os switch` |
| Home (user) | `nh home switch` |
| Bump inputs | `nix flake update` then both commands above |

`nh` is configured (`configuration.nix`) with `flake = "/home/pops/.config/nixos"`,
so both `nh os switch` and `nh home switch` work from any directory (home
resolves `homeConfigurations.pops` from the current user; `home-manager switch
--flake .#pops` is equivalent). Targets are `.#nixos` and `.#pops`.

There is no test/lint/typecheck suite. Verify edits with:

```bash
nix flake check                          # schema / eval checks
nix build .#nixosConfigurations.nixos     # full system build (slow)
nix build .#homeConfigurations.pops       # home build
```

Nix formatting: `nixfmt` (used by the `nixd` LSP in this repo). Format `.nix`
files with `nixfmt <file>` before committing.

## File ownership

- `flake.nix` — inputs + both outputs. Evaled by both targets.
- `configuration.nix` — system-level (kernel, drivers, services, packages).
- `hardware-configuration.nix` — **machine-generated** by
  `nixos-generate-config`; contains filesystem UUIDs and bus IDs. Do not
  hand-edit unless changing hardware; do not copy into another machine's repo.
- `home/default.nix` — Home Manager entrypoint; imports the other `home/*.nix`
  modules. Add new user-facing modules here.
- `home/dotfiles/nvim/` — vendored LazyVim config, **symlinked out-of-store**
  into `~/.config/nvim` (see `home/neovim.nix`). Editing these files takes
  effect live without a rebuild; do NOT import them through the Nix store.

## Conventions / gotchas

- `nixpkgs` tracks `nixos-unstable`; do not pin to a release branch.
- `home.stateVersion` and `system.stateVersion` are pinned to `26.05` — do
  not bump without a migration plan.
- Nvidia hybrid graphics uses Prime offload; run a binary on the dGPU with
  `nvidia-offload <cmd>`. Driver package is `legacy_580` — match this when
  touching GPU config.
- Italian locale/timezone (`Europe/Rome`); X11/console keymap `it`/`it2`.
- Opencode-specific env vars are set in `home/opencode.nix`
  (`OPENCODE_ENABLE_EXA`, `OPENCODE_EXPERIMENTAL_LSP_TOOL`,
  `OPENCODE_WEBSEARCH_PROVIDER=exa`). Change opencode behavior there, not in
  shell rc files.
- `programs.nix-ld` is enabled with a curated shared-lib set so pre-compiled
  binaries run unpatched; add missing libs to that list rather than patching.

## Autonomous agent sandboxes (`docker-sbx`)

Autonomous agent work runs inside Docker `sbx` microVM sandboxes rather than
directly on the host. The `docker-sbx` binary package is installed via
`environment.systemPackages`; `pops` is in the `kvm` group so the per-sandbox
microVMs can use KVM. Rootless Docker stays `enable = false` — `sbx` runs its
own per-sandbox daemons inside the microVMs and does not use the host Docker.

Shell helpers live in `home/sbx.nix` (wired through `programs.bash.initExtra`):
- `sbx-run <agent> [-- AGENT_ARGS...]` — launch an agent in a clone-mode sandbox
  with the default 4 GiB / 2 vCPU caps. When the agent is `opencode`, the
  opencode-go kit is applied automatically; when it's `pi`, the pi sandbox kit
  is applied (see below).
- `sbx-init` — one-time first-run setup: initializes the global network policy
  to `deny-all` and stores the OpenCode Go subscription API key in the OS
  keychain (`sbx secret set -g opencode-go`). Run once after `sbx login`.
- `sbx-ls-mem` — list sandboxes with a memory-capacity summary.
- `sbx-cleanup` — interactive `sbx rm`.
- `sbx-policy-allow-code` — opt-in: globally add github + npm + pypi for
  projects that need public deps/git. Do NOT use for a pure
  opencode+context7 workflow that just edits the cloned host repo.

Both kits use kit-spec **v2** (`schemaVersion: "2"`, strict grammar:
`permissions`/`credentials`/`setup`/`agentInstructions`). The kit grammar and
the credential binding are enforced by the `sbx` daemon — the kits in this repo
target `docker-sbx` **>= 0.38.0** (v0.37.0 only understands an intermediate
grammar and will reject these specs). Kits live at
`~/.config/sbx/kits/{opencode-go,pi}/` (installed via `home.file`).

**opencode-go kit** (`home/sbx/opencode-go/spec.yaml`) — a v2 `kind: mixin`
applied via `sbx run --kit` when the agent is `opencode`. It wires:
- **Feature flags**: `OPENCODE_ENABLE_EXA=1`, `OPENCODE_WEBSEARCH_PROVIDER=exa`,
  `OPENCODE_EXPERIMENTAL_LSP_TOOL=1` (set directly in the sandbox env).
- **Credential**: `OPENCODE_API_KEY` is proxy-managed — the sandbox sees the
  `proxy-managed` sentinel; the host-side proxy injects the real key as
  `Authorization: Bearer <key>` on outbound requests to `opencode.ai`. The
  real key never enters the sandbox. Stored on the host via
  `sbx secret set -g opencode-go` (OS keychain, or encrypted file fallback on
  headless Linux). The inject rule must use an explicit
  `header: Authorization` + `format: "Bearer %s"` — the `scheme: bearer` sugar
  does NOT produce a header mapping in the proxy, which then strips the
  sentinel header and the API replies `AuthError: Missing API key.`
- **Binding**: v2 kits require one credential binding. First `sbx run --kit`
  prompts for approval; equivalent hand-written file is
  `~/.config/sbx/credentials.yaml` with
  `bindings: { opencode-go: { apiKey: { domains: [opencode.ai] } } }`.
- **Network**: egress locked to `opencode.ai` and `*.opencode.ai` (Go inference
  at `/zen/go/v1/*`; the model catalog lives on `models.opencode.ai`, so the
  wildcard is required or the provider init fails), `mcp.context7.com`
  (context7 MCP, unauthenticated), and `mcp.exa.ai` (Exa web search via
  opencode's built-in `websearch` tool, unauthenticated). Note: `api.exa.ai`
  is NOT used — opencode's Exa provider calls `mcp.exa.ai/mcp` (the hosted MCP
  endpoint), not the direct API.
- **context7 auto-config**: writes `~/.config/opencode/opencode.jsonc` in the
  sandbox with the context7 remote MCP server pre-configured (unauthenticated,
  no API key). The file must be `.jsonc`, NOT `opencode.json` — the opencode
  agent's built-in startup script rewrites `opencode.json` on every container
  start, and opencode deep-merges the global config files.

**pi kit** (`home/sbx/pi/spec.yaml`) — a v2 `kind: sandbox` (complete agent):
the Pi coding agent (`@earendil-works/pi-coding-agent`, npm) with
`sandbox.entrypoint: [pi]`, authenticating to OpenCode Go via the **shared
`opencode-go` credential service** (same key). Egress is locked to the npm
registry (registry.npmjs.org / *.npmjs.org, needed for the install step) and
opencode.ai / *.opencode.ai. `PI_SKIP_VERSION_CHECK=1`, `PI_TELEMETRY=0`.
Setup npm-installs pi globally (through the sandbox proxy, with retries) and
ensures `~/.pi/agent/sessions/` exists; the sandbox context
`~/.pi/agent/AGENTS.md` ships from `home/sbx/pi/files/`. Launch with
`sbx-run pi`; inside the sandbox run
`pi --provider opencode-go --model glm-5.2 --print "prompt"` (non-interactive)
or `pi --provider opencode-go` for the interactive TUI.

context7 and Exa are both used **unauthenticated** (no API keys) — only
`OPENCODE_API_KEY` (the Go subscription key) needs to be stored on the host.

Workflow convention: agents run in `--clone` mode, so the host repo's `.git`
is mounted read-only and the agent's commits stay inside the sandbox's clone.
The sandbox is auto-added as a `sandbox-<name>` git remote on the host —
`git fetch sandbox-<name>` and review with normal git operations
(`git diff main...sandbox-<name>/main`, `git merge --no-ff ...`). Fetched refs
are mirrored to `refs/sandboxes/<name>/*` and persist after `sbx rm`, so
forgetting to fetch before cleanup is recoverable. Sandboxes persist across
`sbx stop`/`sbx start`, so you can pause a task mid-flight and resume it the
next day; `sbx rm` is the only thing that drops state. Per-project branch
strategy (stay on `main` vs create a `feat/<name>` per task) is a project-level
decision — document it in the project's `AGENTS.md`/`CLAUDE.md`, not here.

Tuning: defaults target 2-3 parallel sandboxes on the 32 GiB / 8 CPU host.
For a single max-headroom run, override the env vars: e.g.
`SBX_DEFAULT_MEMORY=12g SBX_DEFAULT_CPUS=6 sbx-run opencode`. Do not rely on
the `sbx` defaults (50% of host RAM, N-1 CPUs) when running more than one
sandbox concurrently.