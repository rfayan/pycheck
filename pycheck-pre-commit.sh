#!/bin/sh

set -o pipefail

# Config locations for Black and Isort
BLACK_CONFIG=~/.config/python/black.toml
ISORT_CONFIG=~/.config/python/  # .isort.cfg file must be inside this folder

if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=$(git hash-object -t tree /dev/null)
fi

# If you want to allow non-ASCII filenames set this variable to true.
allownonascii=$(git config --bool hooks.allownonascii)

# Cross platform projects tend to avoid non-ASCII filenames; prevent
# them from being added to the repository. We exploit the fact that the
# printable range starts at the space character and ends with tilde.
if [ "$allownonascii" != "true" ] &&
	# Note that the use of brackets around a tr range is ok here, (it's
	# even required, for portability to Solaris 10's /usr/bin/tr), since
	# the square bracket bytes happen to fall in the designated range.
	test $(git diff --cached --name-only --diff-filter=A -z $against |
	  LC_ALL=C tr -d '[ -~]\0' | wc -c) != 0
then
	cat <<\EOF
Error: Attempt to add a non-ASCII file name.

This can cause problems if you want to work with people on other platforms.

To be portable it is advisable to rename the file.

If you know what you are doing you can disable this check using:

  git config hooks.allownonascii true
EOF
	exit 1
fi

### Python audit checks ###

str_changed_files=$(git diff --cached --name-only --diff-filter=ACMR $against -- | grep ".*\.py$")
IFS=$'\n' changed_files=($str_changed_files)

if [ ! -z "$changed_files" ]
then
	# Isort (import ordering)
	if ! isort -sp "$ISORT_CONFIG" --check-only ${changed_files[@]}
	then
		exit 1
	fi

	# Black (python autoformatter)
	if ! black --config "$BLACK_CONFIG" --check --quiet ${changed_files[@]} 2>&1 | cat
	then
		black --config "$BLACK_CONFIG" --check ${changed_files[@]} 2>&1 | cat
		exit 1
	fi
fi

# If there are whitespace errors, print the offending file names and fail.
exec git diff-index --check --cached $against --
