/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{
  description = "A plain text accounting framework using nix";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }:
    let
      testUtils = import ./nix/test.nix { inherit nixpkgs; };
    in {
      pta = import ./lib { inherit nixpkgs; };

      tests = testUtils.evalNixTests [
        ./lib/dates.test.nix
      ];

      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    };
}
