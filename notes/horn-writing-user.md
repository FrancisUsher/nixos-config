---
id: horn-writing-user
aliases: []
tags: []
---
# Distraction-free writing user "horn"

The user account **horn** would be a dedicated distraction-free writing
space that boots straight into a writing tool and does essentially
nothing else.

We can reference the backup files and configs from our SSD to see
exactly how we had this setup before.

## Narrative adaptation

Each user is a distinct narrative/thematic experience, not just a
funcitonally-tweaked variant but with unique visuals, user-experience
primitives, and conceptual theming.

## Technical considerations in nix

In adding `horn` we should split `home.nix` into

- a shared base, plus
- per-user configs, e.g. one for silk and one for horn
- Since we want it to boot straight into the writing tool, it should have
  its own greetd/session wiring (distinct from `silk`)
- Previously we used wordgrinder

## BYOK integration & syncing

Figure out how we can sync to/from BYOK without their shitty software.

