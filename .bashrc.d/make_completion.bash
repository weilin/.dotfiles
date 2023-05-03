#!/usr/bin/env bash

set -euo pipefail

PRINT_DEBUG=${PRINT_DEBUG:-}

_roku_make_in_os() {
  test -f config/config.mk
}

_roku_make_above_os() {
  test -f os/config/config.mk && test -d port
}

_roku_make_in_platform() {
  grep -E "include.+prep_proj.mk" Makefile 2>/dev/null 1>&2
}

_roku_make_need_cd_os() {
  # A more strict test would also look for the target directory,
  # but we have the intention already.
  _roku_make_above_os && ! _roku_make_elementIn "-C" "${COMP_WORDS[@]}"
}

if [ "$(uname)" == "Darwin" ]; then
  # Testing testing one one
  nproc() {
    echo 32
  }
fi

# Add 20% in a hope that not all process are CPU-bound. Not based on research.
# TODO: More elaborate logic. Consider the RAM? Consider ~/.config/roku/make-bash-completion.cfg.
_roku_make_recommended_cores() {
  echo "$(($(nproc) + $(nproc) / 5))"
}

# Read a variable value from COMP_WORDS (the line being completed).
_roku_make_get_var() {
  local var_name="$1"
  local a=("${COMP_WORDS[@]}")

  while [[ ${#a[@]} -gt 0 ]]; do
    [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: a=${a[*]}"

    if [[ "${a[0]}" == "${var_name}" ]]; then
      if [[ ${#a[@]} -lt 3 || "${a[1]}" != "=" ]]; then
        # It's not an assignment.
        break
      fi
      echo "${a[2]}"
    fi

    a=("${a[@]:1}")
  done

  echo ""
}

## Run make $1 [BUILD_PLATFORM=$2], filtering out the excess messages.
_roku_make_print_var() {
  local MAKE_TARGET_NAME="$1"
  local PLATFORM="$2"

  local BUILD_PLATFORM=""
  if ! _roku_make_in_platform; then
    [[ -n "${PLATFORM}" ]] || PLATFORM="$(_roku_make_get_var BUILD_PLATFORM)"
    [[ -n "${PLATFORM}" ]] || return
    BUILD_PLATFORM="BUILD_PLATFORM=${PLATFORM}"
  fi

  local MAKE_CD_ARGS=
  if _roku_make_above_os; then
    MAKE_CD_ARGS="-C os"
  fi

  local MAKE_VAR_NAME="${MAKE_TARGET_NAME#quickport-print-}"
  MAKE_VAR_NAME=${MAKE_VAR_NAME#port-print-}
  MAKE_VAR_NAME=${MAKE_VAR_NAME#print-}

  # Filter out some messages that port-xxx prints even with --silent.
  # TODO: Silence the messages with --silent.
  local FILTER_PORT_MESSAGES
  FILTER_PORT_MESSAGES="cat"
  if [[ "${MAKE_TARGET_NAME}" == *"port-"* ]] || _roku_make_in_platform; then
    FILTER_PORT_MESSAGES="tail -n 1"
  fi

  # shellcheck disable=SC2086
  make \
    --silent \
    ${BUILD_PLATFORM} \
    ${MAKE_CD_ARGS} \
    ${MAKE_TARGET_NAME} \
  | grep -v 'Audited' \
  | sed "s/${MAKE_VAR_NAME}=//" \
  | ${FILTER_PORT_MESSAGES}
}

export _ROKU_COMPLETION_BUILD_PLATFORMS=
_roku_make_platforms() {
  # Kinda lazy cache. This will never flush, restart your shell.
  if [[ -z "${_ROKU_COMPLETION_BUILD_PLATFORMS}" ]]; then
    _ROKU_COMPLETION_BUILD_PLATFORMS="$(_roku_make_print_var print-ALL_PLATFORMS reno)"
    export _ROKU_COMPLETION_BUILD_PLATFORMS
  fi

  echo "${_ROKU_COMPLETION_BUILD_PLATFORMS}"
}

# Not cached - they are different for different platforms.
_roku_make_components() {
  _roku_make_print_var show-targets
}

_roku_make_partners() {
  _roku_make_print_var quickport-print-OEM_LIST
}

_roku_make_elementIn() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

_roku_make_hasJ() {
  for e; do [[ "$e" == -j* ]] && return 0; done
  return 1
}

_roku_make_pairIn() {
  local e match1="$1"
  local match2="$2"
  shift
  shift
  while [[ "$#" -ne 0 ]]; do
    if [[ "$1" == "$match1" ]]; then
      shift
      break
    fi
    shift
  done
  [[ "$1" == "$match2" ]] && return 0
  return 1
}

_roku_make_complete_by_prefix() {
  local prefix="$1"
  shift

  for variant in "$@"; do
    #    [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: variant=${variant} prefix=${prefix}"
    if [[ "${variant}" == ${prefix}* ]] && ! _roku_make_elementIn "${variant}" "${COMP_WORDS[@]}"; then
      #      [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: variant=${variant} matched prefix=${prefix}"
      COMPREPLY+=("${variant} ")
    fi
  done
}

_roku_make_complete_platforms() {
  local cur="$1"
  _roku_make_platforms >/dev/null # Cache the platforms in a variable first.
  # shellcheck disable=SC2207
  local PLATFORMS=($(_roku_make_platforms))
  _roku_make_complete_by_prefix "${cur}" "${PLATFORMS[@]}"
}

_roku_make_complete_products() {
  local cur="$1"
  if _roku_make_elementIn "austin" "${COMP_WORDS[@]}"; then # Not a very strict check
    local PRODUCTS=('skydi')
    _roku_make_complete_by_prefix "${cur}" "${PRODUCTS[@]}"
  fi
}

_roku_make_complete_partners() {
  local cur="$1"
  # FIXME: Implement.
  local PARTNERS
  # shellcheck disable=SC2207
  PARTNERS=($(_roku_make_partners))
  _roku_make_complete_by_prefix "${cur}" "${PARTNERS[@]}"
}

_roku_make_complete_targets() {
  # trim trailing - if present
  local cur="${1%-}"
  shift
  local TARGETS=("$@")
  # shellcheck disable=SC2207
  local COMPONENTS=($(_roku_make_components))

  # We already have a complete name
  if _roku_make_elementIn "${cur}" "${COMPONENTS[@]}"; then
    COMPREPLY=("${cur/port-/quickport-}-clobber")
    return
  fi

  TARGETS+=("${COMPONENTS[@]}")
  _roku_make_complete_by_prefix "${cur}" "${TARGETS[@]}"
}

# Completes a space or an unknown word.
_roku_make_complete_target() {
  local cur="$1"

  if _roku_make_in_platform; then
    _roku_make_complete_targets "${cur}" 'rootfs' 'image' 'nfs' 'clobber' 'porting-kit'
  else
    if _roku_make_elementIn "BUILD_PLATFORM" "${COMP_WORDS[@]}"; then
      _roku_make_complete_targets "${cur}" \
        'all' 'application' 'rootfs' 'nfs' 'port-image' 'clobber' \
        'quickport-clobber' 'port-clobber' 'quickport-image' 'list-tests-all'
    else
      COMPREPLY+=("BUILD_PLATFORM=")
    fi
  fi
}

_roku_make_complete() {

  local cur=""
  local prev=""
  local preprev=""
  if [[ "${#COMP_WORDS[@]}" -gt 0 ]]; then
    cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ "$((COMP_CWORD - 1))" -ge 0 ]]; then
      prev="${COMP_WORDS[COMP_CWORD - 1]}"
    fi
    if [[ "$((COMP_CWORD - 2))" -ge 0 ]]; then
      preprev="${COMP_WORDS[COMP_CWORD - 2]}"
    fi
  fi

  #  [ -z "${PRINT_DEBUG}" ] || echo "DEBUG:cur=$cur prev=$prev preprev=${preprev}"

  local directory_completions=()
  if _roku_make_in_os; then
    true
  elif _roku_make_above_os; then
    directory_completions=("os" "port")
    if ! _roku_make_elementIn "-C" "${COMP_WORDS[@]}"; then
      # Suggest this first, if we're above.
      if [[ -z "${cur}" ]]; then
        COMPREPLY=("-C os ")
        return
      fi
    fi
  elif _roku_make_in_platform; then
    true
  else
    return
  fi

  COMPREPLY=()

  case "$prev" in
  -C)
    _roku_make_complete_by_prefix "${cur}" "${directory_completions[@]}"
    return
    ;;
  -j)
    if [ -z "$cur" ]; then
      COMPREPLY=("$(_roku_make_recommended_cores) ")
    fi
    return
    ;;
  esac

  case "$cur" in

  -j)
    COMPREPLY+=("-j$(_roku_make_recommended_cores) ")
    ;;

  -C)
    if [[ "${#directory_completions[@]}" -ne 0 ]]; then
      COMPREPLY=("${directory_completions[@]}")
    fi
    ;;

  "" | "-")
#    [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: cur is empty/dach: '${cur}'"
    if ! _roku_make_hasJ "${COMP_WORDS[@]}"; then
      # Let's be aggressive about more common options.
      COMPREPLY=("-j$(_roku_make_recommended_cores) ")
      [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: COMPREPLY:" "${COMPREPLY[@]+"${COMPREPLY[@]}"}"
      return
    fi

    if _roku_make_need_cd_os; then
      COMPREPLY=("-C ")
    elif [[ -z "${cur}" ]]; then
      _roku_make_complete_target "${cur}"
    fi
    ;;

  BUILD_PLATFORMS*)
    # TODO
    COMPREPLY=('BUILD_PLATFORMS="')
    ;;

  =) # That's not my mood, that's an "equal" sign being the current word.
    #    [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: cur is ="

    if [[ "$prev" == "BUILD_PLATFORM" ]]; then
      _roku_make_complete_platforms ""
    elif [[ "$prev" == "BUILD_PRODUCT" ]]; then
      _roku_make_complete_products ""
    elif [[ "$prev" == "OEM_PARTNER" ]]; then
      _roku_make_complete_partners ""
    elif [[ "$prev" == "PAXCTL" ]]; then
      COMPREPLY=("true ")
    fi
    ;;

  BUILD_PLATFORM)
    COMPREPLY=('BUILD_PLATFORM=')
    ;;

  B | BU | BUI | BUIL | BUILD | BUILD_)
    if ! _roku_make_elementIn "BUILD_PLATFORM" "${COMP_WORDS[@]}"; then
      COMPREPLY=('BUILD_PLATFORM')
    elif _roku_make_elementIn "austin" "${COMP_WORDS[@]}"; then # Not a very strict check
      COMPREPLY=('BUILD_PRODUCT=')
    fi
    ;;

  BUILD_PRODUCT)
    COMPREPLY=('BUILD_PRODUCT=')
    ;;

  P | PA | PAX | PAXC | PAXCT | PAXCTL)
    COMPREPLY=("PAXCTL=true ")
    ;;

  O | OE | OEM | OEM_P)
    COMPREPLY=("OEM_PARTNER=")
    ;;

  *)
    [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: 6"

    if [[ "$prev" == "=" ]]; then
      if [[ "$preprev" == "BUILD_PLATFORM" ]]; then
        _roku_make_complete_platforms "${cur}"
      elif [[ "$preprev" == "BUILD_PRODUCT" ]]; then
        _roku_make_complete_products "${cur}"
      elif [[ "$preprev" == "OEM_PARTNER" ]]; then
        _roku_make_complete_partners "${cur}"
      elif [[ "$preprev" == "PAXCTL" ]]; then
        COMPREPLY=("true ")
      fi

    else
      _roku_make_complete_target "${cur}"
    fi
    ;;
  esac

  [ -z "${PRINT_DEBUG}" ] || echo "DEBUG: COMPREPLY:" "${COMPREPLY[@]+"${COMPREPLY[@]}"}"

  #  echo "DEBUG:7"
  return 0
}

#_roku_make_complete
complete -o nospace -F _roku_make_complete make

# As this script is sourced, we don't want an interactive shell to exit each time a command fails.
# Be ware, if your shell settings are different.
set +euo pipefail
