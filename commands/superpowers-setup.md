---
description: Point Superpowers spec and plan documents at a location you choose
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config:*)
argument-hint: "[absolute path for specs] [absolute path for plans]"
---

# Superpowers Setup

Configure where the `brainstorming` and `writing-plans` skills write their spec
and plan documents. Everything here is done by `scripts/superpowers-config` —
do not hand-edit skill files, and do not invent paths.

Arguments (both optional): $ARGUMENTS

## Steps

1. **Show the current setting** so your human partner can see what they are changing:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" show
   ```

2. **Get the specs path.** If the first argument is present, use it. Otherwise ask:

   > "Where should design specs be written? Give me an absolute path.
   > Current: `<specs value from step 1>`"

   STOP and wait for an answer. Do not guess a path, do not offer a default,
   and do not proceed on a relative path — the script rejects those.

3. **Get the plans path.** If the second argument is present, use it. Otherwise ask:

   > "And where should implementation plans go? Absolute path, or say
   > 'same' to use `<specs path>`.
   > Current: `<plans value from step 1>`"

   STOP and wait. If they say "same", pass the specs path.

4. **Apply both.** Run once per key. Add `--user` only if your human partner
   asked for the setting to apply to every project rather than this one:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" set specs "<path>"
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" set plans "<path>"
   ```

5. **Verify coverage.** This fails if any skill still names a default path
   without saying a configured location overrides it — the case where an agent
   copies the old path out of a skill and ignores the setting:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" check
   ```

   If it exits non-zero, report the listed lines to your human partner rather
   than editing them silently. Skill text is behaviour-shaping and changing it
   is their call.

6. **Confirm** by showing the resolved result:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" show
   ```

   Then tell them: the setting is stored in the config file printed by
   `superpowers-config path`, it survives plugin upgrades because no skill
   file is modified, and it takes effect in **new** sessions — the
   SessionStart hook is what feeds these paths to the skills.

## Notes

- A project-level setting lives in `<repo>/.superpowers/config`, which is
  already git-ignored. A `--user` setting lives in
  `${XDG_CONFIG_HOME:-$HOME/.config}/superpowers/config` and applies everywhere.
- `$SUPERPOWERS_SPECS_DIR` / `$SUPERPOWERS_PLANS_DIR` override both, for
  one-off runs.
- Nothing here touches the SDD scratch workspace (`.superpowers/sdd/`) or
  worktree locations. Those are separate and were left alone deliberately.
