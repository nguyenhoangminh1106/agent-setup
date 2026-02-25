# agent-setup

A **single-source-of-truth** repository for AI agent skills shared across:

* Claude Code
* Codex CLI
* Cursor

No duplication. No copy–paste. One skill = one file.

---

## Philosophy

* Safety > cleverness
* Consistency > refactor
* Minimal diff > ideal design
* Read-only review unless explicitly allowed

---

## Skills

### `commit-push`

Used by **Claude Code + Cursor**

* Syncs branch before pushing (fetch + rebase)
* Creates one clean commit (no co-authored trailers)
* Fixes Husky errors only (ignores warnings)
* Pushes current branch
* Prints PR URL or create-PR link

---

### `pr-triage`

Used by **Codex + Cursor**

* Read-only PR review-thread triage
* Bot comments (STYLE / FALSE-ALARM): auto reply + resolve
* Human comments: report only
* Produces handoff plan, never edits code

---

### `branch-risk-review`

Used by **Codex + Cursor**

* Conservative, risk-first diff review
* Ensures no existing logic is broken
* Enforces consistency with current code style
* Prefers containment and minimal change
* Report-only

---

## Install (any machine)

```bash
git clone https://github.com/nguyenhoangminh1106/agent-setup.git
cd agent-setup
./install.sh
```

---

## Usage

### Claude Code

```
/user:commit-push
```

### Codex

```bash
codex pr-triage --pr <PR_URL_OR_NUMBER>
codex branch-risk-review --target <BRANCH_OR_PR_URL>
```

### Cursor

Use commands normally from the command palette.

---

## Updating

Edit files in `skills/`, then:

```bash
git add -A
git commit -m "Update skills"
git push
```

On other machines:

```bash
git pull
./install.sh
```

---

## License

MIT
