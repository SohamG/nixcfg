{
  emacs-git-pgtk,
  webkitgtk_4_0,
  ccacheStdenv,
  lib,
  wrapGAppsHook3
}:

emacs-git-pgtk.overrideAttrs (old: {
  stdenv = ccacheStdenv;
  NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + "-O3 -march=znver1 -mtune=znver1";

})
