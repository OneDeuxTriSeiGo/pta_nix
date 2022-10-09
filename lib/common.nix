/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{ nixpkgs, lib ? nixpkgs.lib }:

let
  inherit (builtins) toString;
  inherit (lib.strings) escapeNixString;

in {

  /* Converts an expression to a string and escapes it for debug printing */
  toEscapedNixStr = x: escapeNixString (toString x);

}
