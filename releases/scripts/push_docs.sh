#!/bin/bash

set -x
set -e

rm -rf .yardoc doc
yardoc

cd ../demiurge
rm -rf .yardoc doc
yardoc

cd ../pixiurge
git rm -r docs/pixiurge
git rm -r docs/demiurge
cp -r ../demiurge/doc docs/demiurge
cp -r doc docs/pixiurge
git add docs/demiurge docs/pixiurge

echo This is where a 'git push' might be helpful.
