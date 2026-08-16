#!/bin/sh
# Link every skill in skills/ into the agent skill directories so the repo
# dogfoods its own skills — without this, nothing in skills/ is discoverable
# and no description, however good, will trigger.
#
# Symlinks rather than copies: copies drift, which is why awesome-utils was
# deleted. Re-run after adding or renaming a skill.
#
# Usage: ./scripts/link-skills.sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

AGENT_DIRS=".claude/skills .agents/skills .agent/skills .windsurf/skills"

for dir in $AGENT_DIRS; do
  mkdir -p "$dir"
  # Drop stale links to skills/ only — leave real directories (e.g. the
  # vendored skill-creator) and links pointing elsewhere untouched.
  for link in "$dir"/*; do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in
      *"/skills/"*) [ -e "$link" ] || rm -f "$link" ;;
    esac
  done

  for skill in skills/*/; do
    name=$(basename "$skill")
    target="$dir/$name"
    [ -d "$skill" ] || continue
    # Never shadow a real directory already sitting in the agent dir.
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "skip $target (real directory, not replacing)" >&2
      continue
    fi
    rm -f "$target"
    ln -s "../../skills/$name" "$target"
  done
  echo "$dir: $(find "$dir" -maxdepth 1 -type l | wc -l | tr -d ' ') linked"
done
