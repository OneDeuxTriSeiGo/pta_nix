/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{
  nixpkgs ? import <nixpkgs>{},
  lib ? nixpkgs.lib,
  common ? import ./lib/common.nix { inherit nixpkgs; }
}:

let
  inherit (builtins) head groupBy isPath length tryEval;
  inherit (lib.attrsets) mapAttrs mapAttrsToList;
  inherit (lib.debug) runTests;
  inherit (lib.lists) drop sort;
  inherit (lib.strings) hasPrefix splitString;
  inherit (common) toEscapedNixStr;

  /* Implementation for fakePathTree */
  fakePathTree' =
    basePath:
    relPath:
    pathElems:
    let
      grouperFn = x:
        if length x == 1 && head x == "" then "noop"
        else if length x == 1 then "files"
        else if head x != "" then "dirs"
        else throw "Path Sequence ${toEscapedNixStr x} contains invalid sequence.";

      relpFn = cur: next: if cur == "" then next else "${cur}/${next}";

      srcFn = x: {
        dir = relPath;
        file = head x;
        path = basePath + "/${relPath}/${head x}";
      };

      elems = { dirs = []; files = []; noop = []; } // (groupBy grouperFn pathElems);
      subdirs = mapAttrs (k: v: map (drop 1) v) (groupBy head elems.dirs);
    in {
      path = basePath + "/${relPath}";
      srcs = map srcFn elems.files;
      dirs = mapAttrsToList (k: v: fakePathTree' basePath (relpFn relPath k) v) subdirs;
    };

in {

  /*
  Maps a set of key value pairs into named test cases and then run the tests lazily using Nix's
  inbuilt test evaluation system. Syntactic sugar.
  */
  runTestsWithName = attrs: runTests (mapAttrs (k: v: { expr = v; expected = true; }) attrs);

  /*
  Try evaluation of a given expression and report failure on successful evaluation and vice versa.
  Syntactic Sugar.
  */
  evalShouldFail = expr: tryEval expr == { success = false; value = false; };

  /*
  Takes a list of relative paths and builds a set representing the tree of directories and files
  contained in that list of paths. Directories can be declared with a trailing slash. Note that the
  paths do not have to be real as long as nothing attempts to read them.
  */
  fakePathTree =
    basePath:
    relPathStrs:
    let
      pathElems = map (splitString "/") (sort hasPrefix relPathStrs);
      pathTree = fakePathTree' basePath "" pathElems;
    in
      if isPath basePath
      then pathTree
      else throw "Base path ${toEscapedNixStr basePath} is not of type Path.";

}
