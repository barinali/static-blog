+++
title = "Writing Haskell with Vim"
description = "Tools you can you use with Vim to make writing Haskell more fun, plus troubleshooting tips"
author = "Monica Lent"
tags = ["haskell", "stack", "vim", "ale", "linting"]
date = "2017-11-19T12:06:04+02:00"

+++

Getting started writing any new language is easier with the help of your editor.
In the case of linters, they can teach you the language's idioms and best
practices while you write your first lines of code. Here's how to set up
a new project in Haskell and configure vim for Haskell.

## Basic vim setup for Haskell

What you're going to need:

- Vim 8
- Your `.vimrc`
- A vim package manager (here I use vundle)
  - Airline (Vim status bar)
  - ALE (Linting engine)
  - ghcmod-vim (Reveal types inline)
- Haskell / ghc
- Stack
- ghc-mod, hlint, hdevtools, hfmt

This tutorial assumes you already have Vim 8 installed.

### Install vundle

If you don't already have a package manager for vim, you can pick
just about any on the market. I'm using Vundle, which is easy to add
by amending your `.vimrc` with just a few lines.

```vim
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'

call vundle#end()
```

### Install your Haskell-friendly vim plugins

There are a few plugins for Vim that will make writing Haskell more fruitful,
including [Airline](https://github.com/vim-airline/vim-airline) and
[ALE](https://github.com/w0rp/ale).

Airline provides you with a sexy status bar inside your vim that integrates
with ALE, a linting engine which will asyncronously run your code through
a few different Haskell linters and report the information back to you
inside vim itself.

GchMod-vim can reveal types inside your code, and this plugin depends
on `vimproc` which you'll install with vundle and compile by
going into `~/.vim/bundle/vimproc` and running `make`.

To get started, update your `.vimrc` and, while the file is open, you execute
`:PluginInstall`.

```vim
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
" Plugin 'mlent/ale' -- Has a small change for multi-line ghc errors, see below
Plugin 'w0rp/ale'
Plugin 'vim-airline/vim-airline'
Plugin 'eagletmt/ghcmod-vim'
Plugin 'Shougo/vimproc'

call vundle#end()

let g:airline#extensions#ale#enabled = 1

nnoremap <Leader>ht :GhcModType<cr>
nnoremap <Leader>htc :GhcModTypeClear<cr>
autocmd FileType haskell nnoremap <buffer> <leader>? :call ale#cursor#ShowCursorDetail()<cr>
```

This first line after the plugins list enables Airline to report ALE
information to you.

The second two are conveniet ways to call the ghc type checker and get that
information inside vim.

And the last line allows you to show multi-line errors in vim by combining
your `<Leader>` key + ?. Unfortunately this only works if you use [my
fork of ALE](https://github.com/mlent/ale), but there are changes coming
in the next ALE release which should make this work with the main repository.
For example:

```bash
  Couldn't match expected typeIO [FilePath]’
  with actual typeFilePath -> IO [FilePath]’
  Probable cause: getDirectoryContents is applied to too few arguments
    In the expression: getDirectoryContents
    In an equation for findPost: findPosts x = getDirectoryContents
```

### Install Haskell and relevant tooling

After you've installed Haskell system-wide, you can also install
[Stack](https://docs.haskellstack.org/en/stable/README/). If you're familiar
with [Python](/blog/tags/python/)'s virtualenv and pip, it's a little bit
similar in that Stack gives you an isolated environment and a package
manager, but in one tool.

```bash
# Install Stack
❯ curl -sSL https://get.haskellstack.org/ | sh
```

If you're creating a new project, you do do this with:

```bash
# Create a new project, if needed
❯ stack new my-project # Directory must not already exist
❯ cd my-project
❯ stack setup
❯ stack build
❯ stack exec my-project-exe
```

Note that your directory now contains a `my-project.cabal` file. This file
is what informs your linters where your modules are. If you create
more modules, you need to expose them through this file.

Otherwise, continue to install the tools that ALE is going to use
to lint our Haskell files.

```bash
stack install ghc-mod hlint hdevtools hfmt
```

Some of these may already be installed on your system, but will be copied
to a directory where you can access them directly through the commandline.
For instance, if you want to run `hlint` on your code, all you have to do
now is execute:

```bash
❯ hlint src 
No hints
```

That's what happens if your code is suuuuuper clean! You can also run

## Troubleshooting

### Ale/vim cannot find modules

Since Ale/vim are running against files stored in `/tmp`, in means they
don't have sufficient context to find your `.cabal` file in your project
root. Since that's where your library directory and exports are declared,
it's missing the information needed to determine the names and functions
exported by your other modules (including modules in the same directory!)

If you're having this problem, you'll see lines like:

```bash
Failed to load interface for YourModuleName. Use -v to see a list of the files searched for.
```

In vim. If you use `:ALEInfo` and <kbd>Shift</kbd> + <kbd>G</kbd>, you'll find
more details about the error which looks something like this:

```bash
(finished - exit code 1) ['/usr/local/bin/zsh', '-c', 'stack ghc -- -fno-code -v0 ''/tmp/vvzQVxy/8/Cli.hs''']
<<<OUTPUT STARTS>>>
  /tmp/vvzQVxy/8/Cli.hs:7:1: error:
  Failed to load interface for YourModuleName
  Use -v to see a list of the files searched for.
<<<OUTPUT ENDS>>>
```

A simple fix for this is to edit your `.vimrc` and 

```vim
let g:ale_linters = {
    \   'haskell': ['stack-ghc', 'ghc-mod', 'hlint', 'hdevtools', 'hfmt'],
    \}
```

### Executable named my-project-exec not found on path

This error isn't specific to the vim setup, but is something you might
encounter while working with Haskell and Stack.

```bash
❯ stack exec my-project-exec
Executable named my-project-exec not found on path: ["/opt/bstats/.stack-work/install/x86_64-osx/lts-9.10/8.0.2/bin","/private/var/root/.stack/snapshots/x86_64-osx/lts-9.10/8.0.2/bin","/private/var/root/.stack/programs/x86_64-osx/ghc-8.0.2/bin","/private/var/root/google-cloud-sdk/bin","/usr/local/bin","/usr/local/bin","/usr/bin","/bin","/usr/sbin","/sbin","/private/var/root/google-cloud-sdk/bin","/usr/local/opt/go/libexec/bin","/var/root/Go/bin","/usr/local/opt/go/libexec/bin","/private/var/root/.local/bin","/var/root/Go/bin"]
```

The solution is to take care when executing `stack exec` take note that you type `my-project-exe` and
not `my-project-exec`.

## That's a wrap!

Stay tuned for more tips on writing your first Haskell project.

* * *

## Questions, Comments, Corrections?

Get in touch via Twitter at [@monicalent](http://www.twitter.com/monicalent).
