/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{ nixpkgs, lib ? nixpkgs.lib }:

let
  inherit (builtins) length listToAttrs map readDir;

  inherit (lib.attrsets) mapAttrs mapAttrsToList nameValuePair;

  inherit (lib.lists) concatMap genList groupBy;

  inherit (lib.strings) concatStrings concatStringsSep optionalString splitString;

  inherit (lib.trivial) flip pipe;

  /* Implementation for pathTree */
  pathTree' = basep: relp: pipe (readDir (basep + "/${relp}")) [
    ( mapAttrsToList (k: v: { dir = k; type = v; }) )
    ( groupBy (x: x.type) )
    ( mapAttrs (k: map (x: x.dir)) )
    ( x: map (k: nameValuePair k x."${k}" or [] ) [ "regular" "directory" ] )
    ( listToAttrs )
    ( x: {
      path = basep + "/${relp}";
      srcs = map (v: { dir = relp; file = v; path = basep + "/${relp}/${v}"; }) x.regular;
      dirs = map (v: pathTree' basep (if relp == "" then v else relp + "/${v}")) x.directory;
    } )
  ];

  /* Implementation for flattenPathTree */
  flattenPathTree' = tree: tree.srcs ++ concatMap flattenPathTree' tree.dirs;

in {

  /*
  Converts a relative path regex pattern into a sourceByRegex pattern. The pattern must not contain
  forward slashes ("/") other than as path separators.
  */
  relPathRegex = (flip pipe) [
    (splitString "/")
    (x: { p = x; n = length x; })
    (x: x // {p = concatStringsSep "(/" x.p; })
    (x: x.p + optionalString (x.n > 1) (concatStrings (genList (i: ")?") (x.n - 1))))
  ];


  /*
  Evaluates a source tree and returns a tree of source files of the form:

  type: srcPath = { dir = relativePathToDir; file = filename; path = path; }
  type: dirTree = { dirs = [ dirTree... ]; path = path; srcs = [ srcPath... ]; }
  */
  pathTree = dir: pathTree' dir "";

  /* Flattens a path tree to a list of paths to files contained within. */
  flattenPathTree = tree: flattenPathTree' tree;

}
