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

  withXwidgets = true;

  buildInputs = old.buildInputs ++ [ webkitgtk_4_0.dev ];
  nativeBuildInputs = old.nativeBuildInputs ++ [ wrapGAppsHook3 webkitgtk_4_0.dev ];
  configureFlags = (lib.lists.remove "--without-xwidgets" old.configureFlags) ++ ["--with-xwidgets"];
})
