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
      common = import ./lib/common.nix { inherit nixpkgs; };
      testRunner = import ./nix/testRunner.nix { inherit nixpkgs common; };
    in {
      pta = import ./lib/accounting.nix { inherit nixpkgs; };

      tests = testRunner.evalNixTests [
        ./lib/dates.test.nix
        ./lib/paths.test.nix
        ./lib/accounting.test.nix
      ];

      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    };
}
