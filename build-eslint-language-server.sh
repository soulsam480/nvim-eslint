#!/bin/bash

set -e

DEBUG_MODE=false
if [ "$1" == "--debug" ]; then
  DEBUG_MODE=true
fi

rm -rf vscode-eslint

git clone https://github.com/microsoft/vscode-eslint.git
cd vscode-eslint

git checkout release/3.0.24

npm install

cd server
npm install
npm run webpack

cd ../..

if [ "$DEBUG_MODE" == "false" ]; then
  echo "Cleaning up everything except server/out..."

  mkdir -p /tmp/vscode-eslint-out
  cp -R vscode-eslint/server/out /tmp/vscode-eslint-out/

  rm -rf vscode-eslint

  mkdir -p vscode-eslint/server
  cp -R /tmp/vscode-eslint-out/out vscode-eslint/server/

  rm -rf /tmp/vscode-eslint-out
else
  echo "Skipping cleanup due to --debug mode."
fi
