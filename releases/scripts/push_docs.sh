#!/bin/bash

set -x
set -e

rm -rf .yardoc doc
yardoc

cd ../demiurge
rm -rf .yardoc doc
yardoc

cd ../pixiurge
git rm -rf docs/pixiurge
git rm -rf docs/demiurge
cp -r ../demiurge/doc docs/demiurge
cp -r doc docs/pixiurge
git add docs/demiurge docs/pixiurge

# Everything has a "generated at <time>" line. We don't want files that change only that line.
git diff --cached --numstat | grep "\<1\t1\t" | cut -f 3 | xargs git reset

echo This is where a 'git push' might be helpful.
