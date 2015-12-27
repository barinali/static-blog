+++
author: Monica
comments: true
date: 2013-02-20 05:42:58+00:00
layout: post
published: false
slug: tips-for-installing-django-1-4-inside-virtualenv-with-south
title: Tips for Installing Django 1.4 inside Virtualenv with South
wordpress_id: 54
categories:
- Python
- Tech
tags:
- debian
- django
- git
- python
- south
- virtualenv
+++

I'm in the process of installing Django 1.4 on my Debian 6 (Squeeze) box, hosted on Rackspace. I've been following a number of tutorials to get this done, but a lot of them leave out important tips that matter for a total n00b like myself. Here's the process I ultimately followed for installing Django and South inside a virtualenv.

If you have any tips or corrections for me, I'd love to hear them. Thanks!


## Pre-reqs:


Make sure you have these installed. Django doesn't run on Python 3 right now, so stick with Python 2.6 or 2.7.



	
  * Python

	
  * Git

	
  * Pip




## Prelude


Don't get so excited about installing Django that you go off and run `pip install django`. Instead, get all fancy-organized by installing it within a virtual environment.

`$ pip install virtualenv`


<blockquote>**Tip:** Use `pip` instead of system-specific package managers like `apt-get` when working with virtualenv, because then you're sure to be downloading the latest versions of the software you're trying to install.</blockquote>





## Installing Virtualenv


You should be in whatever directory you want to create the virtual environment. For example, I want mine to be in `/opt/env/project_name` so I run this in the shell:

`$ virtualenv project_name`



## Activating Virtualenv


Make sure you are inside the directory of the virtual environment you just installed. For me, that is `/opt/env/project_name`. Once we activate virtualenv, we can start installing other python modules using pip.

`$ source bin/activate`

Notice that your shell prompt is now prepended by `(project_name)`. This is a reminder that you are operating within that virtual environment, and are using a virtualenv instead of your system's Python installation. To close virtualenv, run `deactivate`.



<blockquote>**Tip:** Alias this command in your `~/.bashrc` using an absolute path to avoid having to navigate to this folder or type a long path just to activate your virtualenv every time.</blockquote>





## Installing Django


It's necessary to install Django in the virtualenv, rather than at a system-level. Once you've activated your virtualenv, run:

`$ pip install django`

This should give you the latest version of Django automatically.


<blockquote>**Tip:** For some people apparently, `manage.py` comes executable. That wasn't the case for me. To make your manage.py executable (so you can type `./manage.py` rather than `python ./manage.py`), run `chmod 755 manage.py`.</blockquote>




## Creating a Project


Creating a project in Django will make a new directory of that name. Run this command _in_ the parent directory you want for your project:

`$ django-admin.py startproject project_name`

You'll end up with a directory structure like this:

`/opt/env/project_name/project_name`

In the top project_name directory, you'll create apps. More on that in a bit.


<blockquote>**Tip:** Django has projects and apps. This project is like the overarching container, and each app is like a component of the project. Later we will also create the first app.</blockquote>





## Install South in virtualenv


[South](http://south.aeracode.org/) allows you to create an application without writing database-specific code. This is important to me, because I want to try my hand at several different databases while I work on my project. (Soon I will be Oracle-free, so soon...)

Still inside virtualenv, run:

`$ pip install south`

Should go smoothly. Now open up `settings.py` in the internal `project_name` directory. For me, it's `/opt/env/project_name/project_name/settings.py`. Search for `INSTALLED_APPS` and add 'south', as such:

`
INSTALLED_APPS = (
'django.contrib.auth',
'django.contrib.contenttypes',
'django.contrib.sessions',
'django.contrib.sites',
'django.contrib.messages',
'django.contrib.staticfiles',
'south'
# Uncomment the next line to enable the admin:
# 'django.contrib.admin',
# Uncomment the next line to enable admin documentation:
# 'django.contrib.admindocs',
)
`

Go to the top of the `settings.py` (`gg` in vim) and choose a database type. Doesn't matter what it is. I did SQL Lite so I wouldn't have to try and remember what my MySQL password is. It doesn't really matter when you're setting it up. Run:

`./manage.py syncdb`

South will be like yeah, awesome! This works!



## Create an App


Back to the app thing. Create an app:

`$ ./manage.py startapp my_app`

Then, go into your `settings.py` and add 'my_app' right underneath where we just added 'south'. Now we can do the initial migration with South:

`$ ./manage.py schemamigration my_app --initial`
`$ ./manage.py migrate my_app`



<blockquote>**Tip:** If, when you run `./manage.py help` you don't see a section of South's commands, that means Django isn't detecting South.</blockquote>





## Wrap up


That's basically it. Additionally, you should be using source control software such as git. Furthermore, you ought to separate your virtual environment from your development environment. I navigated to `/opt/dev/` and did a `git clone /opt/env/my_project` to bring the project into my dev environment. Make sure you commit in your virtualenv before cloning to your dev environment, or the changes and files won't copy over. Then, I can work in this environment without being in virtualenv unless I'm installing new modules.

I'll continue to chronicle my upcoming adventures with Python and Django. My next step is configuring Django to run on my Apache2 server alongside my other hosted sites and domains. I'm thinking I'll run it on a different port. More on that in the upcoming days!
