+++
author = "Monica"
comments = true
date = "2013-12-06 16:03:09+00:00"
slug = "set-up-nginx-and-uwsgi"
title = "Set up Nginx and uWSGI"
wordpress_id = 156
+++

When browsing the web, I often read that setting up nginx with uWSGI is incredibly easy to set up and get running. I absolutely did not find it so, as I had to deal with a lot of configuration issues. So here's how I finally got these components working together on an instance of Ubuntu 12.04. _I ultimately hook this up to Django_, but I'm sure the general principle would apply to other python frameworks with a WSGI interface.

Before you read this guide, I would advise taking a look at [Setting up Django and your web server with uWSGI and nginx](https://uwsgi.readthedocs.org/en/latest/tutorials/Django_and_nginx.html). It didn't work "as advertised" for me, but was nonetheless very helpful.


## Basic Installation

The fun begins when you simply install both components, nginx and uWSGI.
    
```bash
$ sudo apt-get install nginx uwsgi uwsgi-plugin-python
```

Now, you cannot trust that the version of uWSGI you've just installed is the most recent. Even after running `apt-get update` my package installer _still_ insisted on an ancient version of uWSGI, something like 0.8. You cannot even run `apt-get install uwsgi=1.9` and expect it will find the correct version. The great part about this is that such an old version of uWSGI flat out does not work with nginx. So, check you have the most recent version of uWSGI installed:

```bash
$ uwsgi --version
```

If you find anything besides the latest version (1.9, at the time of writing), you have to do a magic work around for this issue (acquired from [this Stackoverflow question](http://stackoverflow.com/questions/13965555/after-pip-installing-uwsgi-theres-no-etc-uwsgi-directory-how-can-i-use-apps)):

```bash
$ pip install -U uwsgi
$ cd /usr/bin
$ mv uwsgi uwsgi-old
$ ln -s /usr/local/bin/uwsgi uwsgi
```

## nginx Configuration

Both nginx and uWSGI require their own configuration files. Presuming my project name is "app", I generally choose to develop within `/opt/app`. Within, I create a directory called `extras`, wherein I place my configuration files--this way I can symbolically link them to the locations nginx/uWSGI expect them to be, and not have to copy changes over every time there's a change to it by someone else in, say, a Github repository.

In `/opt/app/extras/nginx.conf`, place the following code:
    
```nginx
server {
  listen  8000;
    server_name localhost;
    charset utf-8;
    access_log /var/log/nginx/app.net_access.log;
    error_log /var/log/nginx/app.net_error.log;

    location  /static {
      alias  /opt/app/static/;
    }

    location / {
      uwsgi_pass  unix:///var/uwsgi/app.sock;
      include     /opt/app/extras/uwsgi_params;
      uwsgi_param UWSGI_SCRIPT app.wsgi;
    }
}
```

I'll explain all these settings in turn:

* **listen**: The port that nginx is essentially broadcasting on. If you visit _www.yoursite.com:8000_, in this case, you will trigger nginx to respond. If you don't want to have to specify a port, or you want to update the configuration for production, just use port 80.
* **server_name**: Can generally be localhost, though alternatively could be the IP address of the server you are on.
* **charset**: utf-8 is suitable for most purposes.
* **access_log, error_log**: You can set these to basically any path that the `www-data` Unix user can write to, though it makes sense it keep them out of your working directory so you don't end up pushing them to source control.
* **location `/static`**: This is just a location that we don't need uWSGI to worry about. It keeps the code running faster if nginx knows it can server this directory straight, instead of through the interface.
* **uwsgi_pass**: The path to the socket that uWSGI and nginx will both access to communicate with one another (more on this later).
* **include**: Some uWSGI settings which are rather standard (see: "[What is the uWSGI params file?](http://uwsgi-docs.readthedocs.org/en/latest/Nginx.html#what-is-the-uwsgi-params-file)").
* **uwsgi_param**: Specifies the uWSGI module you want to use--this _must be available from the python path_.**

## uWSGI Configuration

The uWSGI configuration is much pickier than the nginx configuration for several reasons. Hereafter, I'll share the configuration that I use and discuss the errors that many of these specific configurations and values specifically fixed.

```nginx
[uwsgi]
binary-path = /usr/local/bin/uwsgi
chdir = /opt/app
chmod-socket = 777
chown-socket = www-data

# While debugging, it makes sense to comment out this line, 
# so you see uWSGI errors in the terminal instead of having 
# to go to the logs. Once your setup works, uncomment and it 
# should smoothly switch to a daemon process.
daemonize = /var/log/app/app_daemon.log

die-on-term = true
emperor = true
enable-threads = true
gid = www-data
home = env
limit-as = 512
master = true
module = app.wsgi
pidfile = /opt/logs/uwsgi/master.pid
processes = 2
python-path = /opt/app
socket = /var/uwsgi/app.sock 
touch-reload = /opt/app/reload
uid = www-data
vacuum = true
vhost = true
virtualenv = /opt/app/env
workers = 4
```

Not all of these settings may be necessary, but it's what I finally found works for me. Visit the official uWSGI documentation on [Configuration Options](http://uwsgi-docs.readthedocs.org/en/latest/Options.html) for a complete rundown. Here are settings I needed to resolve specific bugs.

**binary-path** You need to tell uWSGI which binary to use in the case that it's not in the default spot. Since we had to do some finagling with the uWSGI version, it is probably a good idea to specify the path here.

**chmod-socket, chown-socket, gid, uid, socket** For uWSGI and nginx to communicate over a socket, you need to specify the permissions and the owner of the socket. _777 as chmod-socket is much too liberal for production_. However, you may have to mess around with this number to get it correct, so everything necessary can communicate. If you don't take care of your socket configurations, you will get errors such as:

```bash
(111: Connection refused) while connecting to upstream.
```

```bash
bind(): Permission denied [socket.c line 107]
``` 

To create the space for the socket to exist, you just have to pick a persistent directory (e.g. _not_ `/run` or `/tmp`) and make `www-data` (the user nginx runs as) the owner of it, as such:

```bash
$ sudo mkdir /var/uwsgi
$ sudo chown www-data:www-data /var/uwsgi
```

Make sure that your value for `socket` in the uWSGI conf file corresponds to the value for `uwsgi_pass` in the nginx conf file.

**limit-as** Unix has some sort of built in limits for what it can transfer. You may need to set this value if you get errors such as:

```bash
[error] 20739#0: *21 upstream prematurely closed connection while reading response header from upstream
```

**module** Refers to the uWSGI module, which must be on the Python Path. In the Nginx settings, you saw this same value corresponding to `uwsgi_param UWSGI_SCRIPT`.

**python-path** As you'd expect, having the correct python path is very important for uWSGI to find your app's WSGI file.

## Symlinking the Conf files

Okay, so you should now have two working configuration files stored in a place such as `/opt/app/extras`. Now, in order for nginx and uWSGI to automatically load when you use them as services, we have to sym link our files into directories that each looks in on startup.

```bash
$ ln -s /opt/app/extras/nginx.conf /etc/nginx/sites-enabled/nginx.conf
$ ln -s /opt/app/extras/uwsgi.conf /etc/uwsgi/apps-enabled/uwsgi.conf
```

## Testing the Configuration

Now we should be able to test out the configuration. My advice is to comment out the `daemonize` line in `uWSGI.conf`, so you can see what's happening while you start up uWSGI. Then start both services.

```bash
$ service nginx restart
$ uwsgi /opt/extras/uwsgi.conf
```

You should then see uWSGI take over your entire terminal and tell you that it's running correctly. Open up localhost or the IP address in the web browser and watch what happens. If you can load a page, congratulations! Sig int and uncomment the daemon line, and let it run.

## Troubleshooting

**Error:**

```bash
ImportError: No module named 'app.wsgi'
unable to load app 0 (mountpoint='') (callable not found or import error)
```

**Problem:** You probably have a Python path issue, because it is not finding your WSGI app. Also, make sure your virtualenv is running!

**Error:**

```bash
uWSGI Error. Python application not found
```
    
**Problem:** Your python path is probably still wrong to your app.wsgi. Make sure that nginx and uWSGI are finding your UWSGI app at all by checking their logs.

**Error:**

```bash
502 Bad Gateway
```

**Problem:** Chances are that uWSGI isn't actually running. The issue is that Nginx is trying to funnel requests through uWGSI, but uWSGI isn't running to handle them with your Python app. 

**In general:**
**Make sure uWSGI is actually running.** It generally helps to look at the processes and see how many are running--I had issues where I thought uWSGI was running, but it was "silently" failing because all the errors were being funneled into the logs. This means that nginx will be attempting to talk to uWSGI, but it cannot. You'll get all sorts of non-descriptives errors of this.

```bash
$ ps aux | grep uwsgi
```

Will list all the processing running on your machine. 

* * *

## Questions, Comments, Corrections?

Get in touch via Twitter at [@monicalent](http://www.twitter.com/monicalent).
