# agent-skills

43 agent skills for AI coding assistants — code review, debugging, git and release
workflow, testing, codebase orientation, and project setup.

A skill is a packaged set of instructions your agent loads when the task matches.
Instead of re-explaining how you want a migration reviewed or a commit written, you
install the skill once and the agent picks it up on its own from what you asked for.

Skills follow the [Agent Skills](https://agentskills.io/) format and work with Claude
Code, Cursor, Windsurf, Copilot, and other agents that read `SKILL.md` files.

---

## Installation

### Install everything

```bash
npx skills add mshindi-labs/agent-skills --all
```

`--all` is shorthand for `--skill '*' --agent '*' -y`: every skill in this repo,
wired into every agent directory it detects, no prompts.

Add `-g` to install for your user account instead of the current project:

```bash
npx skills add mshindi-labs/agent-skills --all -g
```

### Install one skill, or a few

```bash
npx skills add mshindi-labs/agent-skills --skill review-changes
npx skills add mshindi-labs/agent-skills --skill review-auth,review-migration,check-query-safety
```

List what is available without installing anything:

```bash
npx skills add mshindi-labs/agent-skills --list
```

### Target specific agents

By default the installer detects the agents on your machine and wires the skills into
each one. Pass `--agent` to narrow that to specific agents, or `'*'` for all of them:

```bash
npx skills add mshindi-labs/agent-skills --all --agent '*'
```

Installs symlink by default so `npx skills update` keeps them current. Pass `--copy`
if you would rather have independent copies that never move under you.

### Try one without installing

```bash
npx skills use mshindi-labs/agent-skills@review-changes
```

Prints the skill as a prompt you can paste into any agent.

### Manual install

Skills are plain directories — copying one in works fine:

```bash
git clone https://github.com/mshindi-labs/agent-skills
cp -r agent-skills/skills/review-changes ~/.claude/skills/
```

For all of them at once, into any agent's skills directory:

```bash
cp -r agent-skills/skills/* ~/.claude/skills/
```

### Updating

```bash
npx skills update              # everything
npx skills update review-auth  # one skill
npx skills list                # what you have installed
npx skills remove review-auth  # uninstall
```

---

## Using the skills

You do not invoke a skill by name. Ask for the work in your own words and the agent
matches your request against the installed descriptions:

| You say                                          | Skill that fires   |
| ------------------------------------------------ | ------------------ |
| "review my changes before I push"                | `review-changes`   |
| "is this migration safe to run in production?"   | `review-migration` |
| "did I commit an API key?"                       | `audit-secrets`    |
| "prod is throwing 500s, what's the blast radius" | `triage-error`     |
| "ship this to main"                              | `create-pr`        |
| "I'm new here, where do I start"                 | `onboard-codebase` |

Naming a skill directly (`use review-auth on this file`) works too, and is worth doing
when you want the deep pass rather than whatever the agent judged to be closest.

**Related skills know their boundaries.** `review-changes` is the generalist: it
flags auth, migration, and query issues in passing and then hands the deep pass to
`review-auth`, `review-migration`, or `check-query-safety`. Each skill's description
says what it owns and which sibling to prefer, so overlapping requests land in the
right place instead of the first match.

---

## The skills

### Review and audit

| Skill                | What it does                                                                                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `review-changes`     | Reviews a diff like an experienced teammate — highest-risk issues first, no leading praise. The generalist; hands deep passes to the three specialists below.       |
| `review-auth`        | Audits authentication and authorization paths for bypasses, missing ownership checks, and IDOR.                                                                     |
| `review-migration`   | Analyzes a schema migration for data-loss, locking, reversibility, and backfill risk before it runs in production. Names the actual lock type each operation takes. |
| `check-query-safety` | Finds N+1 patterns, unbounded scans, SQL injection, over-fetching, and missing transaction boundaries in application queries.                                       |
| `audit-secrets`      | Scans the working tree **and git history** for committed credentials — including secrets that survive after the file was deleted. Always says rotate, not delete.   |
| `audit-dependencies` | Reports CVEs, badly outdated packages, license risk, and genuinely unused dependencies. Read-only — pair with `upgrade-dependencies` to act on it.                  |

### Debugging and incidents

| Skill               | What it does                                                                                                              |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `debug-issue`       | Works a dev-time bug from evidence to ranked hypotheses to the safest minimal fix.                                        |
| `triage-error`      | Live production error or page: locates the fault site, assesses blast radius, recommends a mitigation path.               |
| `triage-ci-failure` | Reads failing CI logs, classifies the failure, maps it to a local reproduction command, recommends the smallest safe fix. |
| `fix-failing-test`  | Gets one red test green by working out whether the test, the code, or both are wrong — without weakening assertions.      |

### Testing

| Skill               | What it does                                                                                                |
| ------------------- | ----------------------------------------------------------------------------------------------------------- |
| `add-test-coverage` | Writes tests for high-risk untested paths, runs them, and verifies they fail when the behaviour breaks.     |
| `add-missing-tests` | Read-only counterpart: reports what is untested and proposes the most valuable tests, without writing them. |
| `seed-test-data`    | Generates realistic fixtures and factory functions for a model, following the project's existing patterns.  |

### Git, PRs, and releases

| Skill                     | What it does                                                                                                        |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `commit-changes`          | One clean Conventional Commit — explicit staging, validated message, no AI attribution.                             |
| `amend-safely`            | Fixes the last commit's message or contents, with guardrails against rewriting history that has already shipped.    |
| `run-pre-pr-checks`       | Runs the project's real format/lint/typecheck/test scripts and reports a PASS/FAIL gate.                            |
| `create-pr`               | Opens a PR to any target branch — validates state, commits pending work, pushes, writes the body.                   |
| `address-pr-review`       | Triages review comments, applies the changes, writes follow-up commits, and drafts the re-review summary.           |
| `resolve-merge-conflicts` | Resolves conflict markers by understanding both sides' intent, never silently dropping work.                        |
| `sync-branch-safely`      | Syncs a branch with its remote or base, stopping on anything ambiguous instead of defaulting to destructive.        |
| `clean-branch`            | Finds stale local branches and confirms the list with you before deleting anything.                                 |
| `revert-change-safely`    | Backs out a pushed or merged change, assessing blast radius first.                                                  |
| `ship-release-candidate`  | Cuts an RC PR to main: checks conflicts, infers the version bump from commit history, drafts release-focused notes. |
| `hotfix-release`          | Emergency fix on a release line — correct base tag, minimal change, merge-back plan for every affected branch.      |
| `prepare-release-notes`   | Turns a commit range into release notes grouped by user impact, with breaking changes and upgrade steps called out. |

### Understanding a codebase

| Skill                   | What it does                                                                                                   |
| ----------------------- | -------------------------------------------------------------------------------------------------------------- |
| `onboard-codebase`      | Whole-repo orientation: entry points, architecture layers, conventions, test strategy, local gotchas.          |
| `explain-flow`          | Narrative end-to-end trace of one feature, endpoint, or job, grounded in the real execution path.              |
| `locate-implementation` | Answers "where is X handled" with a scannable map of definitions, registrations, and related types — no prose. |
| `map-dependencies`      | Inbound/outbound import map for a module, flagging cycles, tight coupling, god-modules, and orphaned code.     |

### Planning and scaffolding

| Skill              | What it does                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------- |
| `plan-change`      | Implementation-ready plan before any code: scope, options, recommendation, phases, risks, verification. |
| `scaffold-feature` | Skeleton files for a new feature that match the project's existing conventions.                         |
| `draft-adr`        | Captures a technical decision as a durable ADR — context, options considered, decision, consequences.   |

### Code quality

| Skill                   | What it does                                                                                      |
| ----------------------- | ------------------------------------------------------------------------------------------------- |
| `refactor-safely`       | Restructures code in small verified increments with behaviour preserved at every step.            |
| `fix-any-types`         | Replaces every `any` in a TypeScript file with a correct narrow type inferred from actual usage.  |
| `functional-typescript` | Functional patterns for TS/JS: closures, currying, immutability, composition, the module pattern. |

### Project setup and CI

| Skill                            | What it does                                                                                              |
| -------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `setup-env`                      | Generates a fillable `.env.stub` for what your local setup is missing, and checks `.gitignore` covers it. |
| `align-env-checklist`            | Verifies every env var the code reads is documented, validated, and that no real `.env` is tracked.       |
| `improve-getting-started`        | Closes the gap between what the README claims and what actually works for a new contributor.              |
| `setup-commit-hooks-and-release` | Wires up Husky, commitlint, lint-staged, semantic-release, and the GitHub Actions release workflow.       |
| `check-ci-health`                | Inspects CI config for trigger misconfigurations, security risks, caching gaps, and slow paths.           |

### Dependencies and design

| Skill                  | What it does                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ |
| `upgrade-dependencies` | Plans and executes version bumps in risk-tiered batches, reading changelogs and verifying checks after each. |
| `draft-ui-redesign`    | Turns an existing page into a paste-ready prompt for a design tool. Presentation only — never changes logic. |

### Meta

| Skill           | What it does                                                                                       |
| --------------- | -------------------------------------------------------------------------------------------------- |
| `skill-creator` | Creates, improves, and measures skills — including running eval suites and description benchmarks. |

---

## Skill structure

Each skill is a self-contained directory:

```
skills/
  {skill-name}/
    SKILL.md          # Required: frontmatter (name, description) + instructions
    references/       # Optional: deep reference docs, loaded on demand
    scripts/          # Optional: executable helpers
    evals/            # Optional: eval suite for this skill
      evals.json
      fixtures/
```

The `description` in the frontmatter is what makes a skill trigger. It carries the
trigger phrases a user would actually type and a boundary clause naming the sibling
skill to prefer when a request sits between two of them.

See [AGENTS.md](AGENTS.md) for authoring conventions, packaging, and validation.

---

## Evals

Skills that make judgement calls carry an eval suite under `skills/{name}/evals/`.
Each eval runs twice — with the skill and without it — and the delta between the two
arms is the measurement. Ten suites exist today; the six detection skills
(`review-changes`, `review-auth`, `review-migration`, `check-query-safety`,
`audit-dependencies`, `audit-secrets`) have three evals each.

Two rules matter enough to repeat here, both covered in
[AGENTS.md](AGENTS.md#running-skill-evals):

- **Run every arm in a `mktemp -d` sandbox outside this repo.** Working inside the
  repo lets a baseline arm load the very skill it is supposed to be blind to.
- **Assert on what the skill adds, not on what the model already does.** An assertion
  both arms pass measures the model. `skills/review-auth/evals/evals.json` is the
  reference suite.

The most recent run is recorded in `detection-skills-benchmark.json`, including the
caveats that apply to it.

---

## Developing in this repo

```bash
npm install                 # commitlint, husky, prettier, semantic-release
./scripts/link-skills.sh    # symlink skills/ into the agent dirs so the repo dogfoods itself
```

Re-run `link-skills.sh` after adding or renaming a skill. Commits follow
[Conventional Commits](https://www.conventionalcommits.org/) — commitlint enforces it
on the way in, and semantic-release derives the version and changelog from it.

Vendored skills (`skills/skill-creator`) keep their original upstream license.
