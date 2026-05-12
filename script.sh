BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RED="\e[31m"
ORANGE="\e[93m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
clear

organizations=("gttrcr" "eaziu" "magnethica" "wide3network" "academyforma2026" "cate5196")
echo "${BOLD}gitsync${NORMAL} has started over"

# compute the number of repos
tot=0
for organization in "${organizations[@]}"
do
	current=`gh repo list $organization --json name --jq ".[].name" | wc -l`
	tot=$(echo $tot+$current | bc -l)
	echo -e "\t${BOLD}$organization${NORMAL} with $current repositories"
done

echo -e "\n\tTotal $tot repositories\n"

# do the job
idx=1
for organization in "${organizations[@]}"
do
	for repo in $(gh repo list $organization --json name --jq ".[].name");
	do
		dir="/home/iki/git/"$organization"/"$repo
		printf "%-70s" $(printf "%03d" $idx)/$tot") "${BOLD}$dir${NORMAL}
		((idx++))
		
		if [ -d "$dir" ]; then
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
				echo -ne $ORANGE"some diff!"$ENDCOLOR
			else
				echo -ne $GREEN"done!"$ENDCOLOR
			fi
		else
			echo -ne $ORANGE"cloning..."$ENDCOLOR
			git clone --recurse-submodules -j8 git@github.com:$organization/$repo.git $dir
			echo -ne $GREEN"done!"$ENDCOLOR
		fi
		
		echo
		for i in {5..0}; do sleep 1; printf "\r$i\r"; done
	done
done