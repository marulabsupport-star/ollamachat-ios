#!/bin/bash
cd /Users/jasonkim/.openclaw/workspace/OllamaChat-iOS
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "auto-backup: $(date '+%Y-%m-%d %H:%M')"
  git push origin main
fi