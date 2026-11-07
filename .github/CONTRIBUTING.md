# Contributing to Curiosity

Thank you for your interest in contributing. This guide covers how to set up the
project and submit changes.

## Getting Started

1. Fork the repository and clone your fork.
2. Set up the backend and frontend by following the
   [Getting Started](../README.md#getting-started) section of the README.
3. Create a branch from `main`:

   ```bash
   git checkout -b feat/short-description
   ```

## Development Guidelines

- **State management:** use Riverpod notifiers. Keep widgets thin.
- **I/O:** keep network and storage code in `lib/services/` or `server/services/`.
- **Backend:** validate all input with Pydantic models and return typed error
  messages over the WebSocket.
- **Secrets:** never commit API keys or `.env` files.

## Before You Commit

Run the checks that apply to your change:

```bash
# Flutter
flutter analyze
flutter test

# Backend
cd server
python -m compileall .
```

## Commit Messages

This project uses [Conventional Commits](https://www.conventionalcommits.org).

| Type | Use for |
| --- | --- |
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `chore` | Tooling, dependencies, configuration |

Examples:

```bash
git commit -m "feat(chat): add source count to sources pill"
git commit -m "fix(ws): fail in-flight turns on disconnect"
```

## Pull Requests

1. Keep each pull request focused on one change.
2. Fill in the pull request template.
3. Include screenshots for any UI change.
4. Link the related issue, if there is one.

For substantial changes, open an issue first so the approach can be discussed
before you invest time in the implementation.

## Reporting Bugs and Requesting Features

Use the issue templates. For security problems, do not open a public issue.
See [SECURITY.md](SECURITY.md).
