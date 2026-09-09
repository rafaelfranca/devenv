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
