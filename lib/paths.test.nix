/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{ nixpkgs, lib ? nixpkgs.lib, test }:

let
  inherit (builtins) tryEval;

  inherit (lib.debug) runTests testAllTrue;

  sut = import ./paths.nix { inherit nixpkgs; };
in
  runTests {

    testFlattenPathTree = {
      expr = sut.flattenPathTree (test.fakePathTree ./. [ "a/b/c/2.y" "a/b/1.x" "f/g/3.z" ]);
      expected = [
        {
          dir = "a/b";
          file = "1.x";
          path = ./. + "/a/b/1.x";
        } {
          dir = "a/b/c";
          file = "2.y";
          path = ./. + "/a/b/c/2.y";
        } {
          dir = "f/g";
          file = "3.z";
          path = ./. + "/f/g/3.z";
        }
      ];
    };

  }
