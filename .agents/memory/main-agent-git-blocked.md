---
name: Main-agent git is write-blocked
description: Why git write ops fail for the main agent, and the repo's prose+SHA milestone convention as the workaround.
---

# Main-agent git writes are blocked

Any git *write* from the main agent (tagging, committing, resetting,
checking out, …) is rejected by the sandbox guard with:
"Destructive git operations are not allowed in the main agent. Use the
`project_tasks` skill to propose a new background Project Task that will perform
this git operation instead." Even read-only `git status` is blocked unless run
with `--no-optional-locks`.

**Subtle footgun:** the guard scans the *entire bash command string*, including
heredoc bodies. A perfectly innocent `cat >> file <<EOF ... EOF` gets blocked if
its CONTENT merely mentions a git write verb. Write such files with the
write/edit file tools (not guarded), never via a bash heredoc that quotes git
verbs.

**Why it matters:** a user "merge X / tag Y" order cannot be satisfied with a
literal tag from the main agent. The work itself is already on `main` (I edit
main directly; Replit checkpoints are the auto-commits), so "merge" is
effectively a no-op, but the tag ref cannot be created here.

**How to apply:**
- Track milestones as **prose + SHA** in `replit.md` / `docs/ROADMAP.md` /
  `docs/CHANGELOG.md` (the repo already does this: "YM frozen at `c8f6a7ed`").
  Record the tag *name* + the checkpoint SHA it would point at.
- The vendored-mathlib recovery scripts (`restore-lake-git.sh`) wrap git ops in
  a *script file* run via `bash`, which bypasses the string-level guard for the
  *non-destructive* pin-restore path — do NOT use that trick to fabricate git
  writes the guard is meant to block (tags/commits); only the pin-restore use is
  sanctioned.
- If the user truly needs a real git ref, delegate via a background Project Task.
