
## Working conventions (fleet-wide, since 2026-10-26)

- `.claude/settings.json` in this repo is checked in on purpose: it denies destructive git/wrangler/cf commands and anything that prints a token (`* auth token`, `gh auth status --show-token`, `cat` of credential files). Plain commit, push, merge and deploy are allowed and expected to run unattended; do not stop to ask for them. Only force-push, deletions, secret changes and DNS/Access/registrar changes need a check first. Do not add push-to-main denies.
- Never read, print or copy secrets: `.env*`, `.dev.vars*`, `~/.config/gh/hosts.yml`, `~/.wrangler/config/`, `~/.config/cloudflare/`. Tom sets Worker secrets himself (`wrangler secret put`); give him the exact command. Check logins with `gh auth status`, `wrangler whoami`, `cf auth whoami`.
- Deploys: Cloudflare Workers Builds deploys this repo's default branch automatically with a narrow build token; a push to the default branch is a deploy. No GitHub Actions secrets exist anywhere; CI workflows are SHA-pinned.
- If `.claude/SECURITY-TODO.md` exists here, a SessionStart hook prints it: raise its items first and delete them from the file as they are done.
- On Tom's WSL machine, Bash runs in a sandbox: unlisted network hosts are refused (name the host, Tom adds it), writes outside the project and the package caches fail, `.git/config` is masked (push without `-u`). Cloud sessions have their own sandbox; the same no-secrets rules apply.
