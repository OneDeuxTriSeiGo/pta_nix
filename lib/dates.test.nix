/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{ nixpkgs, lib ? nixpkgs.lib }:

let
  inherit (builtins) tryEval;

  inherit (lib.debug) runTests testAllTrue;

  sut = import ./dates.nix { inherit nixpkgs; };
in
  runTests {

    testToDate = testAllTrue [
      ( sut.toDate "2000"       == [ 2000       ] )
      ( sut.toDate "2000.01"    == [ 2000  1    ] )
      ( sut.toDate "2000.1"     == [ 2000  1    ] )
      ( sut.toDate "2000.01.05" == [ 2000  1  5 ] )
      ( sut.toDate "2000.1.5"   == [ 2000  1  5 ] )
    ];

    testisLeapYear = testAllTrue [
      # Divisible by 4
      (   sut.isLeapYear 1996 )
      # Not divisible by 4
      ( ! sut.isLeapYear 1999 )
      # Divisible by 4 and 100 but not 400
      ( ! sut.isLeapYear 1900 )
      # Divisible by 400
      (   sut.isLeapYear 2000 )
    ];

    #testDateFormats = testAllTrue [
    #  (tryEval (sut.gapChecker "2020-01-01" "2020-01-02") == { success = false; value = false; })
    #];

    testGapChecker = testAllTrue [
      # Year to year
      (   sut.gapChecker "2001"       "2002"       )
      ( ! sut.gapChecker "2001"       "2003"       )
      # Month to Month, Same Year
      (   sut.gapChecker "2001.01"    "2001.02"    )
      (   sut.gapChecker "2001.03"    "2001.04"    )
      ( ! sut.gapChecker "2001.01"    "2001.03"    )
      ( ! sut.gapChecker "2001.03"    "2001.05"    )
      # Month to Month, Cross Year
      (   sut.gapChecker "2001.12"    "2002.01"    )
      ( ! sut.gapChecker "2001.12"    "2002.03"    )
      ( ! sut.gapChecker "2001.01"    "2002.01"    )
      # Day to Day, Same Month
      (   sut.gapChecker "2001.01.01" "2001.01.02" )
      (   sut.gapChecker "2001.01.12" "2001.01.13" )
      ( ! sut.gapChecker "2001.01.12" "2001.01.15" )
      # Day to Day, Jan -> Feb
      (   sut.gapChecker "2001.01.30" "2001.01.31" )
      (   sut.gapChecker "2001.01.31" "2001.02.01" )
      (   sut.gapChecker "2001.01.31" "2001.02"    )
      ( ! sut.gapChecker "2001.01.29" "2001.01.31" )
      ( ! sut.gapChecker "2001.01.30" "2001.02.01" )
      ( ! sut.gapChecker "2001.01.31" "2001.02.02" )
      # Day to Day, Feb
      (   sut.gapChecker "2001.02.27" "2001.02.28" )
      (   sut.gapChecker "2001.02.28" "2001.03.01" )
      (   sut.gapChecker "2001.02.28" "2001.03"    )
      ( ! sut.gapChecker "2001.02.28" "2001.03.02" )
      ( ! sut.gapChecker "2001.02.27" "2001.03.02" )
      # Day to Day, Feb, Year % 4
      (   sut.gapChecker "2004.02.28" "2004.02.29" )
      (   sut.gapChecker "2004.02.29" "2004.03.01" )
      (   sut.gapChecker "2004.02.29" "2004.03"    )
      ( ! sut.gapChecker "2004.02.27" "2004.02.29" )
      ( ! sut.gapChecker "2004.02.29" "2004.03.02" )
      ( ! sut.gapChecker "2004.02.28" "2004.03.01" )
      # Day to Day, Feb, Year % 4, Year % 100
      (   sut.gapChecker "1900.02.27" "1900.02.28" )
      (   sut.gapChecker "1900.02.28" "1900.03.01" )
      (   sut.gapChecker "1900.02.28" "1900.03"    )
      ( ! sut.gapChecker "1900.02.28" "1900.03.02" )
      ( ! sut.gapChecker "1900.02.27" "1900.03.02" )
      # Day to Day, Feb, Year % 400
      (   sut.gapChecker "2000.02.28" "2000.02.29" )
      (   sut.gapChecker "2000.02.29" "2000.03.01" )
      (   sut.gapChecker "2000.02.29" "2000.03"    )
      ( ! sut.gapChecker "2000.02.27" "2000.02.29" )
      ( ! sut.gapChecker "2000.02.29" "2000.03.02" )
      ( ! sut.gapChecker "2000.02.28" "2000.03.01" )
      # Day to Day, Mar -> Apr
      (   sut.gapChecker "2001.03.30" "2001.03.31" )
      (   sut.gapChecker "2001.03.31" "2001.04.01" )
      (   sut.gapChecker "2001.03.31" "2001.04"    )
      ( ! sut.gapChecker "2001.03.29" "2001.03.31" )
      ( ! sut.gapChecker "2001.03.30" "2001.04.01" )
      ( ! sut.gapChecker "2001.03.31" "2001.04.02" )
      # Day to Day, Apr -> May
      (   sut.gapChecker "2001.04.29" "2001.04.30" )
      (   sut.gapChecker "2001.04.30" "2001.05.01" )
      (   sut.gapChecker "2001.04.30" "2001.05"    )
      ( ! sut.gapChecker "2001.04.28" "2001.04.30" )
      ( ! sut.gapChecker "2001.04.29" "2001.05.01" )
      ( ! sut.gapChecker "2001.04.30" "2001.05.02" )
      # Day to Day, May -> Jun
      (   sut.gapChecker "2001.05.30" "2001.05.31" )
      (   sut.gapChecker "2001.05.31" "2001.06.01" )
      (   sut.gapChecker "2001.05.31" "2001.06"    )
      ( ! sut.gapChecker "2001.05.29" "2001.05.31" )
      ( ! sut.gapChecker "2001.05.30" "2001.06.01" )
      ( ! sut.gapChecker "2001.05.31" "2001.06.02" )
      # Day to Day, Jun -> Jul
      (   sut.gapChecker "2001.06.29" "2001.06.30" )
      (   sut.gapChecker "2001.06.30" "2001.07.01" )
      (   sut.gapChecker "2001.06.30" "2001.07"    )
      ( ! sut.gapChecker "2001.06.28" "2001.06.30" )
      ( ! sut.gapChecker "2001.06.29" "2001.07.01" )
      ( ! sut.gapChecker "2001.06.30" "2001.07.02" )
      # Day to Day, Jul -> Aug
      (   sut.gapChecker "2001.07.30" "2001.07.31" )
      (   sut.gapChecker "2001.07.31" "2001.08.01" )
      (   sut.gapChecker "2001.07.31" "2001.08"    )
      ( ! sut.gapChecker "2001.07.29" "2001.07.31" )
      ( ! sut.gapChecker "2001.07.30" "2001.08.01" )
      ( ! sut.gapChecker "2001.07.31" "2001.08.02" )
      # Day to Day, Aug -> Sep
      (   sut.gapChecker "2001.08.30" "2001.08.31" )
      (   sut.gapChecker "2001.08.31" "2001.09.01" )
      (   sut.gapChecker "2001.08.31" "2001.09"    )
      ( ! sut.gapChecker "2001.08.29" "2001.08.31" )
      ( ! sut.gapChecker "2001.08.30" "2001.09.01" )
      ( ! sut.gapChecker "2001.08.31" "2001.09.02" )
      # Day to Day, Sep -> Oct
      (   sut.gapChecker "2001.09.29" "2001.09.30" )
      (   sut.gapChecker "2001.09.30" "2001.10.01" )
      (   sut.gapChecker "2001.09.30" "2001.10"    )
      ( ! sut.gapChecker "2001.09.28" "2001.09.30" )
      ( ! sut.gapChecker "2001.09.29" "2001.10.01" )
      ( ! sut.gapChecker "2001.09.30" "2001.10.02" )
      # Day to Day, Oct -> Nov
      (   sut.gapChecker "2001.10.30" "2001.10.31" )
      (   sut.gapChecker "2001.10.31" "2001.11.01" )
      (   sut.gapChecker "2001.10.31" "2001.11"    )
      ( ! sut.gapChecker "2001.10.29" "2001.10.31" )
      ( ! sut.gapChecker "2001.10.30" "2001.11.01" )
      ( ! sut.gapChecker "2001.10.31" "2001.11.02" )
      # Day to Day, Nov -> Dec
      (   sut.gapChecker "2001.11.29" "2001.11.30" )
      (   sut.gapChecker "2001.11.30" "2001.12.01" )
      (   sut.gapChecker "2001.11.30" "2001.12"    )
      ( ! sut.gapChecker "2001.11.28" "2001.11.30" )
      ( ! sut.gapChecker "2001.11.29" "2001.12.01" )
      ( ! sut.gapChecker "2001.11.30" "2001.12.02" )
      # Day to Day, Dec -> Jan
      (   sut.gapChecker "2001.12.30" "2001.12.31" )
      (   sut.gapChecker "2001.12.31" "2002.01.01" )
      (   sut.gapChecker "2001.12.31" "2002.01"    )
      (   sut.gapChecker "2001.12.31" "2002"       )
      ( ! sut.gapChecker "2001.12.29" "2001.12.31" )
      ( ! sut.gapChecker "2001.12.30" "2002.01.01" )
      ( ! sut.gapChecker "2001.12.31" "2002.01.02" )
    ];

    testGapChecker_errors = testAllTrue [
      (tryEval (sut.gapChecker "2000-01-01" ""           ) == { success = false; value = false; })
      (tryEval (sut.gapChecker ""           "2000-01-01" ) == { success = false; value = false; })
    ];

  }
