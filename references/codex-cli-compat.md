---
exclude: [claude-code, gemini-cli, opencode]
---

# Codex CLI Compatibility Guide

Use this reference when source workflows mention platform-specific tools or recursion rules that do not map 1:1 to Codex CLI.

| Source concept | Codex CLI mapping | Notes |
|---|---|---|
| `AskUserQuestion` | `request_user_input` (native Codex tool) | Codex has this tool natively — use it to ask follow-up questions and wait for the reply. |
| `request_user_input` | `request_user_input` (same name) | This tool exists in Codex CLI — no translation needed. |
| `Skill tool` | Follow the relevant skill instructions directly in the root context | Skills stay in the main chat; do not invent a separate Skill API. |
| `Agent tool` | Use `spawn_agent` only for bounded child tasks | The root context keeps orchestration and integration decisions. |
| `Read tool` | `shell` (e.g. `cat`) | Codex has no dedicated read_file tool; use shell commands. |
| `Glob tool` / `Grep tool` | `shell` (e.g. `find`, `grep`) | Or `list_dir` (experimental). |
| `Bash tool` | `shell` | Execute shell commands. |
| `max chain depth 3` | `agents.max_depth = 1` with root-only orchestration | A child can finish one bounded task; any next step is decided back in the root context. |
| `.mcp.json` | `.codex/config.toml` | Codex MCP and profile settings live in the TOML config. |

## Flattened Workflow Example

Source workflow wording:

1. Call `AskUserQuestion` for confirmation.
2. Use the `Skill tool` for the setup flow.
3. Use the `Agent tool` for a follow-up task.

Codex CLI wording:

1. Use `request_user_input` to ask the user and wait for the reply.
2. Keep the setup flow in the root context by following the skill instructions directly.
3. If a bounded side task remains, use `spawn_agent`, then return to the root context to decide what happens next.

## Troubleshooting

- Child approvals surface in the child thread. Approve or deny there, then continue orchestration from the root context after the child returns.
- If a task would require deeper recursion, stop spawning children and flatten the next step into the root context or split the work into separate bounded child tasks.
- Codex custom agents live in `.codex/agents/*.toml`.
- Repo-scoped Codex skills live in `.agents/skills/`.
- MCP servers, approval policy, sandbox mode, and profiles live in `.codex/config.toml`.
