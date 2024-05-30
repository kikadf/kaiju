# kaiju

WIP repository to NetBSD support of Chromium and Chromium based apps.

### Guide

* Starting step to use repository

Get repositories:

`git clone git@github.com:kikadf/kaiju.git`

`git clone https://github.com/openbsd/ports.git`

* Working with repository

Get chromium to the version of OpenBSD port, apply OpenBSD patches,
apply the NetBSD delta patch from kaiju/patches/chromium,
check the changes in the reference Open-, FreeBSD files:

`cd kaiju`

`./update_vanilla.sh <chromium version>`

`./check_new_files.sh <chromium version>`

Finally fix the rejected parts of nb-delta.patch in chromium repo,
what is created by update_vanilla.sh, update the added NetBSD files
based on the output of check_new_files.sh, and commit:

`cd ../chromium-netbsd-*`

`git add . && git commit -m "Apply NetBSD patchset"`

* Create patches from chromium repo kaiju/patches/chromium
1) All changes over vanilla chromium: nb.patch
2) Changes over OpenBSD changes: nb-delta.patch

`git diff commithash HEAD > ../kaiju/patches/chromium/nb.patch` or

`git diff commithash commithash2 > ../kaiju/patches/chromium/nb-delta.patch` or

`git diff commithash > ../kaiju/patches/chromium/nb-delta.patch`
