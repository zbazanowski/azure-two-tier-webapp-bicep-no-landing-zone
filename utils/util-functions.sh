#!/usr/bin/env bash

save-variables() {
    (
        for var in "$@"; do
            printf 'export %s="%s"\n' "$var" "${!var}"
        done
        echo
    ) >> ${DEPLOYMENT_PARAMS_CONFIG}
}




split() {
  titles=()
  commands=()

  local title=""
  local cmd=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    # If it's a title line: emit previous block (if any), then start a new one
    if [[ "$line" =~ ^[[:space:]]*#(.*)$ ]]; then
      # emit previous
      if [[ -n "$title" || -n "$cmd" ]]; then
        titles+=("$title")
        commands+=("$cmd")
        cmd=""
      fi
      # capture trimmed title text
      title="${BASH_REMATCH[1]}"
      title="${title#"${title%%[![:space:]]*}"}"   # ltrim
      title="${title%"${title##*[![:space:]]}"}"   # rtrim
      continue
    fi

    # Skip blank lines before the first command line of a block
    if [[ -z "${line//[[:space:]]/}" && -z "$cmd" ]]; then
      continue
    fi

    # Accumulate command lines, preserving newlines
    if [[ -n "$cmd" ]]; then
      cmd+=$'\n'"$line"
    else
      cmd="$line"
    fi
  done

  # Emit the last block
  if [[ -n "$title" || -n "$cmd" ]]; then
    titles+=("$title")
    commands+=("$cmd")
  fi
}
