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

Add this function to `~/.zshrc`:

```zsh
devenv-allow() {
  if (( $# > 1 )); then
    print -u2 'usage: devenv-allow [org/repo]'
    return 2
  fi

  local repo="${1-}"
  if [[ -z "$repo" ]]; then
    local remote
    remote="$(git remote get-url origin 2>/dev/null)" || {
      print -u2 'devenv-allow: cannot read origin; pass org/repo explicitly'
      return 1
    }

    case "$remote" in
      (https://github.com/*) repo="${remote#https://github.com/}" ;;
      (git@github.com:*) repo="${remote#git@github.com:}" ;;
      (ssh://git@github.com/*) repo="${remote#ssh://git@github.com/}" ;;
      (*)
        print -u2 'devenv-allow: origin is not on GitHub; pass org/repo explicitly'
        return 1
        ;;
    esac

    repo="${repo%.git}"
  fi

  if [[ "$repo" != */* || "$repo" == */*/* || "$repo" == /* || "$repo" == */ ]]; then
    print -u2 'usage: devenv-allow [org/repo]'
    return 2
  fi

  local devenv_root="$HOME/src/github.com/rafaelfranca/devenv"
  local devenv_origin="https://github.com/rafaelfranca/devenv.git"

  if [[ -e "$devenv_root" && ! -d "$devenv_root/.git" ]]; then
    print -u2 "devenv-allow: $devenv_root is not a Git repository"
    return 1
  fi

  if [[ ! -d "$devenv_root/.git" ]]; then
    mkdir -p "$HOME/src/github.com/rafaelfranca" || {
      print -u2 'devenv-allow: cannot create the local repository parent'
      return 1
    }
    git clone --branch main --single-branch "$devenv_origin" "$devenv_root" || {
      print -u2 'devenv-allow: cannot clone the central repository'
      return 1
    }
  else
    if [[ -n "$(git -C "$devenv_root" status --porcelain 2>/dev/null)" ]]; then
      print -u2 'devenv-allow: local central repository has changes; refusing to update'
      return 1
    fi

    git -C "$devenv_root" switch --quiet main || {
      print -u2 'devenv-allow: cannot switch the central repository to main'
      return 1
    }
    git -C "$devenv_root" fetch --quiet origin main || {
      print -u2 'devenv-allow: cannot fetch the central repository'
      return 1
    }
    git -C "$devenv_root" merge --ff-only --quiet origin/main || {
      print -u2 'devenv-allow: central repository is not a fast-forward update'
      return 1
    }
  fi

  local source="$devenv_root/$repo"
  if [[ ! -f "$source/devenv.nix" ]]; then
    print -u2 "devenv-allow: no devenv.nix exists at $repo"
    return 1
  fi

  local input_file="$PWD/devenv.yaml"
  local remove_input=false
  if [[ ! -e "$input_file" && -f "$source/devenv.yaml" ]]; then
    cp "$source/devenv.yaml" "$input_file" || {
      print -u2 'devenv-allow: cannot stage the central input configuration'
      return 1
    }
    remove_input=true
  fi

  local result
  devenv allow --from "path:$source"
  result=$?

  if [[ "$remove_input" == true ]]; then
    rm -f "$input_file"
  fi

  return $result
}
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
