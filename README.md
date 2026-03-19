# agent-skills

A collection of agent skills for AI coding assistants. Skills are packaged
instructions that extend agent capabilities with domain-specific knowledge and
patterns.

Skills follow the [Agent Skills](https://agentskills.io/) format and work with
Claude Code, Cursor, Copilot, and other AI coding agents.

## Available Skills

### functional-typescript

Helps write idiomatic functional TypeScript and JavaScript. Covers closures,
partial application, currying, pure functions, immutability, higher-order
functions, function composition, and the module pattern — grounded in *You
Don't Know JS Yet* foundations with TypeScript type system coverage.

**Use when:**
- Writing functional-style TypeScript or JavaScript
- Typing higher-order functions, curried functions, or generics
- Structuring code with the module pattern
- Avoiding mutation and side effects
- Understanding closures and scope

## Skill Structure

Each skill lives under `skills/` and follows this layout:

```
skills/
  {skill-name}/
    SKILL.md          # Required: metadata + instructions
    references/       # Optional: detailed reference docs
    scripts/          # Optional: executable helper scripts
```

## Installation

```bash
npx skills add https://github.com/mshindi-labs/agent-skills --skill <skill>
```

Or manually copy a skill directory into your agent's skills folder.

## License

MIT
