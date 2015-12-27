+++
author = Monica
comments = true
date = 2013-03-27 02:23:36+00:00
layout = post
slug = avoiding-the-oom-killer-by-limiting-the-number-of-apache2-processes
title = Avoiding the OOM Killer by limiting the number of Apache2 processes and clients
wordpress_id = 77
categories:
- Tech
tags:
- apache
- debian
+++

## Prologue


Last week I had the following mortifying experience: I tried to ssh into my box hosted at RackSpace and nothing happened. It simply hung, and never prompted me for my password. Commence panic. I determined that port 22 was, in fact, open, and I was connecting to the machine at some point.

    
    <code>> nc -zw3 monicalent.com 22
    > Connection to monicalent.com 22 port [tcp/ssh] succeeded!
    
    > telnet monicalent.com 22
    > Trying 198.101.205.52...
    Connected to monicalent.com.</code>


But...how can I fix whatever is wrong with this box if I can't even ssh into it?!

<!-- more -->

I was able to get into the box using RackSpace's web terminal. While it didn't allow me to type anything, I was able to get just enough information to determine what was causing the webserver, at least, not to respond:

    
    <code>[25020884.198143] Out of memory: kill process 4805 (apache2) score 46872 or a child
    [25020884.198150] Killed process 22433 (apache2)</code>


Awesome. I'm out of memory. I scroll up only to find out what is actually killing the processes: **OOM Killer**.


## Problem


Here's what I've learned. When you don't have any memory left on your box, OOM Killer will try to figure out what process is causing the problem. Apache has some default settings in apache2.conf which are not okay for a box with as little memory as mine has (256 MB). So it will run a bunch of apache2 processes, using up a ton of my memory. Obviously, if you are actually expecting a lot of web traffic (unlike me), you're just going to need a bigger box.

To see what processes are running on your machine, sorted by their memory usage, run the following command:


    
    <code class="language-bash">ps aux | awk '{print $2, $4, $11}' | sort -k2rn | head -n 15</code>




    
    <code>30077 12.4 /usr/sbin/apache2
    29920 12.0 /usr/sbin/apache2
    31319 11.0 /usr/sbin/apache2
    31320 11.0 /usr/sbin/apache2
    29915 10.6 /usr/sbin/apache2
    29194 10.2 /usr/sbin/apache2
    915 2.1 /usr/sbin/mysqld
    31321 1.2 /usr/sbin/apache2
    29186 0.9 /usr/sbin/apache2
    2075 0.4 ps</code>



Notice how Apache2 has a bunch of processes running, which are eating up double-digit percentages of my memory.


## Patch


Apache needs someone to tell it not to go overboard on creating all of these processes. When I open up /etc/apache2/apache2.conf, I find some interesting numbers.

    
    <code><IfModule mpm_prefork_module> 
    StartServers 5 
    MinSpareServers 5 
    MaxSpareServers 10 
    MaxClients 150 
    MaxRequestsPerChild 0 
    </IfModule></code>


Here's a quick breakdown on what this means:



	
  * StartServers: The number of server processes (as seen when we run `ps aux` or `top`) that apache starts automatically.

	
  * MinSpareServers: The minimum number of server processes apache will keep running in reserve, so they can be used as needed.

	
  * MaxSpareServers: The maximum number of server processes apache will keep running in reserve. Any processes in excess of this will be killed.

	
  * MaxClients: The maximum number of requests (GET, POST, etc.) that can be fielded at the same time. MaxKeepAliveRequests, earlier in this file, determines how many requests each connection can make before it has to re-establish. While keeping these numbers high is good for performance for your end-user, it's bad if you have a baby-sized server like me.

	
  * MaxRequestsPerChild: Number of requests a child process will handle before terminating.


Now, for a small server like mine, there is no way it's going to handle 150 clients simultaneously. Furthermore, it doesn't need to start with a dozen apache2 processes waiting for action it's never going to get. Following the [recommendations](http://articles.slicehost.com/2010/5/19/configuring-the-apache-mpm-on-ubuntu) of the folks at Slicehost, along with other resources, I use the following settings.

    
    <code><IfModule mpm_prefork_module>
    StartServers 2
    MinSpareServers 2
    MaxSpareServers 5
    MaxClients 40
    MaxRequestsPerChild 0
    </IfModule></code>


Now, when I check for memory usage on my machine after a restart of apache, I see that there are fewer apache processes going (thanks to my changes to StartServers, MinSpareServers, and MaxSpareServers). However, each apache process is using a greater percentage of memory a piece. So it becomes a bit of a balancing game to figure out what the proper numbers to put in ought to be.

Hopefully, however, since MaxClients has been reduced from 150 to 40, I will not cause my machine to dip into swap memory to comply with client requests. Further, it should be killing the other connections rather than keeping them alive.
