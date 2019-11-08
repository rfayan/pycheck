#!/bin/bash

set -eu

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo "Your "'$PATH'" is missing ~/.local/bin, you need to add it to run pycheck"
  echo "Add '"'export PATH=$PATH:/home/rfayan/bin'"' to your shell rc (e.g. ~/.bashrc)"
  exit 1
fi

# Create config folder
mkdir -p ~/.config/python

# Copy config files and pre-commit git hook script
cp pylama.ini black.toml isort.cfg pycheck-pre-commit.sh ~/.config/python

# Install dependencies
pip install --user --upgrade mccabe pycodestyle pydocstyle pyflakes pylint astroid black isort
pip install --user --upgrade pylama
npm install -g diff-so-fancy

# Copy executable script to folder included in $PATH
cp pycheck.sh ~/.local/bin/pycheck

echo "All done! Have fun!"