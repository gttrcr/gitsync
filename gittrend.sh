#!/usr/bin/env bash

set -e

REPO_PATH="${1:-.}"
if ! git -C "$REPO_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo "Error: '$REPO_PATH' is not a valid Git repository." >&2
	exit 1
fi

OUTPUT_FILE="repo_line_growth.csv"
echo "CommitHash,CommitTimestamp,TotalLines,CommitSubject" > "$OUTPUT_FILE"
echo "--------------------------------------------------------------------------------"
echo "Analyzing repository: $(realpath "$REPO_PATH")"
echo "Exporting to: $OUTPUT_FILE"
echo "--------------------------------------------------------------------------------"

git -C "$REPO_PATH" log --reverse --format="%H|%at|%s" | while IFS='|' read -r commit_hash commit_timestamp commit_msg; do
	total_lines=0
	while read -r mode type blob_hash file_path; do
		if [ "$type" = "blob" ]; then
			lines=$(git -C "$REPO_PATH" cat-file -p "$blob_hash" | wc -l)
			total_lines=$((total_lines + lines))
		fi
	done < <(git -C "$REPO_PATH" ls-tree -r "$commit_hash")
	clean_msg=$(echo "$commit_msg" | sed 's/"/""/g')
	echo "$commit_hash,$commit_timestamp,$total_lines,\"$clean_msg\"" >> "$OUTPUT_FILE"
	echo "Processed commit ${commit_hash:0:8} (Timestamp: $commit_timestamp) -> $total_lines lines"
done

echo "--------------------------------------------------------------------------------"
echo "Done! File successfully generated: $OUTPUT_FILE"
echo "--------------------------------------------------------------------------------"
