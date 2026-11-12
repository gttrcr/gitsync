#!/usr/bin/env bash

set -e

# Gestione del parametro della repository (default: directory corrente)
REPO_PATH="${1:-.}"

# Verifica che sia una repository Git valida
if ! git -C "$REPO_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo "Errore: '$REPO_PATH' non è una repository Git valida." >&2
	exit 1
fi

OUTPUT_FILE="repo_crescita_linee.csv"
# Sostituita la colonna CommitDate con CommitTimestamp
echo "CommitHash,CommitTimestamp,TotalLines,CommitSubject" > "$OUTPUT_FILE"
echo "--------------------------------------------------------------------------------"
echo "Analisi della repository: $(realpath "$REPO_PATH")"
echo "Esportazione in corso su: $OUTPUT_FILE"
echo "--------------------------------------------------------------------------------"

# Utilizzo di %at per ottenere il timestamp Unix del commit
git -C "$REPO_PATH" log --reverse --format="%H|%at|%s" | while IFS='|' read -r commit_hash commit_timestamp commit_msg; do
	total_lines=0
	while read -r mode type blob_hash file_path; do
		if [ "$type" = "blob" ]; then
			lines=$(git -C "$REPO_PATH" cat-file -p "$blob_hash" | wc -l)
			total_lines=$((total_lines + lines))
		fi
	done < <(git -C "$REPO_PATH" ls-tree -r "$commit_hash")

	# Gestione delle virgolette doppie nel messaggio per preservare la validità del CSV
	clean_msg=$(echo "$commit_msg" | sed 's/"/""/g')
	echo "$commit_hash,$commit_timestamp,$total_lines,\"$clean_msg\"" >> "$OUTPUT_FILE"
	echo "Processato commit ${commit_hash:0:8} (Timestamp: $commit_timestamp) -> $total_lines linee"
done

echo "--------------------------------------------------------------------------------"
echo "Completato! File generato con successo: $OUTPUT_FILE"
echo "--------------------------------------------------------------------------------"
