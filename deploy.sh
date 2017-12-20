#!/bin/bash
set -x
if [ $TRAVIS_BRANCH == 'master' ] ; then
  cd public
  git init

  git remote add deploy "travis@monicalent.com:/opt/website/static-blog"
  git config user.name "Travis CI"
  git config user.email "lent.monica+travis@gmail.com"

  git add .
  git commit -m "Deploy"
  git push --force deploy master
else
  echo "Not deploying, since this branch isn't master."
fi
