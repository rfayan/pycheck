# PyCheck

Python audit script that integrates several tools for checking and reporting logic and stylistic code errors as well as applying automated fixes for code style and PEP8 compliance.

---

### Setup

```
 $ ./setup.sh  # Install all dependencies and set executable and configuration files path
```

### Usage

```
 $ pycheck                    # Analyse all .py files in current and subfolders
 $ pycheck [files] [folders]  # Analyse specified files and/or files contained in folders
 $ pycheck ( -c | --config )  # Print versions and configuration files
 $ pycheck ( -h | --help )    # Print help message (the one you're reading)
 $ pycheck ( --add-hook )     # Add git pre-commit hook to repository in current path
```
