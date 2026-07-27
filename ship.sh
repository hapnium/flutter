#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# ship.sh — Multi-project git workflow for Hapnium Flutter packages
#
# Detects changed projects, runs tests, handles git add/commit/push with
# graceful error handling and colored output.
#
# Usage:
#   ./ship.sh                    # Interactive mode
#   ./ship.sh -m "fix: ..."      # Commit with message
#   ./ship.sh -m "fix: ..." -y   # Skip confirmation prompt
#   ./ship.sh --skip-tests       # Skip test execution
#   ./ship.sh --dry-run          # Show what would happen without doing it
#   ./ship.sh --status           # Show status of all projects
# ============================================================================

# --- Colors -------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Configuration -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_MSG=""
AUTO_YES=false
SKIP_TESTS=false
DRY_RUN=false
STATUS_ONLY=false

# All known projects (space-separated for bash 3 compat)
ALL_PROJECTS="chime device gallery hapnium link_preview multimedia phosphor_flutter secure sedat smart tracing zap"

# Projects that use flutter test
FLUTTER_PROJECTS="chime device gallery hapnium link_preview multimedia secure sedat smart zap"

# Projects that use dart test only
DART_ONLY_PROJECTS="tracing"

# --- Helpers ------------------------------------------------------------------

info()    { echo -e "${BLUE}i${NC}  $*"; }
success() { echo -e "${GREEN}v${NC}  $*"; }
warn()    { echo -e "${YELLOW}!${NC}  $*"; }
error()   { echo -e "${RED}x${NC}  $*"; }
header()  { echo -e "\n${BOLD}${CYAN}--- $* ---${NC}"; }
dim()     { echo -e "${DIM}$*${NC}"; }

has() { command -v "$1" &>/dev/null; }

# Check if a project is in a space-separated list
in_list() {
  local needle="$1"
  local haystack="$2"
  for item in $haystack; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# --- Parse arguments ----------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)  COMMIT_MSG="$2"; shift 2 ;;
    -y|--yes)      AUTO_YES=true; shift ;;
    --skip-tests)  SKIP_TESTS=true; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --status)      STATUS_ONLY=true; shift ;;
    -h|--help)
      echo "Usage: ./ship.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -m, --message MSG   Commit message"
      echo "  -y, --yes           Skip confirmation prompt"
      echo "  --skip-tests        Skip running tests"
      echo "  --dry-run           Show what would happen without doing it"
      echo "  --status            Show status of all projects"
      echo "  -h, --help          Show this help"
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      exit 1
      ;;
  esac
done

# --- Pre-flight checks -------------------------------------------------------

header "Pre-flight checks"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  error "Not inside a git repository"
  exit 1
fi

cd "$SCRIPT_DIR"

for cmd in git dart; do
  if ! has "$cmd"; then
    error "Required command not found: $cmd"
    exit 1
  fi
done

if ! has flutter; then
  warn "Flutter not found in PATH — will use 'dart test' for all projects"
  FLUTTER_AVAILABLE=false
else
  FLUTTER_AVAILABLE=true
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

success "In git repo: $REPO_ROOT"

# --- Detect changed projects -------------------------------------------------

header "Detecting changes"

CHANGED_FILES=$(git status --porcelain=v1 2>/dev/null | awk '{print $2}')

if [[ -z "$CHANGED_FILES" ]]; then
  info "No changes detected in any project."
  if $STATUS_ONLY; then
    echo ""
    for proj in $ALL_PROJECTS; do
      if [[ -d "$REPO_ROOT/$proj" ]]; then
        dim "  $proj/"
      fi
    done
  fi
  exit 0
fi

# Map changed files to projects (bash 3 compatible)
CHANGED_PROJECTS=""
ROOT_CHANGES=0

while IFS= read -r file; do
  proj=$(echo "$file" | cut -d'/' -f1)
  if echo "$ALL_PROJECTS" | grep -qw "$proj"; then
    if ! echo "$CHANGED_PROJECTS" | grep -qw "$proj"; then
      CHANGED_PROJECTS="$CHANGED_PROJECTS $proj"
    fi
  else
    ROOT_CHANGES=$((ROOT_CHANGES + 1))
  fi
done <<< "$CHANGED_FILES"

CHANGED_PROJECTS=$(echo "$CHANGED_PROJECTS" | xargs) # trim

if [[ -z "$CHANGED_PROJECTS" ]]; then
  info "Changes detected but not in any project directory:"
  echo "$CHANGED_FILES" | head -10 | while read -r f; do
    dim "  $f"
  done
  if [[ $(echo "$CHANGED_FILES" | wc -l) -gt 10 ]]; then
    dim "  ... and more"
  fi
  echo ""
  info "These changes will be included in the commit."
fi

# Show changed projects
header "Changed projects"
for proj in $CHANGED_PROJECTS; do
  file_count=$(echo "$CHANGED_FILES" | grep "^$proj/" | wc -l | xargs)
  success "$proj ($file_count files changed)"
done

if [[ $ROOT_CHANGES -gt 0 ]]; then
  success "root ($ROOT_CHANGES files changed)"
fi

# --- Status mode exit ---------------------------------------------------------

if $STATUS_ONLY; then
  echo ""
  header "Project details"
  for proj in $CHANGED_PROJECTS; do
    echo ""
    echo -e "${BOLD}$proj/${NC}"
    git status --porcelain="$proj/" 2>/dev/null | head -15 | while read -r line; do
      echo "  $line"
    done
  done
  exit 0
fi

# --- Run tests ----------------------------------------------------------------

FAILED_PROJECTS=""
PASSED_PROJECTS=""
SKIPPED_PROJECTS=""

if ! $SKIP_TESTS; then
  header "Running tests"

  for proj in $CHANGED_PROJECTS; do
    proj_dir="$REPO_ROOT/$proj"

    if [[ ! -d "$proj_dir/test" ]]; then
      warn "$proj — no test/ directory, skipping tests"
      SKIPPED_PROJECTS="$SKIPPED_PROJECTS $proj"
      continue
    fi

    info "Testing $proj..."

    test_cmd=""
    if in_list "$proj" "$FLUTTER_PROJECTS" && $FLUTTER_AVAILABLE; then
      test_cmd="flutter test"
    elif in_list "$proj" "$DART_ONLY_PROJECTS"; then
      test_cmd="dart test"
    elif $FLUTTER_AVAILABLE; then
      test_cmd="flutter test"
    else
      test_cmd="dart test"
    fi

    if $DRY_RUN; then
      dim "  [dry-run] $test_cmd"
      PASSED_PROJECTS="$PASSED_PROJECTS $proj"
      continue
    fi

    pushd "$proj_dir" > /dev/null
    if timeout 120 $test_cmd --reporter compact 2>&1 | tail -5; then
      success "$proj — tests passed"
      PASSED_PROJECTS="$PASSED_PROJECTS $proj"
    else
      error "$proj — tests failed"
      FAILED_PROJECTS="$FAILED_PROJECTS $proj"
    fi
    popd > /dev/null
    echo ""
  done

  # Report test results
  FAILED_PROJECTS=$(echo "$FAILED_PROJECTS" | xargs)
  if [[ -n "$FAILED_PROJECTS" ]]; then
    echo ""
    error "Project(s) failed tests:"
    for proj in $FAILED_PROJECTS; do
      dim "  - $proj"
    done
    echo ""
    read -rp "Continue anyway? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      error "Aborted."
      exit 1
    fi
    warn "Continuing despite test failures..."
  fi
fi

# --- Git add ------------------------------------------------------------------

header "Staging changes"

if $DRY_RUN; then
  dim "[dry-run] git add -A"
else
  git add -A
  success "All changes staged"
fi

# --- Commit message ------------------------------------------------------------

if [[ -z "$COMMIT_MSG" ]]; then
  proj_count=$(echo "$CHANGED_PROJECTS" | wc -w | xargs)
  if [[ "$proj_count" -eq 1 ]]; then
    proj_list="$CHANGED_PROJECTS"
  else
    proj_list=$(echo "$CHANGED_PROJECTS" | sed 's/ /, /g')
  fi

  if $DRY_RUN; then
    echo ""
    dim "[dry-run] Would prompt for commit message"
    dim "  Auto-generated: docs: update $proj_list"
  else
    echo ""
    info "Changed projects: $proj_list"
    echo ""
    read -rp "Commit message (or press Enter for 'docs: update $proj_list'): " input_msg

    if [[ -z "$input_msg" ]]; then
      COMMIT_MSG="docs: update $proj_list"
    else
      COMMIT_MSG="$input_msg"
    fi
  fi
fi

# --- Confirm ------------------------------------------------------------------

if ! $AUTO_YES && ! $DRY_RUN; then
  echo ""
  header "Ready to commit"
  echo -e "  ${BOLD}Message:${NC} $COMMIT_MSG"
  echo -e "  ${BOLD}Projects:${NC} $CHANGED_PROJECTS"
  echo ""
  read -rp "Proceed? [Y/n] " answer
  if [[ "$answer" =~ ^[Nn]$ ]]; then
    error "Aborted."
    exit 1
  fi
fi

# --- Git commit ---------------------------------------------------------------

header "Committing"

if $DRY_RUN; then
  dim "[dry-run] git commit -m \"$COMMIT_MSG\""
else
  if git diff --cached --quiet 2>/dev/null; then
    warn "Nothing to commit (no staged changes)"
  else
    git commit -m "$COMMIT_MSG"
    success "Committed: $COMMIT_MSG"
  fi
fi

# --- Git push -----------------------------------------------------------------

header "Pushing"

if $DRY_RUN; then
  dim "[dry-run] git push"
else
  BRANCH=$(git branch --show-current 2>/dev/null || echo "HEAD")
  info "Pushing to origin/$BRANCH..."

  if git push 2>&1; then
    success "Pushed to origin/$BRANCH"
  else
    error "Push failed. You may need to pull first or resolve conflicts."
    exit 1
  fi
fi

# --- Summary ------------------------------------------------------------------

echo ""
header "Summary"

PASSED_PROJECTS=$(echo "$PASSED_PROJECTS" | xargs)
SKIPPED_PROJECTS=$(echo "$SKIPPED_PROJECTS" | xargs)
FAILED_PROJECTS=$(echo "$FAILED_PROJECTS" | xargs)

if [[ -n "$PASSED_PROJECTS" ]]; then
  echo -e "${GREEN}Tests passed:${NC}"
  for proj in $PASSED_PROJECTS; do
    success "  $proj"
  done
fi

if [[ -n "$SKIPPED_PROJECTS" ]]; then
  echo -e "${YELLOW}Tests skipped:${NC}"
  for proj in $SKIPPED_PROJECTS; do
    warn "  $proj (no tests)"
  done
fi

if [[ -n "$FAILED_PROJECTS" ]]; then
  echo -e "${RED}Tests failed:${NC}"
  for proj in $FAILED_PROJECTS; do
    error "  $proj"
  done
fi

echo ""
success "Done!"
