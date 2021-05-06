#!/bin/bash
# Rafael Fayan, 2019. MIT License
#
# Verify python code for logic and stylistic erros with the Pylama tool
# as well as applying simple code fixes with isort for correct
# import order and and black for PEP8 code style compliance
#
# Note: Currently, diff-so-fancy as a standalone tool has a bug in
#       which it does not displays added or removed blank lines corretly

set -e # Exit script on any error

# Config locations for Pylama, Black and Isort
PYLAMA_CONFIG=~/.config/python/pylama.ini
BLACK_CONFIG=~/.config/python/black.toml
ISORT_CONFIG=~/.config/python/  # .isort.cfg file must be inside this folder
PRE_COMMIT_HOOK=~/.config/python/pycheck-pre-commit.sh

# Color code for pylama types of errors, from more to less critical
dark_red='01;38;5;160'
light_red='01;38;5;01'
orange='01;38;5;214'
yellow='01;38;5;226'
blue='01;38;5;45'
green='01;38;5;41'

# Color codes for echoing headers
cyan='\033[01;38;5;87m'
NC='\033[0m'

case "$1" in
	-h | --help)
		cat <<-EOF
		Python code audit and formatter script

		Usage:
		pycheck                    # Analyse all .py files in current and subfolders
		pycheck [files] [folders]  # Analyse specified files and/or files contained in folders
		pycheck ( -c | --config )  # Print versions and configuration files
		pycheck ( -h | --help )    # Print help message (the one you're reading)
		pycheck ( --add-hook )     # Add git pre-commit hook to repository in current path
		pycheck ( --install-deps ) # Install python dependencies (detect 3rd party imports in virtual enviroments)
		EOF

		exit
		;;
	-c | --config)
		echo -e "$cyan"'Software Versions:'"$NC"
		python --version
		pylama --version
		echo 'pycodestyle' `pycodestyle --version`
		pylint --version | head -n 1
		isort -v |grep VERSION | awk '$1="isort"'
		black --version
		diff-so-fancy --version 2>&1 |grep Version | awk '$1="diff-so-fancy"'

		echo -e "$cyan"'\nPylama config :' "$PYLAMA_CONFIG""$NC"
		cat "$PYLAMA_CONFIG"

		echo -e "$cyan"'\nBlack config: ' "$BLACK_CONFIG""$NC"
		cat "$BLACK_CONFIG"

		exit
		;;
	--install-deps)
		pip install mccabe pycodestyle pydocstyle pyflakes pylint astroid black isort
		pip install pylama

		exit
		;;
	--add-hook)
		cp "$PRE_COMMIT_HOOK" ./.git/hooks/pre-commit
		echo "Git pre-commit hook added succesfully!"

		exit
		;;
esac

# Run Pylama with appliying grep colors based on type of error (E,W,I,...)
# with predefined colors defined as globals in this shell function
pylama -o "$PYLAMA_CONFIG" "$@"                          |
	GREP_COLOR="$dark_red" grep -E --color=always '^.* .E. .*$|$'   |
	GREP_COLOR="$light_red" grep -E --color=always '^.* .W. .*$|$'  |
	GREP_COLOR="$orange" grep -E --color=always '^.* .I. .*$|$'     |
	GREP_COLOR="$yellow" grep -E --color=always '^.* .R. .*$|$'     |
	GREP_COLOR="$blue" grep -E --color=always '^.* .C. .*$|$'       |
	GREP_COLOR="$green" grep -E --color=always '^.* .D. .*$|$'      ||
	{ echo -e "$cyan"'\n--- No errors detected! Cheers! ---\n' && exit 0; }


echo -e "\nType Enter to continue..."
read

# Run isort to verify if sorting is needed, and if so, print the diff with
# diff-so-fancy after applying sed substitutions for compatibility and
# query desired action from the user
if ( ! isort --sp "$ISORT_CONFIG" --check-only "$@" > /dev/null 2>&1 ); then
		isort --sp "$ISORT_CONFIG" --diff "$@" | sed 's/.py\(:before\|:after\)/.py/'      |
				sed 's/--- \(.*.py\)/diff --git \1\n&/' | diff-so-fancy                  |
				(echo -e "$cyan"'--- Imports not sorted, diff bellow: ---'"$NC" && cat)  |
				less --tabs=4 -RFXS
		echo -ne "\nApply changes (y/n)? "
		read answer
		if [ "$answer" != "${answer#[Yy]}" ] ;then
				isort --sp "$ISORT_CONFIG" "$@"
		fi
		echo
else
		echo -e "$cyan"'--- Imports are correctly sorted! ---\n'"$NC"
fi

# Run black to verify if reformating is needed, and if so, print the diff with
# diff-so-fancy after applying sed substitutions for compatibility and
# query desired action from the user
if ( ! black --config "$BLACK_CONFIG" --check "$@" > /dev/null 2>&1 ); then
		black --config "$BLACK_CONFIG" --diff --quiet "$@"                             |
				sed 's/--- \(.*.py\)/diff --git \1\n&/' | diff-so-fancy                |
				(echo -e "$cyan"'--- Pycodestyle suggested changes: ---'"$NC" && cat)  |
				less --tabs=4 -RFXS
		echo -ne "\nApply changes (y/n)? "
		read answer
		if [ "$answer" != "${answer#[Yy]}" ] ;then
				black --config "$BLACK_CONFIG" "$@" 2>&1 | cat
		fi
		echo
else
		echo -e "$cyan"'--- Pycodestyle conventions OK! ---\n'"$NC"
fi
