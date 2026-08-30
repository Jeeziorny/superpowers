---
description: Point Superpowers spec and plan documents at a location you choose, and name this project's test conventions
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config:*)
argument-hint: "[absolute path for specs] [absolute path for plans] [absolute path to test conventions file]"
---

# Superpowers Setup

Configure where the `brainstorming` and `writing-plans` skills write their spec
and plan documents, and which file records this project's test conventions for
`test-driven-development`. Everything here is done by
`scripts/superpowers-config` — do not hand-edit skill files, and do not invent
paths.

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

4. **Get the test conventions file.** If the third argument is present, use it.
   Otherwise ask:

   > "Does this project have a file recording its test conventions — naming,
   > fixtures, how the suite is run? Absolute path to that file, or say 'none'.
   > Current: `<test_conventions value from step 1>`"

   STOP and wait. If they say "none", skip to step 5 — or, if step 1 showed a
   value and they now want it gone, clear it:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" unset test-conventions
   ```

   This one names an **existing file**, not a directory: the script refuses a
   path that does not exist, because a typo would configure a file nothing ever
   reads and the only symptom is conventions being quietly ignored. If your
   human partner names a file that does not exist yet, say so and ask them to
   create it first — do not create it for them and do not write its contents.

5. **Apply the settings.** Run once per key your human partner supplied. Add
   `--user` only if they asked for the setting to apply to every project rather
   than this one:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" set specs "<path>"
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" set plans "<path>"
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" set test-conventions "<path>"
   ```

6. **Verify coverage.** This fails if any skill still names a default path
   without saying a configured location overrides it — the case where an agent
   copies the old path out of a skill and ignores the setting:

   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/superpowers-config" check
   ```

   If it exits non-zero, report the listed lines to your human partner rather
   than editing them silently. Skill text is behaviour-shaping and changing it
   is their call.

7. **Confirm** by showing the resolved result:

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
- `$SUPERPOWERS_SPECS_DIR` / `$SUPERPOWERS_PLANS_DIR` /
  `$SUPERPOWERS_TEST_CONVENTIONS` override both, for one-off runs.
- The config file is shared by every worktree of the repository, so a setting
  made in the main checkout still applies inside a worktree — which is where
  `using-git-worktrees` puts the session.
- `test-conventions` has no default. A project that never sets it behaves
  exactly as before: nothing is injected and `test-driven-development` falls
  back to following the surrounding tests.
- Nothing here touches the SDD scratch workspace (`.superpowers/sdd/`) or
  worktree locations. Those are separate and were left alone deliberately.
