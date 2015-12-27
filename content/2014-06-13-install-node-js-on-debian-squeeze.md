+++
author: Monica
comments: true
date: 2014-06-13 09:39:46+00:00
layout: post
slug: install-node-js-on-debian-squeeze
title: Install Node.js on Debian Squeeze
wordpress_id: 230
categories:
- JavaScript
- Node
- Tech
tags:
- debian
- debian squeeze
- nodejs
- npm
+++

I had some issues with libraries installed via npm (such as d3 and jsdom) causing segmentation faults in Mocha tests. Ultimately I realized that it wasn't a problem with these node modules so much as it was with my node install itself. I had installed from source following [this guide](http://sekati.com/etc/install-nodejs-on-debian-squeeze), but it wasn't quit enough to get my node install right on Debian Squeeze.

<!-- more -->




## Install Node.js




### Dependencies


Pretty standard stuff -- make sure you're up to date on these.

    
    <code class="language-bash">$ sudo apt-get update && apt-get install git-core curl build-essential openssl libssl-dev</code>




### Clone the Git Repo


Change into the directory you want to install node from. A good option, if in doubt, is to just go for `/opt`.

    
    <code class="language-bash">$ git clone https://github.com/joyent/node.git
    cd node</code>


Check the [Node.js Download Page](http://nodejs.org/download/) and see what they say the latest version of Node is that we should be using. At the time of writing, this was **v0.10.28**. Find this using `git tag`:

    
    <code class="language-bash">$ git tag</code>


There may be a newer version in the Git repo than the one recommended on the Download page, however it may not be stable. Check it out:

    
    <code class="language-bash">$ git checkout v0.10.28</code>


You should see **(Stable)** after the version number once you perform this checkout.


### Make and Install


Configure node. The section option `--without-snapshot` should give you a faster build and alleviate some seg fault issues mentioned [elsewhere](http://www.armhf.com/node-js-for-the-beaglebone-black/) around the web.

    
    <code class="language-bash">$ ./configure --openssl-libpath=/usr/lib/ssl --without-snapshot</code>


Now make and install (it could take some time to complete the make testing and process, as we're compiling the source code).

    
    <code class="language-bash">$ make
    $ make test
    $ make install</code>


If it worked, you'll be able to run both of these commands:

    
    <code class="language-bash">$ node -v
    $ npm -v</code>




## If you messed up...


...like me, and installed a totally wrong and unstable version, luckily there's still hope. Change into the directory where you put the node source:

    
    <code class="language-bash">$ make uninstall</code>


Now you can switch branches, re-configure, and re-build the node source as needed. Just be sure to check with `node -v` again after you've done the install to be sure everything worked. Good luck!



* * *





## Questions, Comments, Mistakes?


Get in touch via the comments (preferable, so others can use them to troubleshoot), or Twitter at [@monicalent](http://www.twitter.com/monicalent), or Google at [+MonicaLent](https://plus.google.com/+MonicaLent/).
