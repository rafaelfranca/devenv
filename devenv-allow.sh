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
    rm -f "$input_file" || {
      print -u2 'devenv-allow: cannot remove the temporary input configuration'
      return 1
    }
  fi

  (( result == 0 )) || return $result

  local git_state
  if ! git_state="$(LC_ALL=C git rev-parse --is-inside-work-tree 2>&1)"; then
    if [[ -n "${1-}" && "$git_state" == 'fatal: not a git repository (or any of the parent directories): .git'* ]]; then
      return 0
    fi
    print -u2 "devenv-allow: cannot inspect Git working tree: $git_state"
    return 1
  fi
  if [[ "$git_state" != true ]]; then
    print -u2 'devenv-allow: cannot add excludes outside a Git working tree'
    return 1
  fi

  local prefix exclude
  prefix="$(git rev-parse --show-prefix)" && exclude="$(git rev-parse --git-path info/exclude)" || {
    print -u2 'devenv-allow: cannot locate the Git exclude file'
    return 1
  }
  if [[ "$prefix" == *$'\n'* ]]; then
    print -u2 'devenv-allow: cannot exclude a directory whose name contains a newline'
    return 1
  fi

  # Anchor the patterns to this directory, escaping its literal Git wildcards.
  local escaped_prefix='' char rule last output=''
  local -i i
  for (( i = 1; i <= ${#prefix}; i++ )); do
    char="${prefix[i]}"
    case "$char" in
      ('\'|'*'|'?'|'[') escaped_prefix+="\\$char" ;;
      (*) escaped_prefix+="$char" ;;
    esac
  done

  local -a missing=()
  for rule in "/${escaped_prefix}.devenv*" "/${escaped_prefix}devenv.lock"; do
    if [[ -e "$exclude" ]]; then
      if grep -Fqx -- "$rule" "$exclude"; then
        continue
      else
        result=$?
      fi
      if (( result != 1 )); then
        print -u2 "devenv-allow: cannot read Git exclude file: $exclude"
        return 1
      fi
    fi
    missing+=("$rule")
  done

  if (( ${#missing} )); then
    if [[ -s "$exclude" ]]; then
      last="$(tail -c 1 "$exclude")" || {
        print -u2 "devenv-allow: cannot read Git exclude file: $exclude"
        return 1
      }
      [[ -n "$last" ]] && output=$'\n'
    fi
    for rule in "${missing[@]}"; do
      output+="${rule}"$'\n'
    done
    mkdir -p "${exclude:h}" && printf '%s' "$output" >> "$exclude" || {
      print -u2 "devenv-allow: cannot update Git exclude file: $exclude"
      return 1
    }
  fi

  return 0
}
