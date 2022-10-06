/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{ nixpkgs, lib ? nixpkgs.lib }:

let
  inherit (builtins) map;
  inherit (lib.lists) any;
in {

  /*
  Evaluates all nix tests in the included source files.

  Returns either a success string or a json result dump on failure.
  */
  evalNixTests =
    nixSrcs:
    let
      results = map (src: import src { inherit nixpkgs; }) nixSrcs;
      errorMsg = "[FAILURE] At least one nix test failed: ${builtins.toJSON results}.";
    in
      if any (x: x != []) results
      then throw errorMsg
      else "[SUCCESS] All tests passed.";

}
