#!/bin/zsh
set -e
cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/release.sh <version>}"
NAME="AJ139 Driver"
APP="build/$NAME.app"

scripts/build_app.sh "$VERSION"

rm -rf dist
mkdir -p dist
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$NAME" -srcfolder "$STAGE" -ov -format UDZO -quiet dist/AJ139-Driver.dmg
rm -rf "$STAGE"

ditto -c -k --keepParent "$APP" dist/AJ139-Driver.zip
ls -lh dist
