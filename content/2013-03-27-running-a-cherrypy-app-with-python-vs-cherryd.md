---
author: Monica
comments: true
date: 2013-03-27 00:14:30+00:00
layout: post
published: false
slug: running-a-cherrypy-app-with-python-vs-cherryd
title: Running a CherryPy app with 'python' vs 'cherryd'
wordpress_id: 74
categories:
- Python
- Tech
tags:
- cherrypy
- python
---

## Loading Configuration Files


When using 'python' to run your app file, CherryPy will respect the settings you have established within that file. For example:

`import os
import cherrypy`

`# App stuff here`

`# Configuration
conf_path = os.path.dirname(os.path.abspath(__file__))
conf_path = os.path.join(conf_path, "myapp.conf")
cherrypy.config.update(conf_path)
cherrypy.quickstart(MyApp())`

Inside `myapp.conf` you will include something like this, and probably more:

`[global]
server.socket_host = '198.101.205.52' # Your IP address
server.socket_port = 8080 # Your port
server.thread_pool = 8`

Then, you can begin the CherryPy server using:

`$ python myapp.py`

However, if you want to use `cherryd`, you must explicitly specify the location of the config file, or cherrypy will simply use default configs — in my case, constantly reverting to setting `server.socket_host` to 127.0.0.1. Very annoying! Here is the alternate code to start with cherryd:

`$ cherryd -c myapp.conf myapp.py`

Quite bizarre, yet interesting...no? I just spent at least and hour trying to fix code that already worked because apparently, the last time I was working on this, I was running my code with `python` rather than `cherryd`. Arg!
