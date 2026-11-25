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
7. Adds local Git exclude rules for `.devenv*` and `devenv.lock` if the directory is in a Git repository.

The helper does not change an existing `devenv.yaml` in the target repository.

The exclude rules apply to the local repository and its linked worktrees. They do not affect files that Git already tracks.

## GlobalID

The GlobalID environment uses Ruby 4.0.6 and stores installed gems in the devenv state directory. Its setup task installs the locked dependencies without changing `Gemfile.lock`.

Run these commands in the GlobalID checkout after you install `devenv-allow`:

```zsh
devenv-allow
devenv tasks run globalid:setup
```

## Thor

The Thor environment uses Ruby 4.0.6 and stores installed gems in the devenv state directory.

Run these commands in the Thor checkout after you install `devenv-allow`:

```zsh
devenv-allow
devenv tasks run thor:setup
devenv shell -- bundle exec thor spec
devenv shell -- bundle exec rubocop
```

## Repository layout

Add a target configuration at `<org>/<repo>`:

```text
<org>/<repo>/devenv.nix
<org>/<repo>/devenv.yaml   # optional
```

The target repository must have a `devenv.nix` file. The helper refuses paths that contain more than one slash, paths that start with `/`, and paths that end with `/`.

## Roundhouse

The `rubys/roundhouse` configuration includes `libyaml` and `pkg-config`. Bundler uses them to build the native extension for `psych`.

It also includes:

- `libclang`, with `LIBCLANG_PATH` set. Bindgen needs it to build `ruby-rbs-sys` and `ruby-prism-sys`.
- `vips`, with its library directory on `LD_LIBRARY_PATH`. The `ruby-vips` gem loads `libvips.so.42` at runtime.

Run `devenv tasks run roundhouse:gems` to install the gems that Roundhouse's CI unit job installs for emitted-Ruby tests: `rails-html-sanitizer`, `sqlite3`, `bcrypt`, `rack`, `ruby-vips`, `markly`, and Active Record 8.1. The task does nothing once every one of them loads.
