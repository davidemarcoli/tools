#!/bin/bash

# Usage function
function show_usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -e, --ext EXT     Filter by file extension(s) (comma-separated)"
  echo "  -p, --path PATH   Filter by path(s) (comma-separated)"
  echo "  -s, --sort COL    Sort by column (author, commits, insertions, deletions, net)"
  echo "  -r, --reverse     Reverse sort order"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --ext js,ts                # Only count JavaScript and TypeScript files"
  echo "  $0 --path src/                # Only count files in the src directory"
  echo "  $0 --sort commits --reverse   # Sort by number of commits in ascending order"
  exit 1
}

# Initialize variables
EXTENSIONS=""
PATHS=""
SORT_COLUMN="net"  # Default sort by net change
SORT_REVERSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--ext)
      EXTENSIONS="$2"
      shift 2
      ;;
    -p|--path)
      PATHS="$2"
      shift 2
      ;;
    -s|--sort)
      SORT_COLUMN="$2"
      shift 2
      ;;
    -r|--reverse)
      SORT_REVERSE=true
      shift
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      ;;
  esac
done

# Validate sort column
case "$SORT_COLUMN" in
  author|authors)
    SORT_FIELD=2  # Sort by the author name
    ;;
  commit|commits)
    SORT_FIELD=3  # Sort by number of commits
    ;;
  insertion|insertions)
    SORT_FIELD=4  # Sort by number of insertions
    ;;
  deletion|deletions)
    SORT_FIELD=5  # Sort by number of deletions
    ;;
  net|change|net_change)
    SORT_FIELD=6  # Sort by net change
    ;;
  *)
    echo "Invalid sort column: $SORT_COLUMN"
    echo "Valid options: author, commits, insertions, deletions, net"
    exit 1
    ;;
esac

# Set sort flag
if [ "$SORT_REVERSE" = true ]; then
  SORT_FLAG="-rn"  # Reverse numeric sort
else
  SORT_FLAG="-n"   # Numeric sort
fi

# Special case for author name (alphabetical sort)
if [ "$SORT_FIELD" -eq 2 ]; then
  if [ "$SORT_REVERSE" = true ]; then
    SORT_FLAG="-r"  # Reverse alphabetical sort
  else
    SORT_FLAG=""    # Alphabetical sort
  fi
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a git repository"
    exit 1
fi

# Get terminal width for adaptable formatting
TERM_WIDTH=$(tput cols)

# Calculate table width based on the longest author name
MAX_AUTHOR_LEN=$(git log --format="%aN" | awk '{ if (length($0) > max) max = length($0) } END { print max }')

# Add some padding
AUTHOR_COL=$((MAX_AUTHOR_LEN + 4))

# Column widths
COMMITS_COL=10
INSERTED_COL=10
DELETED_COL=10
NET_CHANGE_COL=12

# Total table width
TABLE_WIDTH=$((AUTHOR_COL + COMMITS_COL + INSERTED_COL + DELETED_COL + NET_CHANGE_COL + 6))

# Create horizontal line
function hr() {
  printf "+%${AUTHOR_COL}s+%${COMMITS_COL}s+%${INSERTED_COL}s+%${DELETED_COL}s+%${NET_CHANGE_COL}s+\n" | tr ' ' '-'
}

# Print header - fixed column spacing to match data rows exactly
hr
printf "| %-*s| %-*s| %-*s| %-*s| %-*s|\n" \
       $((AUTHOR_COL-1)) "Author" \
       $((COMMITS_COL-1)) "Commits" \
       $((INSERTED_COL-1)) "Inserted" \
       $((DELETED_COL-1)) "Deleted" \
       $((NET_CHANGE_COL-1)) "Net Change"
hr

# Build the git command with optional path filters
GIT_CMD="git log --format=\"%aN\" --shortstat"

# Add file extension filters if specified
if [[ -n "$EXTENSIONS" ]]; then
  # Create path filters for each extension
  IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
  for ext in "${EXT_ARRAY[@]}"; do
    # Trim whitespace
    ext=$(echo "$ext" | xargs)
    # Add each extension as a separate path filter
    GIT_CMD="$GIT_CMD -- \"*.$ext\""
  done
elif [[ -n "$PATHS" ]]; then
  # Add path filters if specified
  IFS=',' read -ra PATH_ARRAY <<< "$PATHS"
  for path in "${PATH_ARRAY[@]}"; do
    # Trim whitespace
    path=$(echo "$path" | xargs)
    GIT_CMD="$GIT_CMD \"$path\""
  done
fi

# Get stats per author
eval $GIT_CMD | awk -v author_col=$AUTHOR_COL -v commit_col=$COMMITS_COL -v ins_col=$INSERTED_COL -v del_col=$DELETED_COL -v net_col=$NET_CHANGE_COL '
BEGIN { }
/^[a-zA-Z]/ { author = $0 }
/^ [0-9]/ {
    commits[author]++
    # Handle the different formats of the shortstat line
    for (i=1; i<=NF; i++) {
        if ($i ~ /insertion/) {
            insertions[author] += $(i-1)
        }
        if ($i ~ /deletion/) {
            deletions[author] += $(i-1)
        }
    }
}
END {
    for (a in commits) {
        net = insertions[a] - deletions[a]
        printf "| %-*s| %*d | %*d | %*d | %*d |\n",
               author_col-1, a,
               commit_col-2, commits[a],
               ins_col-2, insertions[a],
               del_col-2, deletions[a],
               net_col-2, net
    }
}' | sort $SORT_FLAG -k $SORT_FIELD -t '|'

# Print footer
hr
