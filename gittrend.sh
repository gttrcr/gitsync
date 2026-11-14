#!/usr/bin/env bash

set -e

REPO_PATH="${1:-.}"
if ! git -C "$REPO_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo "Error: '$REPO_PATH' is not a valid Git repository." >&2
	exit 1
fi

OUTPUT_FILE="repo_line_growth.csv"

# Variabile per memorizzare da dove riprendere
resume_from=""

if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
	# Prende l'ultima riga del file CSV e isola il primo campo (CommitHash)
	last_line=$(tail -n 1 "$OUTPUT_FILE")
	last_commit=$(echo "$last_line" | awk -F',' '{print $1}')

	# Verifica che l'hash estratto esista nel repository corrente
	if [ -n "$last_commit" ] && git -C "$REPO_PATH" rev-parse --verify "$last_commit^{commit}" >/dev/null 2>&1; then
		resume_from="$last_commit"
	else
		echo "Warning: L'ultimo commit registrato nel file non è valido o non esiste in questo repo. Ricindo da capo." >&2
		rm -f "$OUTPUT_FILE"
	fi
fi

# Se il file non esiste (o è stato eliminato perché non valido), crealo con l'intestazione
if [ ! -f "$OUTPUT_FILE" ]; then
	echo "CommitHash,CommitTimestamp,TotalLines,CommitSubject" > "$OUTPUT_FILE"
fi

echo "--------------------------------------------------------------------------------"
echo "Analyzing repository: $(realpath "$REPO_PATH")"
echo "Exporting to: $OUTPUT_FILE"
if [ -n "$resume_from" ]; then
	echo "Resuming from last recorded commit: ${resume_from:0:8}"
else
	echo "Starting fresh analysis from the first commit."
fi
echo "--------------------------------------------------------------------------------"

# Imposta il comando git log: se c'è un punto di ripresa, usa il range (esclude il commit già salvato e prende i successivi)
if [ -n "$resume_from" ]; then
	git_log_cmd=(git -C "$REPO_PATH" log "${resume_from}..HEAD" --reverse --format="%H|%at|%s")
else
	git_log_cmd=(git -C "$REPO_PATH" log --reverse --format="%H|%at|%s")
fi

"${git_log_cmd[@]}" | while IFS='|' read -r commit_hash commit_timestamp commit_msg; do
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
echo "Done! File successfully updated: $OUTPUT_FILE"
echo "--------------------------------------------------------------------------------"
