#!/bin/bash

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RED="\e[31m"
ORANGE="\e[93m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
ORGS=("gttrcr" "eaziu" "magnethica" "wide3network" "cate5196")
clear

log=$(date '+%d/%m/%Y %H:%M:%S')
echo "$log" >> ~/.gitsync

if [ -z "$1" ]; then
	organizations=("${ORGS[@]}")
else
	organizations=($1)
fi

echo "${BOLD}gitsync${NORMAL} has started over"

# associative array: organization -> newline separated list of remote repo names
declare -A REMOTE_REPOS

# compute the number of repos (and cache the remote repo list per organization)
tot=0
for organization in "${organizations[@]}"
do
	current_list=$(gh repo list $organization --json name --jq ".[].name")
	REMOTE_REPOS[$organization]="$current_list"
	current=$(echo "$current_list" | grep -c .)
	tot=$(echo $tot+$current | bc -l)
	echo -e "\t${BOLD}$organization${NORMAL} with $current repositories"
done

echo -e "\n\tTotal $tot repositories\n"

# cycle for every organizations
idx=1
never=true
for organization in "${organizations[@]}"
do
	# cycle for every repo in organization
	for repo in ${REMOTE_REPOS[$organization]};
	do
		dir="/home/iki/git/"$organization"/"$repo
		printf "%-70s" $(printf "%03d" $idx)/$tot") "${BOLD}$dir${NORMAL}
		((idx++))

		if [ -d "$dir" ]; then
			# git push --all origin
			# git fetch --prune

			git -C $dir config pull.rebase false
			local_branch=$(git -C $dir branch --format='%(refname:short)')
			remote_branch=$(git -C $dir branch -r --format='%(refname:short)')
			current_branch=$(git -C $dir rev-parse --abbrev-ref HEAD)
			printf '%-20s' $current_branch

			echo -ne "pulling..."
			git -C $dir pull | grep -v "Already up to date."

			echo -ne "updating..."
			git -C $dir submodule update --recursive --init

			echo -ne "checking..."
			git -C $dir add .

			if [[ $(git -C $dir status --porcelain) ]]; then
				never=false
				echo -e $ORANGE"some diff!"$ENDCOLOR
			else
				echo -ne $GREEN"done..."$ENDCOLOR
				printf '\r%s%s' "$(tput el)"
			fi
		else
			echo -ne $ORANGE"cloning..."$ENDCOLOR
			git clone --recurse-submodules -j8 git@github.com:$organization/$repo.git $dir
			git -C $dir config pull.rebase false
			echo -ne $GREEN"done!"$ENDCOLOR
			printf '\r%s%s' "$(tput el)"
		fi
	done
done

if $never; then
	echo "Oh, come on! There is absolutely nothing you need to do today in github. Go for a run!"
fi

# check for local folders that have no matching remote repository
# (repo deleted on GitHub, or a local-only repo/folder never pushed)
echo -e "\n${BOLD}Checking for local folders without a matching remote repo...${NORMAL}"
found_orphans=false
for organization in "${organizations[@]}"
do
	org_dir="/home/iki/git/$organization"
	[ -d "$org_dir" ] || continue

	for local_dir in "$org_dir"/*/; do
		[ -d "$local_dir" ] || continue
		repo_name=$(basename "$local_dir")

		if ! grep -qxF "$repo_name" <<< "${REMOTE_REPOS[$organization]}"; then
			found_orphans=true
			echo -e "\t${RED}$org_dir/$repo_name${ENDCOLOR} -> nessuna repo remota corrispondente"
		fi
	done
done

if ! $found_orphans; then
	echo -e "\t${GREEN}Nessuna cartella orfana trovata.${ENDCOLOR}"
fi