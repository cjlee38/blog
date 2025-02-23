#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

rm -drf docs
hugo -d docs
echo "blog.cjlee.io" > ./docs/CNAME

git add .

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

git push origin master

# --- rss copy ---

cp docs/index.xml ../cjlee38.github.io/index.xml
cd ../cjlee38.github.io
git add index.xml
git commit -m "update rss"
git push origin main
