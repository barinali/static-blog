---
title: "Deploy Static Sites to Digital Ocean with Travis CI"
date: "2017-12-20T21:08:08+01:00"
---

## Create an encrypted private key for Travis to access your droplet

```bash
gem install travis
travis login
```

```bash
cd /opt/website
touch .travis.yml
ssh-keygen -t rsa -N "" -C "my.email+travis@gmail.com" -f travis_rsa
travis encrypt-file travis_rsa --add
rm travis_rsa
pbcopy < travis_rsa.pub
```

## Create travis user on your droplot who can access the public directory

```bash
sudo adduser --disabled-password --gecos "" travis
sudo chown -R travis:travis /opt/website
sudo su travis
mkdir ~/.ssh
chmod 700 ~/.ssh
vim ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## Prepare the remote repo on the droplet to receive build artifacts

```bash
sudo su travis
cd /opt/website
mkdir .git
cd .git
git init --bare
vim hooks/post-receive
chmod +x hooks/post-receive
```

```shell
#!/bin/sh
git --work-tree=/opt/website/public/ --git-dir=/opt/website/.git checkout -f
```

## Set up `.travis.yml` and shell scripts for deployment

```yaml
language: go

go:
  - 1.9.2

addons:
  ssh_known_hosts: website.com

notifications:
  email:
    on_success: never
    on_failure: always   

before_install:
  - openssl aes-256-cbc -K $encrypted_285ce119f0f4_key -iv $encrypted_285ce119f0f4_iv
    -in travis_rsa.enc -out travis_rsa -d
  - chmod 600 travis_rsa
  - mv travis_rsa ~/.ssh/id_rsa

install:
  - go get -v github.com/spf13/hugo

script:
  - hugo -d public

after_success:
  - bash ./deploy.sh
```

```bash
#!/bin/bash
set -xe

if [ $TRAVIS_BRANCH == 'master' ] ; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_rsa

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

```

## Tips and troubleshooting

### Permission denied (publickey)

### Handling submodules initialized with ssh authentication

### Committing the binary to the repo to improve build times

### Enabling different authorization methods for different users on linux
