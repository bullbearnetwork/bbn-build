#!/usr/bin/env bash
# Avoid symlinks
cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2

# ADD to the PATH the bin folder with all the pg and other deps scripts
export PATH="$(pwd)/../bin:$PATH"

# Mostly (If not only) when compiling the node package. (postgres)
export LD_LIBRARY_PATH="$(pwd)/../lib:$LD_LIBRARY_PATH"

export PM2_HOME="$(pwd)/../.pm2"
