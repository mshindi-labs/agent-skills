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
functions, function composition, and the module pattern — grounded in _You
Don't Know JS Yet_ foundations with TypeScript type system coverage.

**Use when:**

- Writing functional-style TypeScript or JavaScript
- Typing higher-order functions, curried functions, or generics
- Structuring code with the module pattern
- Avoiding mutation and side effects
- Understanding closures and scope

### draft-ui-redesign

Turns an existing page into a paste-ready prompt for a design tool (Claude
Design, Stitch, v0, Lovable, Figma Make). Reads the component code and the API
response that feeds it, audits every data point and interaction, benchmarks
against the industry leaders for that product domain, and specs any new data as
additive, non-breaking APIs. Presentation only — it never changes logic.

**Use when:**

- Redesigning or modernizing a page that already works
- Writing a design brief or generation prompt for a design tool
- A page looks dated and you want it to feel like Linear, Stripe, or Vercel
- You need new data points specced without breaking existing API consumers

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
