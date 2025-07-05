#!/bin/bash
# Simple helper to fetch Flutter and add it to PATH for the current session.
# This requires git and an internet connection.
set -e
if [ -d "$HOME/flutter" ]; then
  echo "Flutter already appears installed at $HOME/flutter" >&2
else
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter --version
