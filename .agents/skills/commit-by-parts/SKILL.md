---
name: commit-by-parts
description: Split uncommitted changes into a sequence of atomic commits, each following Conventional Commits v1.0.0 with a bullet-list body.
whenToUse: Use when the working tree holds changes that belong in several focused commits, or when the user asks to commit by parts, split the commit, or "commit this in pieces".
---

# Commit by parts

Turn the current changes into a sequence of small, self-contained commits. Every commit carries exactly one logical change and a message that follows [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/). Never bundle unrelated work into one commit, and leave no uncommitted change behind (apart from files that are ignored or the user told you to leave out).

## 1. Survey the changes

Inspect everything before staging anything:

```bash
git status --short
git diff            # unstaged changes
git diff --cached   # already-staged changes
```

Read enough of the changed files to understand intent, not just the diff. Untracked files that `git status` lists separately are part of the work too. If there is nothing to commit, say so and stop; do not invent an empty commit.

## 2. Plan the parts

Group the changes by intent, then order the commits so each one builds and tests on its own:

1. Refactors and groundwork first.
2. Bug fixes before features that depend on them.
3. Tests next to the code they pin down.
4. Docs, build, CI, and chore commits last.

A single file may contain more than one part; split its hunks rather than mislabeling the commit. If the grouping is genuinely ambiguous because the user's intent is unclear, ask one short question instead of guessing. Proceed without asking when the intent is obvious from the diff.

## 3. Stage exactly one part

- Per file: `git add -- <path> ...`, enumerating paths explicitly.
- Mixed file: stage hunks with `git add -p <file>` (or `git apply --cached` from a filtered `git diff`), so the commit contains only that part's lines.
- Never run `git add -A` or `git add .` blindly, and never stage files you did not inspect.
- Check what is staged before committing: `git diff --cached --stat` and `git diff --cached`.

## 4. Write the message

Use this structure:

```
<type>[(scope)][!]: <description>

- <what changed, or why>
- <what changed, or why>

[<footer-token>: <value>]
[BREAKING CHANGE: <migration impact>]
```

### Subject line

- One `type` in lowercase: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, or `revert`. A project that documents extra types (for example in `commitlint.config.*` or `CONTRIBUTING.md`) may use those; check first.
- Optional `scope`: a noun naming the section of the codebase, in parentheses, kebab-case, e.g. `fix(es_reproduction): ...`. Omit it when the change spans the whole project.
- `!` immediately before the colon when the commit introduces a breaking change, e.g. `feat(api)!: drop the legacy endpoint`.
- `description`: imperative mood ("add", not "added" or "adds"), lowercase first word, no trailing period, at most 72 characters, and specific about what changed.
- Exactly one type per commit. When a change seems to fit two, split the change instead of choosing the lesser label.

### Body: a bullet list

- Separate the body from the subject with exactly one blank line.
- Write the body as a Markdown bullet list: every entry starts on its own line with `- `.
- One bullet per concrete change, or per reason/impact when the change is not self-explanatory (why the fix is correct, why the refactor was needed, what the new option enables).
- Wrap bullets at roughly 72 columns; align continuation lines with the text after `- `.
- Use one to six bullets. More than that is a signal to split the commit further.
- No headings or footers inside the body. Reference files and symbols in backticks.
- Omit the body only when a single self-evident change is fully described by the subject.

### Footers

- Separate footers from the body with one blank line.
- Format each footer as `Token: value` or `Token #value`.
- A token uses `-` in place of spaces, e.g. `Reviewed-by`, `Co-authored-by`, `Refs`, `Fixes`. The exception is the uppercase token `BREAKING CHANGE` (or the synonymous `BREAKING-CHANGE`).
- Record a breaking change both in the prefix (`!`) and, when the impact needs explaining, as a `BREAKING CHANGE: <description>` footer.
- Reference issues with `Refs: #123` or `Fixes: #123`.

### Commit

Pass the message through a heredoc so the bullets and blank lines land exactly as written:

```bash
git commit -F - <<'EOF'
fix(es_reproduction): guard against empty population

- Reject zero-length sampling populations before the update step
- Return the unchanged parameters instead of raising on an empty batch

Fixes: #123
EOF
```

If a pre-commit hook fails, fix the cause, re-stage, and retry. Do not use `--no-verify` unless the user explicitly asks for it.

## 5. Verify each commit

After every commit, confirm it contains only that part:

```bash
git show --stat --oneline HEAD
git diff HEAD~1 --stat   # same thing, spelled out
```

At the end:

- `git status --short` shows nothing pending except ignored files or paths the user asked to leave alone.
- `git log --oneline -n <number-of-parts>` matches the planned sequence.
- Report the resulting commits, in order, with their subjects.

## Rules

- Never push, amend, rebase, tag, or rewrite history unless the user explicitly asks.
- Never commit secrets or credentials, generated artifacts, or files matched by `.gitignore`.
- Never revert, stash, or "clean up" changes the user did not ask about.
- Do not create a commit for a change that is already committed, and do not duplicate content across two parts.
- If the tree turns out to hold a single logical change, one well-formed commit is the correct answer: "by parts" means atomic, not artificially numerous.

## Examples

```text
feat(es_reproduction): add checkpoint resume support

- Load the latest optimizer and scheduler state when `resume_from` is set
- Skip already-finished steps instead of replaying them
- Log the resumed step count at startup

Refs: #42
```

```text
refactor: extract noise sampling from the update loop

- Move perturber construction into `build_perturber`
- Keep the update loop focused on scoring and parameter updates
```

```text
feat(configs)!: require an explicit estimator in every config

- Replace the implicit default with a mandatory `estimator` field
- Report a clear error when a config omits it

BREAKING CHANGE: configs without an `estimator` key now fail to load; add `estimator: antithetic` or the value you intend to use.
```
