#!/bin/bash

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

# Get stats per author
git log --format="%aN" --shortstat | awk -v author_col=$AUTHOR_COL -v commit_col=$COMMITS_COL -v ins_col=$INSERTED_COL -v del_col=$DELETED_COL -v net_col=$NET_CHANGE_COL '
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
}' | sort -rnk 9

# Print footer
hr
