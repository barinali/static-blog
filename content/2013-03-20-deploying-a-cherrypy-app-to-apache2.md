---
author: Monica
comments: true
date: 2013-03-20 08:50:33+00:00
layout: post
published: false
slug: deploying-a-cherrypy-app-to-apache2
title: Deploying a CherryPy app to Apache2
wordpress_id: 69
categories:
- Python
- Tech
tags:
- cherrypy
- python
---

This is really quick and dirty, but after a _lot _of tedious editing of an apache conf file, I need to get my thoughts and notes written down so I don't forget. It is loosely based on the [CherryPy documentation](http://tools.cherrypy.org/wiki/ModRewrite), though certain things did not work the same way for me. Who knows why.


## The CherryPy Bit


Obviously, replace 'YOUR_IP_ADDRESS' and 'PORT_OF_CHOICE' with the actual values you'd like. I chose 8080 for my port.

`import cherrypy`

`# Settings specific to my server
cherrypy.config.update({'server.socket_host' : 'YOUR_IP_ADDRESS',
'server.socket_port' : PORT_OF_CHOICE});
`

`class HelloWorld:
def index(self):
return "Hello world!"
index.exposed = True
`

`cherrypy.quickstart(HelloWorld())`


## The Apache Bit


The absolute most painful part of it all. Inside my <Directory /path/to/public_html/></Directory> section, I have the following directives:

`AllowOverride All
Options Indexes FollowSymLinks MultiViews
RewriteEngine on
Order allow,deny
allow from all
AddHandler mod_python .py
PythonHandler mod_python.publisher | .py
PythonDebug On`

`# CherryPy related settings
RewriteCond %{SCRIPT_FILENAME} !autostart\.cgi$
RewriteRule ^api/(.*) http://www.example.com:8080/$1 [Last,Proxy]
ErrorDocument 503 http://www.example.com/path/to/cgi-bin/autostart.cgi`

This will route example.com/api/ through the CherryPy app running on port 8080.


## The CGI Bit


And if the CherryPy quickstart server isn't running, it will use a cgi script to start it. This is also in my apache conf file at the end. The file autostart.cgi must be executable, and must be executed by Python.

`# CGI Directory
ScriptAlias /cgi-bin/ /var/www/www.example.com/path/to/cgi-bin/ <Location /cgi-bin>
Options +ExecCGI
AddType text/html py
AddHandler cgi-script .py
</Location>`

More to come once I get a handle on doing this in a better way. Presently, refreshing /api/ will takeover my terminal, which is pretty annoying. I need to find a way to deploy in the background so I can keep working and simply reset the server when I make Python changes.

**UPDATE** Turns out this is as simple as running:

` $ cherryd -d my_app.py`

Then you can check on the process by running top, and you'll see cherryd at the top along with its resource usage. To kill the daemon, run:

`$ killall -v cherryd`

Now I will update my autostart CGI script to execute that command rather than simply `python my_app.py`.
