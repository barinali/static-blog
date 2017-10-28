+++
title = "Writing Haskell with Vim"
description = "Tools you can you use with Vim to make writing Haskell more fun, plus troubleshooting tips"
author = ""
tags = [
]
date = "2017-10-28T16:06:04+02:00"

+++

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

    let g:ale_linters ={
          \   'haskell': ['ghc', 'stack-ghc', 'ghc-mod', 'hlint', 'hdevtools', 'hfmt'],
          \}
