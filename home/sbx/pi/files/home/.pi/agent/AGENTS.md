# Pi agent — sandbox context

You are the Pi coding agent running inside a Docker sandbox that clones the
host repository.

- **Inference**: you authenticate to the **OpenCode Go** provider
  (`opencode.ai`). The `OPENCODE_API_KEY` env var is set to the literal
  sentinel `proxy-managed` inside this sandbox; the host-side proxy injects
  the real key as `Authorization: Bearer <key>` on outbound requests to
  `opencode.ai`, so the real key never appears in the sandbox. Provider id is
  `opencode-go` — select models with `/model`.

- **Network**: egress is locked to `registry.npmjs.org` / `*.npmjs.org`
  (package installs) and `opencode.ai` (inference). `curl`/`wget`/`pip` to any
  other host will fail. Ask the host operator to run `sbx-policy-allow-code`
  if a project genuinely needs github/npm/pypi egress.

- **Session state**: stored in `~/.pi/agent/sessions/`; it persists as long as
  the sandbox exists (`sbx stop`/`sbx start` keep it; `sbx rm` deletes it).
  Use `-c` to continue the most recent session.

- **Built-in tools**: `read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`.
  Run shell commands with `!command` (sends output to the model) or
  `!!command` (doesn't). There is no MCP, no sub-agents, and no plan mode by
  design — use skills, prompt templates, and the `!` prefix instead.
