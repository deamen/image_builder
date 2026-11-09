#!/bin/bash
# Clone deamen/dotclaude into ~/.claude. The image build already creates ~/.claude (the Claude Code
# installer writes ~/.claude/downloads), so `gh repo clone` cannot be used there. Instead, initialise
# the existing directory as a clone and check out origin/master. Untracked files that the dotclaude
# tree would overwrite are moved to ~/.claude/backups, which is not tracked.
set -euo pipefail

REPO=deamen/dotclaude
URL=https://github.com/${REPO}.git
TARGET="$HOME/.claude"

if [ ! -d "$TARGET/.git" ]; then
    if [ -z "$(ls -A "$TARGET" 2>/dev/null)" ]; then
        exec gh repo clone "$REPO" "$TARGET"
    fi
    git -C "$TARGET" init -q -b master
    git -C "$TARGET" remote add origin "$URL"
fi

if [ "$(git -C "$TARGET" config --get remote.origin.url)" != "$URL" ]; then
    echo "$TARGET is a git repository with another origin: $(git -C "$TARGET" config --get remote.origin.url)" >&2
    exit 1
fi

git -C "$TARGET" fetch --quiet origin master

if git -C "$TARGET" rev-parse --verify --quiet HEAD >/dev/null; then
    # Already a clone: fast-forward only, so local commits are never discarded
    git -C "$TARGET" merge --ff-only --quiet origin/master
else
    BACKUP="$TARGET/backups/dotclaude-$(date +%Y%m%d%H%M%S)"
    git -C "$TARGET" ls-tree -r --name-only origin/master | while IFS= read -r path; do
        if [ -e "$TARGET/$path" ] && ! git -C "$TARGET" ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
            mkdir -p "$BACKUP/$(dirname "$path")"
            mv "$TARGET/$path" "$BACKUP/$path"
            echo "Moved existing $path to $BACKUP/$path"
        fi
    done
    git -C "$TARGET" checkout -q -B master origin/master
fi

git -C "$TARGET" branch --quiet --set-upstream-to=origin/master master
echo "dotclaude is at $(git -C "$TARGET" rev-parse --short HEAD) in $TARGET"
