#!/bin/bash
# Primitive script to;
# - Identify and run any "clean" rake tasks in specified directories (if present)
# - Git pull, checkout and submodule init/update on master (optionally force, clean and/or reset)
#   but only if the directory is a git repo
# - Force & clean options available which will discard local changes in favour of repo versions
# Marc Savy

#use -d "/my/dir /my/dir2" to override defaults
#you can use relative paths from wherever the script is executed if you prefer
PROJECTS=( /mnt/boxgrinder/boxgrinder-build /mnt/boxgrinder/boxgrinder-build-plugins  /mnt/boxgrinder/boxgrinder-core  /mnt/boxgrinder/rumpler  /mnt/boxgrinder/steamcannon  /mnt/boxgrinder/steamcannon-agent  /mnt/boxgrinder/steamcannon-agent-rpm  /mnt/boxgrinder/steamcannon-appliances  /mnt/boxgrinder/steamcannon-rpm  /mnt/boxgrinder/torquebox-rpm )

USAGE="Usage: `basename $0` [-hvl][-d \"dir1 dir2 dir3\"][-frc] \n
-d \t list of directories to override defaults \n
-f \t force checkout, this will discard any local changes in favour of repository committed version (careful!) \n
-c \t clean out any untracked files
-r \t hard reset, discards all local repository changes and resets to origin/master
-h \t this information \n
-v \t version \n
-l \t list default directories 
"
VERSION=0.1
FORCE_CHECKOUT=0
BRANCH=master
HARD_RESET=0
CLEAN_UNTRACKED=0

run_clean_tasks ()
{
    if [ ! -e "Rakefile" ]; then #no rake tasks
	return
    fi 

    rake -T | awk '{result = match($0,/^.*?clean([\S]*|$)/,arr)} {if (result !=0 ) print arr[0]}' | tee /dev/tty | sh
}

run_git_tasks ()
{  
    git status

    if [ $? != "0" ]; then
	echo `pwd` "is not associated with a git repository, skipping."
	return
    fi

    if [ $HARD_RESET == 1 ]; then
	git reset --hard origin/master    
    fi

    if [ $CLEAN_UNTRACKED == 1 ]; then
	git clean -d -f
    fi

    if [ $FORCE_CHECKOUT == 1 ]; then
	git checkout -f master
    else
	git checkout master
    fi

    git pull
    git submodule init
    git submodule update
} 

print_projects ()
{
    echo -e "Number of Default Directories: ${#PROJECTS[*]}"
	    
    for i in ${!PROJECTS[@]}; do
	printf "%s\n" ${PROJECTS[$i]} 
    done
    
    exit
}

### Parse the Command-Line arguments
while getopts "d:vhlfrc" OPTION; do
    case $OPTION in
	h) 
	    echo -e $USAGE
	    exit 0
	    ;;
	v) 
	    echo $VERSION
	    exit 0
	    ;;
	l) 
	    print_projects	    
	    exit 0
	    ;;
	d)  
	    #redeclare the array with user's path choices
	    declare -a PROJECTS=($OPTARG)
	    ;;
	f)
	    FORCE_CHECKOUT=1
	    ;;
	r)
	    HARD_RESET=1
	    ;;
	c)
	    CLEAN_UNTRACKED=1
	    ;;
	*)
	    exit 0
	    ;;
    esac
done

#Anchored to the directory the script is
#executed from
ROOT_DIR=`pwd`

for directory in ${PROJECTS[@]}; do
    cd $ROOT_DIR

    if [ -d "$directory" ]; then
	echo "Changing directory: " $directory
	cd $directory
    else
	echo "Directory $directory does not exist" 1>&2
	continue
    fi
   
    #echo "Running clean tasks where applicable"
    run_clean_tasks
    #echo "Checking out master & pulling"
    run_git_tasks
    rm -rf build # not sure if this is really needed
done

exit 0