# FCU mobile app (Flutter)

Two Claude agents build this app at the same time. **Before any work, read `docs/collaboration.md`.** It covers who owns which screens, how to claim work, the git rules and the quality bar. It overrides older briefs on process.

Key rules (details in that file):
- Use your own working folder (a separate clone or `git worktree`); never share a folder with the other agent.
- `git pull --rebase origin main` before starting, before editing shared files, and before pushing.
- Stage files by explicit path. Never use `git add -u`, `git add .` or `git add -A`.
- New files under `mobile/lib` need `git add -f` until the root `.gitignore` `lib/` rule is fixed. `git status --short --ignored mobile/lib` must print nothing before you push.
- Never push to `main` unless `flutter analyze` shows 0 issues and `flutter test` is green.
- Flutter: `F:\flutter_windows_3.50.0-stable\flutter\bin\flutter.bat`, with `PUB_CACHE=F:/.pub-cache`.
