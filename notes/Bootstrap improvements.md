# Bootstrap improvements

- [ ] I made some manual changes to the files to improve clarity and writing
      style. please review.
- [ ] "verify ssh/wifi" but presumably we're already connected to wifi because
      we just used git clone on a github repo. Anyway I think this verification
      should be scripted, not in the MD file.
- [ ] I don't know if I really like the idea of having my deploy key be
      dependent on github and github auth. If we do want this "deploy keys"
      feature we need to talk through what they are, pros/cons, alternatives.
- [ ] There looks like a lot of stuff in the machine-specific setup that could
      be delegated to a script instead of written out in the MD file.
- [ ] I'm thinking we might just want to split out the bootstrapping MD files
      into separate ones for each purpose. So, some global bootstrapping in the
      root dir; but then some machine-specific bootstrpping in the hosts dirs.
