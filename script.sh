bold=$(tput bold)
normal=$(tput sgr0)
RED="\e[31m"
ORANGE="\e[93m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
organizations=("gttrcr" "eaziu" "magnethica" "wide3network" "academyforma2026")

clear

# compute the number of repos
tot=0
for organization in "${organizations[@]}"
do
	tot=$(echo $tot+`gh repo list $organization --json name --jq ".[].name" | wc -l` | bc -l)
done

# do the job
idx=1
for organization in "${organizations[@]}"
do
	for repo in $(gh repo list $organization --json name --jq ".[].name");
	do
		dir="/home/iki/git/"$organization"/"$repo
		echo "scale=3; 100*"$idx/$tot | bc -l | awk '{printf "%.3f", $0}'
		printf "%-60s" "%) "${bold}$dir${normal}
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
				echo -e $ORANGE"some diff!"$ENDCOLOR
			else
				echo -e $GREEN"done!"$ENDCOLOR
			fi
		else
			echo -ne $ORANGE"cloning..."$ENDCOLOR
			git clone --recurse-submodules -j8 git@github.com:$organization/$repo.git $dir &> /dev/null
			echo -e $GREEN"done!"$ENDCOLOR
		fi
		
		sleep 5
	done
done