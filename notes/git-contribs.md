---
id: git-contribs
aliases: []
tags: []
---
# Git contributions

Record here some open-source contributions I would like to make but haven't
gotten around to yet, so I don't forget.

## Vimium - Tab group control

Someone already put in a PR for this.
Figure out why it stalled out and see if we can help it along.

https://github.com/philc/vimium/pull/4858/changes

## Stylix - live theme changing

There's some discussion here about this.
I think the issue is, how to make this without sacrificing the "immutability"
characteristics Nix users feel like they have in their system due to the
compiled config builds.

https://github.com/nix-community/stylix/discussions/371

Probably the way to go on this is to compile *how* themes are applied, but
leave the specific theme color variables to the runtime. See the `pywal`
related PR linked at the bottom of that discussion thread:

https://github.com/nix-community/stylix/issues/99
