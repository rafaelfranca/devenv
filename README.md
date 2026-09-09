# devenv configurations

This repository stores shared [devenv](https://devenv.sh/) configurations for GitHub repositories.

Each configuration uses the GitHub path of its target repository. For example:

```text
rails/rails/devenv.nix
rails/rails/devenv.yaml
```

The configuration above applies to `rails/rails`.

## Requirements

Install these tools before you use the helper:

- [Git](https://git-scm.com/)
- [devenv](https://devenv.sh/)
- Z shell (`zsh`)

The helper stores a local copy of this repository at:

```text
$HOME/src/github.com/rafaelfranca/devenv
```

## Install `devenv-allow`

Add this line to `~/.zshrc`:

```zsh
source "$HOME/src/github.com/rafaelfranca/devenv/devenv-allow.sh"
```

Reload the function in the current shell:

```zsh
source ~/.zshrc
```

## Use `devenv-allow`

Run the helper from a target repository:

```zsh
cd ~/src/github.com/rails/rails
devenv-allow
```

With no argument, the helper reads the target repository's `origin` remote. It accepts these GitHub remote forms:

- `https://github.com/org/repo.git`
- `git@github.com:org/repo.git`
- `ssh://git@github.com/org/repo.git`

You can pass the repository path explicitly:

```zsh
devenv-allow rails/rails
```

The helper then:

1. Clones the central repository if it does not exist locally.
2. Updates an existing clean checkout with a fast-forward-only merge.
3. Loads `$HOME/src/github.com/rafaelfranca/devenv/org/repo/devenv.nix`.
4. Copies `devenv.yaml` temporarily when the central configuration provides one.
5. Runs `devenv allow --from path:<configuration-path>`.
6. Removes the temporary `devenv.yaml` after `devenv allow` finishes.

The helper does not change an existing `devenv.yaml` in the target repository.

## Repository layout

Add a target configuration at `<org>/<repo>`:

```text
<org>/<repo>/devenv.nix
<org>/<repo>/devenv.yaml   # optional
```

The target repository must have a `devenv.nix` file. The helper refuses paths that contain more than one slash, paths that start with `/`, and paths that end with `/`.
