---
description: Point Superpowers spec and plan documents at a location you choose
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config:*)
argument-hint: "[absolute path for specs] [absolute path for plans]"
---

# Superpowers Setup

Optional. Run it once if you want spec and design documents somewhere other
than `docs/superpowers/specs/` and `docs/superpowers/plans/` inside the current
repo. Skipping it entirely leaves Superpowers at its shipped defaults.

Everything here is done by `scripts/superpowers-config`. Do not hand-edit skill
files, and do not invent paths.

Arguments (both optional): $ARGUMENTS

## Steps

1. **Show the current state:**

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" show
   ```

2. **Get the specs path.** If the first argument is present, use it. Otherwise ask:

   > "Where should design specs be written? Give me an absolute path.
   > Current: `<specs value from step 1>`"

   STOP and wait for an answer. Do not guess, do not offer a default, and do
   not proceed on a relative path — the script rejects those.

3. **Get the plans path.** If the second argument is present, use it. Otherwise ask:

   > "And where should implementation plans go? Absolute path, or say
   > 'same' to use `<specs path>`.
   > Current: `<plans value from step 1>`"

   STOP and wait. If they say "same", pass the specs path.

4. **Record both choices:**

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" set specs "<path>"
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" set plans "<path>"
   ```

   Add `--user` to either only if your human partner asked for the setting to
   apply to every project rather than this one.

5. **Rewrite the skill files to match:**

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" apply
   ```

6. **Verify it took:**

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" check
   ```

   If this exits non-zero, report the output verbatim. Do not try to fix the
   skill files by hand.

7. **Tell them what happened** — which paths are now in effect, and that
   `apply` edits the installed plugin's skill files, so **a plugin update will
   overwrite it**. Re-running `/superpowers-setup` after an update restores it,
   and because the choice is recorded in the config file, `superpowers-config
   apply` on its own is enough — it will not ask again.

## Undoing it

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" revert
```

Restores the shipped `docs/superpowers/...` defaults in every skill file.

## Notes

- The recorded choice lives in `<repo>/.superpowers/config` (git-ignored), or
  `${XDG_CONFIG_HOME:-$HOME/.config}/superpowers/config` with `--user`.
- `$SUPERPOWERS_SPECS_DIR` / `$SUPERPOWERS_PLANS_DIR` override the config file
  for a one-off run.
- This covers spec and plan documents only. The subagent-driven-development
  scratch workspace (`.superpowers/sdd/`), worktree locations, and brainstorm
  visual sessions are separate and deliberately untouched.
