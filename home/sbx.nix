# Docker sbx (Agent Sandboxes) helpers.
#
# Autonomous coding-agent work runs inside `docker-sbx` microVM sandboxes
# rather than directly on the host. These shell helpers enforce per-sandbox
# resource caps so 2-3 can run in parallel on the 32 GiB / 8 CPU host without
# hitting sbx's "50% of host RAM, N-1 CPUs" default — which would OOM the
# machine after the second sandbox.
#
# Two kits (schemaVersion "2", installed to ~/.config/sbx/kits/ via home.file):
#   opencode-go  — a mixin for the built-in opencode agent. Declaratively wires
#                  feature flags, proxy-managed OPENCODE_API_KEY credential, the
#                  network allowlist, and auto-configures the context7 MCP
#                  server — so an `sbx-run opencode` just works.
#   pi           — a sandbox (complete agent) running the Pi coding agent
#                  (npm @earendil-works/pi-coding-agent), authenticating to the
#                  same opencode-go credential service (shared OpenCode Go key).
# Both kits share the `opencode-go` credential service; v2 kits require one
# credential binding for it (created via first-run approval, or by hand in
# ~/.config/sbx/credentials.yaml).
#
# Workflow (see AGENTS.md):
#   sbx-init                             # one-time: policy + OPENCODE_API_KEY
#   sbx-run opencode -- "prompt"         # launch opencode in a clone-mode sandbox
#   sbx ls                               # see your sandboxes (they persist)
#   sbx stop <name> && sbx start <name>  # pause/resume across days
#   git fetch sandbox-<name>             # pull the agent's commits back to host
#   git diff main...sandbox-<name>/main  # review
#   sbx-cleanup                          # interactive rm when you're done
#
# Opt-in (only if a project needs public deps/git):
#   sbx-policy-allow-code                # globally add github + npm + pypi
{ ... }:
{
  # opencode-go kit — a v2 mixin applied via `sbx run --kit` when the agent is
  # opencode. Installs feature flags (Exa search, LSP tool), proxy-managed
  # OPENCODE_API_KEY injection, a 3-host network allowlist, and an
  # auto-configured context7 remote MCP server. See home/sbx/opencode-go/spec.yaml.
  home.file.".config/sbx/kits/opencode-go/spec.yaml".source = ./sbx/opencode-go/spec.yaml;

  # pi kit — a v2 sandbox (complete agent): the Pi coding agent
  # (@earendil-works/pi-coding-agent) using the OpenCode Go provider via the
  # shared opencode-go credential. Installed as a directory so its files/
  # tree (the sandbox-context AGENTS.md) ships too. See home/sbx/pi/spec.yaml.
  home.file.".config/sbx/kits/pi".source = ./sbx/pi;

  programs.bash.initExtra = ''
    # Per-sandbox resource caps. Defaults target 2-3 parallel on 32 GiB / 8 CPU.
    # Override per shell (e.g. `SBX_DEFAULT_MEMORY=12g SBX_DEFAULT_CPUS=6`) for
    # a single max-headroom run.
    export SBX_DEFAULT_MEMORY="''${SBX_DEFAULT_MEMORY:-4g}"
    export SBX_DEFAULT_CPUS="''${SBX_DEFAULT_CPUS:-2}"

    # Launch an agent in a clone-mode sandbox with the default caps.
    # Sandbox persists after the agent exits; use `sbx stop`/`sbx start`/
    # `sbx rm` to manage lifecycle. The agent's commits stay inside the
    # sandbox's clone until you `git fetch sandbox-<name>` on the host.
    #
    # When the agent is opencode, the opencode-go kit is applied automatically
    # (feature flags + proxy-managed OPENCODE_API_KEY + network allowlist +
    # context7 MCP auto-config). When the agent is pi, the pi sandbox kit is
    # applied (the Pi coding agent on the shared OpenCode Go provider). Pass
    # agent args after `--`.
    sbx-run() {
      if [[ "$#" -lt 1 ]]; then
        echo "Usage: sbx-run <agent> [-- AGENT_ARGS...]" >&2
        echo "Agents: claude codex gemini opencode copilot kiro pi ..." >&2
        return 2
      fi
      local agent="$1"; shift || true
      local -a kit_args=()
      if [[ "$agent" == "opencode" ]]; then
        local kit="$HOME/.config/sbx/kits/opencode-go"
        if [[ -f "$kit/spec.yaml" ]]; then
          kit_args+=(--kit "$kit")
        else
          echo "sbx-run: warning — opencode-go kit not found at $kit/spec.yaml" >&2
          echo "Run home-manager switch (or sbx-init) to install it." >&2
        fi
      elif [[ "$agent" == "pi" ]]; then
        local kit="$HOME/.config/sbx/kits/pi"
        if [[ -f "$kit/spec.yaml" ]]; then
          kit_args+=(--kit "$kit")
        else
          echo "sbx-run: warning — pi kit not found at $kit/spec.yaml" >&2
          echo "Run home-manager switch (or sbx-init) to install it." >&2
        fi
      fi
      sbx run --clone \
        --memory "''${SBX_DEFAULT_MEMORY}" --cpus "''${SBX_DEFAULT_CPUS}" \
        "''${kit_args[@]}" \
        "$agent" "$@"
    }

    # List sandboxes with a memory-capacity summary.
    sbx-ls-mem() {
      sbx ls
      echo
      local count
      count=$(sbx ls 2>/dev/null | grep -c '^' || true)
      if [[ "$count" -gt 0 ]]; then
        echo "~$((count * 4)) GiB RAM across $count sandbox(es) at defaults."
        echo "Host: 32 GiB / 8 CPU. Comfortable at <=3; tune caps to overcommit."
      fi
    }

    # Interactive cleanup: list sandboxes, prompt for one to remove.
    sbx-cleanup() {
      sbx ls
      echo
      read -r -p "Sandbox to remove (empty to cancel): " name
      [[ -n "$name" ]] && sbx rm "$name"
    }

    # One-time first-run setup. Does two things:
    #   1. Initializes the global network policy to deny-all (locked down).
    #      The kits' permissions.network.allow opens the endpoints an agent
    #      needs, per-sandbox. Fails harmlessly if the
    #      policy is already initialized — check `sbx policy ls`.
    #   2. Stores the OpenCode Go subscription API key in the OS keychain
    #      (or encrypted file fallback on headless hosts). Both kits read the
    #      `opencode-go` service — proxy-managed, so the real key never enters
    #      the sandbox. You'll be prompted to paste the key. On first `sbx run`
    #      after switching to kit-spec v2, you'll also be asked to approve the
    #      credential binding for `opencode-go`.
    sbx-init() {
      echo "==> Initializing global network policy (deny-all)..."
      sbx policy init deny-all || echo "    (may already be initialized — check: sbx policy ls)"
      echo
      echo "==> Storing OpenCode Go subscription API key (opencode-go service)..."
      echo "    You'll be prompted to paste your key. It goes into the OS keychain."
      echo "    Get it from: https://opencode.ai/auth"
      echo
      sbx secret set -g opencode-go
      echo
      echo "==> Done. Next steps:"
      echo "    sbx-run opencode -- \"your prompt\""
      echo "    # Opt-in if a project needs public deps/git:"
      echo "    sbx-policy-allow-code"
    }

    # Opt-in: add public code-hosting and package-registry endpoints on top
    # of the per-sandbox kit allowlist. Use this only when an agent's project
    # work needs to fetch dependencies or clone from public repos. For a pure
    # opencode+context7 workflow that just edits the cloned host repo, you
    # do NOT need this — leave it locked down.
    sbx-policy-allow-code() {
      sbx policy allow network \
        github.com api.github.com codeload.github.com \
        registry.npmjs.org \
        pypi.org files.pythonhosted.org
      echo
      sbx policy ls
    }
  '';
}
