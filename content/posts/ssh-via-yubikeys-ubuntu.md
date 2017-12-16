+++
title = "Set up 2FA on Ubuntu with YubiKeys"
description = "Use your yubikey, combined with your publickey, to ssh into your favorite Ubuntu server with the touch of a finger."
author = "Monica Lent"
tags = ["ubuntu", "YubiKeys", "2FA"]
date = "2017-12-16T12:06:04+02:00"
+++

## What's a YubiKey?

A YubiKey is basically a tiny device that plugs into your USB slot and pretends
to be a keyboard. When you tap the little golden disc, it types out a
One Time Password (OTP). Through the Yubico API, you can easily validate this
password, and use it in combination with another method of authentication
(such as a password or ssh key) to achieve two-factor authentication (2FA).
Many popular websites like Google, Facebook, and Github allow you to enable
2FA via YubiKeys.

![YubiKeys](/blog/images/yubikeys.jpg "YubiKeys")

The idea is that even if your first "factor" of authentication like your
password or your ssh key were compromised, you'd have a second physical
factor that still keeps people out. The only way someone could log in to
your machine would be if they had both your (digital) password/key
and your (physical) YubiKey.

> Note: I'm not a security expert. There are a lot of ways to harden a machine,
> and adding a YubiKey as a form of two-factor authentication is just one
> way to make it more difficult to hack into.

This article is going to show you how to enable two-factor authentication
on your Ubuntu machine using a combination of publickey and YubiKey!

## How to use a YubiKey to SSH into an Ubuntu machine

I'm going to start with the assumption that you have already set up
your machine for SSH via public/private keypairs. If you haven't done that
yet, I would advise you to do it as a first step. [This article](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server) can help you accomplish that.

Here's how we're going to enable ssh access to an Ubuntu machine via YubiKey:

1. [Install the Yubico pam library]({{< relref "#install-yubico-library" >}})
2. [Generate an API key from Yubico]({{< relref "#get-api-key" >}})
3. [Update your pam settings to use YubiKeys]({{< relref "#pam-settings" >}})
4. [Update your `sshd_config` to authenticate via publickey and pam]({{< relref "#update-sshd_config" >}})
5. [Test it out!]({{< relref "#test-it-out" >}})

### 1. Install the Yubico pam library {#install-yubico-library}

```bash
$ sudo add-apt-repository ppa:yubico/stable
$ sudo apt-get update
$ sudo apt-get install libpam-yubico
```

### 2. Generate an API key from Yubico {#get-api-key}

Open the [Yubico Get API Key](https://upgrade.yubico.com/getapikey/) portal.
To generate a key, simply put in your email address, and focus your
cursor in the "YubiKey OTP" field and tap your Yubikey.

On the next page, you'll get two values: an `client id` and a `secret key`
that look something like this:

```bash
Client ID: 12345
Secret Key: 29384=hr2wCsdl+fi4tj4o3i
```

### 3. Update your pam settings to use YubiKeys {#pam-settings}

```bash
$ sudo vim /etc/pam.d/sshd
```

Here you need to do two things:

As the **first line in the file**, include the following (while obviously
replacing the values between square brackets with the values you got
from the Yubico API above):

```bash
auth required pam_yubico.so id=[Your Client ID] key=[Your Secret Key] debug authfile=/etc/yubikey_mappings mode=client
```

And also, comment out the following line:

```bash
@include common-auth
```

The reason is that without it, if someone fails to provide the OTP from
your YubiKey, they can simply fall back to providing the password (which
kind of defeats the point). This way, the YubiKey is required to authenticate.

Next, you're going to actually create the file at `/etc/yubikey_mappings`
and populate it with the first 12 characters of your YubiKey's OTP. Doing
this is pretty easy: just open the file, type the name of the user
for whom you want to enable authentication via YubiKey, and then
tap your YubiKey to output the password. Take the first 12 characters and
voila!

Here's roughly how it's going to look:

```bash
monica:jdlrkfosndhf
some_other_user:jdlrkfosndhf
```

If you want to add multiple YubiKeys so you can also have a backup,
just separate the values with a colon. For instance:

```bash
monica:lsofbrnfhgid:jfkrbdkfhsud
```

### 4. Update your `sshd_config` to authenticate via publickey and pam {#update-sshd_config}

Now that you have updated your pam settings to talk to the Yubico API
and get your tokens from a file, you need to tell SSH to use this for
authentication purposes.

```bash
$ sudo vim /etc/ssh/sshd_config
```

There are a few different settings you need to update. Some may already
be in your file, others you may need to add yourself:

```bash
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive:pam
UsePAM yes
```

Again, if you don't already have publickey authentication set up for your server,
there's a [great
tutorial](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server)
that can help you with that. Once you have successfully added your ssh
publickeys to the `authorized_keys` file on your server, you're going to want
to make sure you have these things enabled as well:

```bash
PubkeyAuthentication yes
AuthorizedKeysFile      %h/.ssh/authorized_keys
PasswordAuthentication no
```

This will disable the ability of people to log in with a password, and instead
use the publickey. In combination with the settings above, you should
be able to log in to your server using your ssh keys and YubiKey!

Restart the `sshd` service to enable the updated settings:

```bash
$ service sshd restart
```

> **NOTE** Don't close the session you have open while you are editing
> these settings, or you risk locking yourself out of your machine!

### 5. Test it out {#test-it-out}

In another terminal session, try logging in to your machine without supplying
any kind of password.

```bash
$ ssh monica@my-machine
YubiKey for `monica': 
```

It should then prompt you to tap your YubiKey. Do so, and the YubiKey will
transmit the OTP and log you into the system. Congratulations!

## Troubleshooting

There were a few things that went wrong while I was setting this up, hopefully
they help you out.

### Permission denied (publickey)

**Make sure you're logged in as the right user** on the machine from which
you're trying to ssh into the remote machine. Also make sure that
this user has keys which have been placed on the remote machine as well.

**Restart the ssh agent** in case it is no longer running. You can easily do
that, and add your relevant key to it, as follows:

```bash
$ eval `ssh-agent -s`
$ ssh-add ~/.ssh/id_rsa
```

It's good practice to generate a new key for every service or new machine
you're going to be connecting to. If you do generate a different key for this
particular machine, be sure to pass that to `ssh-add` rather than the
default key.

### SSH falling back to password if YubiKey auth fails

When I was first testing out my awesome new YubiKey setup, I realized that
if I provided the wrong YubiKey value, it would fall back to asking
for a password -- which is _kind of_ besides the point:

```bash
$ ssh monica@my-machine
YubiKey for `monica': # Bad value provided
Password:
```

Double-check that you commented out `@include common-auth` in your
`/etc/pam.d/sshd` file. You can set everything else up correctly,
but leaving this line will still cause the machine to fall back to asking
for a password during ssh if authentication via YubiKey fails.

## More resources for working with your YubiKeys

I first started this process using [this
article](https://medium.com/@james_poole/yubikey-2fa-on-ubuntu-ssh-e09b4e91bfc8).
Since then, I've also discovered [this other article](https://github.com/drduh/YubiKey-Guide)
with a lot more detailed information on using your YubiKey for GPG and SSH via
gpg-agent. Have fun!
