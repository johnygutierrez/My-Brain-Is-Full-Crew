#!/usr/bin/env bash
# Tests for adapters/lib.sh
# Source the lib under test
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/adapters/lib.sh"

# Test functions will be added in subsequent tasks.
# Each function must be named test_* to be auto-discovered by tests/run.sh.

test_parse_frontmatter_scalar() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
description: Text Capture
model: sonnet
---
body content
EOF
  local result; result="$(parse_frontmatter "$fixture" name)"
  rm "$fixture"
  [[ "$result" == "scribe" ]] || { echo "expected 'scribe', got '$result'"; return 1; }
}

test_parse_frontmatter_list() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
capabilities: [read, write, edit]
---
EOF
  local result; result="$(parse_frontmatter "$fixture" capabilities)"
  rm "$fixture"
  [[ "$result" == "[read, write, edit]" ]] || { echo "expected '[read, write, edit]', got '$result'"; return 1; }
}

test_parse_frontmatter_missing_key() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
---
EOF
  local result; result="$(parse_frontmatter "$fixture" nonexistent)"
  rm "$fixture"
  [[ -z "$result" ]] || { echo "expected empty, got '$result'"; return 1; }
}

test_parse_capabilities_normal() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
capabilities: [read, write, edit]
---
EOF
  local result; result="$(parse_capabilities "$fixture")"
  rm "$fixture"
  [[ "$result" == "read write edit" ]] || { echo "expected 'read write edit', got '$result'"; return 1; }
}

test_parse_capabilities_single() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
capabilities: [read]
---
EOF
  local result; result="$(parse_capabilities "$fixture")"
  rm "$fixture"
  [[ "$result" == "read" ]] || { echo "expected 'read', got '$result'"; return 1; }
}

test_parse_capabilities_empty() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
capabilities: []
---
EOF
  local result; result="$(parse_capabilities "$fixture")"
  rm "$fixture"
  [[ -z "$result" ]] || { echo "expected empty, got '$result'"; return 1; }
}

test_should_include_no_exclude() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
---
EOF
  if should_include "$fixture" claude-code; then
    rm "$fixture"; return 0
  else
    rm "$fixture"; echo "expected 0, got 1"; return 1
  fi
}

test_should_include_empty_exclude() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
exclude: []
---
EOF
  if should_include "$fixture" claude-code; then
    rm "$fixture"; return 0
  else
    rm "$fixture"; echo "expected 0, got 1"; return 1
  fi
}

test_should_include_excluded() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
exclude: [opencode]
---
EOF
  if should_include "$fixture" opencode; then
    rm "$fixture"; echo "expected 1, got 0"; return 1
  else
    rm "$fixture"; return 0
  fi
}

test_should_include_excluded_other_fw() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
exclude: [opencode]
---
EOF
  if should_include "$fixture" claude-code; then
    rm "$fixture"; return 0
  else
    rm "$fixture"; echo "expected 0, got 1"; return 1
  fi
}

test_parse_hook_yaml_simple() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
name: notify
script: notify.sh
triggers:
  - event: on-notification
exclude: []
EOF
  local result; result="$(parse_hook_yaml "$fixture")"
  rm "$fixture"
  [[ "$result" == *"name=notify"* ]] || { echo "missing name=notify in: $result"; return 1; }
  [[ "$result" == *"script=notify.sh"* ]] || { echo "missing script="; return 1; }
  [[ "$result" == *"event=on-notification"* ]] || { echo "missing event="; return 1; }
}

test_parse_hook_yaml_with_match() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
name: protect-system-files
script: protect-system-files.sh
triggers:
  - event: before-tool-use
    match-tool: [edit, write]
EOF
  local result; result="$(parse_hook_yaml "$fixture")"
  rm "$fixture"
  [[ "$result" == *"event=before-tool-use"* ]] || { echo "missing event"; return 1; }
  [[ "$result" == *"match-tool=edit write"* ]] || { echo "missing match-tool: $result"; return 1; }
}

test_agent_body() {
  local fixture; fixture="$(mktemp)"
  cat > "$fixture" <<'EOF'
---
name: scribe
---

You are the Scribe.
You write notes.
EOF
  local result; result="$(agent_body "$fixture")"
  rm "$fixture"
  [[ "$result" == *"You are the Scribe."* ]] || { echo "missing body line 1"; return 1; }
  [[ "$result" == *"You write notes."* ]] || { echo "missing body line 2"; return 1; }
  [[ "$result" != *"name: scribe"* ]] || { echo "frontmatter leaked into body"; return 1; }
}

test_enumerate_agents() {
  local dir; dir="$(mktemp -d)"
  touch "$dir/foo.md" "$dir/bar.md" "$dir/not-an-agent.txt"
  local count; count="$(enumerate_agents "$dir" | wc -l | xargs)"
  rm -rf "$dir"
  [[ "$count" == "2" ]] || { echo "expected 2, got $count"; return 1; }
}

test_enumerate_hooks() {
  local dir; dir="$(mktemp -d)"
  touch "$dir/foo.hook.yaml" "$dir/bar.hook.yaml" "$dir/foo.sh"
  local count; count="$(enumerate_hooks "$dir" | wc -l | xargs)"
  rm -rf "$dir"
  [[ "$count" == "2" ]] || { echo "expected 2, got $count"; return 1; }
}

test_rewrite_framework_paths_opencode() {
  local file; file="$(mktemp)"
  printf 'See .claude/agents/ and .claude/references/foo.md\nAlso CLAUDE.md here.\n' > "$file"
  rewrite_framework_paths "$file" "opencode" "AGENTS.md"
  local result; result="$(cat "$file")"
  rm "$file"
  [[ "$result" == *".opencode/agents/"* ]]     || { echo "agents/ not rewritten: $result"; return 1; }
  [[ "$result" == *".opencode/references/"* ]]  || { echo "references/ not rewritten: $result"; return 1; }
  [[ "$result" == *"AGENTS.md"* ]]              || { echo "AGENTS.md not present: $result"; return 1; }
  [[ "$result" != *".claude/"* ]]               || { echo ".claude/ still present: $result"; return 1; }
  [[ "$result" != *"CLAUDE.md"* ]]              || { echo "CLAUDE.md still present: $result"; return 1; }
}

test_rewrite_framework_paths_noop_for_claude_code() {
  local file; file="$(mktemp)"
  local content='.claude/agents/ and CLAUDE.md'
  printf '%s\n' "$content" > "$file"
  rewrite_framework_paths "$file" "claude" "CLAUDE.md"
  local result; result="$(cat "$file")"
  rm "$file"
  [[ "$result" == "$content" ]] || { echo "content was changed unexpectedly: $result"; return 1; }
}

test_rewrite_framework_paths_preserves_product_name() {
  local file; file="$(mktemp)"
  printf 'Claude Code auto-loads agents from .claude/agents/\n' > "$file"
  rewrite_framework_paths "$file" "opencode" "AGENTS.md"
  local result; result="$(cat "$file")"
  rm "$file"
  [[ "$result" == *"Claude Code auto-loads"* ]] || { echo "product name was altered: $result"; return 1; }
  [[ "$result" == *".opencode/agents/"* ]]       || { echo "path not rewritten: $result"; return 1; }
}
