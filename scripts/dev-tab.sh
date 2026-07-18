#!/usr/bin/env bash
set -euo pipefail

tab="${1:?tab name is required}"
project_dir="${DEV_PROJECT_DIR:?DEV_PROJECT_DIR is required}"
workbench_dir="${DEV_WORKBENCH_DIR:?DEV_WORKBENCH_DIR is required}"

cd "${project_dir}"

open_shell() {
  local shell_path="${SHELL:-/bin/zsh}"
  exec "${shell_path}" -l
}

case "${tab}" in
  editor)
    exec "${workbench_dir}/scripts/run.sh" "${project_dir}"
    ;;
  codex)
    exec codex
    ;;
  git)
    if command -v lazygit >/dev/null 2>&1; then
      exec lazygit
    fi
    git status --short --branch || true
    printf '\nGit shell ready in %s (install lazygit for the full-screen Git UI).\n' "${project_dir}"
    open_shell
    ;;
  test)
    if [[ -n "${DEV_TEST_COMMAND:-}" ]]; then
      printf 'Running DEV_TEST_COMMAND: %s\n\n' "${DEV_TEST_COMMAND}"
      set +e
      "${SHELL:-/bin/zsh}" -lc "${DEV_TEST_COMMAND}"
      test_status=$?
      set -e
      printf '\nTest command exited with status %s. Test shell remains open.\n' "${test_status}"
    else
      printf 'Test shell ready in %s.\n' "${project_dir}"
      printf 'Set DEV_TEST_COMMAND to run a project-specific command at startup.\n'
    fi
    open_shell
    ;;
  *)
    echo "Unknown dev tab: ${tab}" >&2
    exit 2
    ;;
esac
