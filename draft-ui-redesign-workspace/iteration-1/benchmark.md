# Benchmark: draft-ui-redesign — iteration 1

| Configuration | Pass rate   | Time (s) | Tokens           |
| ------------- | ----------- | -------- | ---------------- |
| with_skill    | 1.00 ± 0.00 | 150 ± 29 | 242,139 ± 44,718 |
| without_skill | 0.61 ± 0.19 | 103 ± 26 | 128,887 ± 8,150  |

**Delta:** pass rate +0.39 · time +47s · tokens +113,253

## Per eval

| Eval                 | with_skill | without_skill |
| -------------------- | ---------- | ------------- |
| fintech-transactions | 6/6        | 3/6           |
| issues-list          | 6/6        | 5/6           |
| deployments-page     | 6/6        | 3/6           |

## Notes

- Executor runs were isolated `claude -p` subprocesses, one fresh context per run.
- with_skill injected SKILL.md plus both reference files as a preamble; without_skill received the raw prompt only.
- Baselines inherited the session's ambient frontend-design plugin skill, so without_skill is a strong baseline rather than a naive one.
- Graded inline against evals.json assertions by claude-opus-5.
