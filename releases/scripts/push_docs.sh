#!/bin/bash

set -x
set -e

rm -rf .yardoc doc
yardoc

cd ../demiurge
rm -rf .yardoc doc
yardoc

cd ../pixiurge
git reset HEAD docs/pixiurge docs/demiurge
git rm -rf docs/pixiurge
git rm -rf docs/demiurge
rm -rf docs/pixiurge docs/demiurge

# Copy over generated documentation
cp -r ../demiurge/doc docs/demiurge
cp -r doc docs/pixiurge
git add docs/demiurge docs/pixiurge

# Everything has a "generated at <time>" line. We don't want files that change only that line.
# A one-line change is always that... except for class_list.html files.
git diff --cached --numstat | grep "\<1\t1\t" | grep -v "class_list.html" | cut -f 3 | xargs git reset
git commit -m "Update docs with latest source changes"
gc docs/

echo Review the created commit using 'git log -p', then push it upstream.
