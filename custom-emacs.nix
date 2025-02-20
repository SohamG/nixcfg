{
  emacs-pgtk,
  webkitgtk_4_0,
  ccacheStdenv,
  lib,
  wrapGAppsHook3
}:

emacs-pgtk.overrideAttrs (old: {
  stdenv = ccacheStdenv;
  NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + "-O3 -march=native -mtune=native";

})
