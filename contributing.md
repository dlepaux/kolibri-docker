# Contributing

Thanks for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch: `git checkout -b feat/my-feature`
4. Make your changes

## Development

```bash
docker build -t kolibri:dev .
docker run -p 8080:8080 kolibri:dev
```

## Commit Messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — maintenance

## Pull Requests

- Keep PRs focused — one change per PR
- Include a clear description of what changed and why

## Reporting Issues

Open a GitHub issue with:

- What you expected to happen
- What actually happened
- Steps to reproduce
- Environment details (OS, Docker version, architecture)

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](license.md).
