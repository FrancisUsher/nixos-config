---
id: captive-portal
aliases: []
tags: []
---
# Captive portal

## Lack of playwright

Claude majorly biffed this one up. It wrote the whole script but playwright
isn't even installed. Add playwright installation to the system-level
config and verify it works after that.

## Auto-regression script

I would assume that this won't "just work" a lot of the time. In cases where
it doesn't work I would like an easy way to snapshot the captive portal and
emulate it later for a regression case to keep the script robust with a
broad test suite.

## Security

Do a security analysis of this module. Am I taking any risks by connecting to
an insecure captive portal and automatically clicking through? Is there any
way for this to trigger a download or something that could introduce more
risks to my computer? Can I run the captive portal clickthrough in a stricter
sandbox or with more limitations on what I can enter?
