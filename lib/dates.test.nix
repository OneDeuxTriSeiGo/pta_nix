/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{ nixpkgs, lib ? nixpkgs.lib, test }:

let
  sut = import ./dates.nix { inherit nixpkgs; };
in
  test.runTestsWithName {

    testToDate_YYYY       = ( sut.toDate "2000"       == [ 2000       ] );
    testToDate_YYYY_MM    = ( sut.toDate "2000.01"    == [ 2000  1    ] );
    testToDate_YYYY_M     = ( sut.toDate "2000.1"     == [ 2000  1    ] );
    testToDate_YYYY_MM_DD = ( sut.toDate "2000.01.05" == [ 2000  1  5 ] );
    testToDate_YYYY_MM_D  = ( sut.toDate "2000.01.5"  == [ 2000  1  5 ] );
    testToDate_YYYY_M_DD  = ( sut.toDate "2000.1.05"  == [ 2000  1  5 ] );
    testToDate_YYYY_M_D   = ( sut.toDate "2000.1.5"   == [ 2000  1  5 ] );

    testIsLeapYear_Y4_N100_N400 = (   sut.isLeapYear 1996 );
    testIsLeapYear_N4_N100_N400 = ( ! sut.isLeapYear 1999 );
    testIsLeapYear_Y4_Y100_N400 = ( ! sut.isLeapYear 1900 );
    testIsLeapYear_Y4_Y100_Y400 = (   sut.isLeapYear 2000 );

    #testDateFormats = testAllTrue [
    #  (tryEval (sut.gapChecker "2020-01-01" "2020-01-02") == { success = false; value = false; })
    #];

    testGapChecker_cont_YtoY                      = (   sut.gapChecker "2001"       "2002"       );
    testGapChecker_disj_YtoY                      = ( ! sut.gapChecker "2001"       "2003"       );

    testGapChecker_cont_YMtoYM_sY_1               = (   sut.gapChecker "2001.01"    "2001.02"    );
    testGapChecker_cont_YMtoYM_sY_2               = (   sut.gapChecker "2001.03"    "2001.04"    );
    testGapChecker_disj_YMtoYM_sY_1               = ( ! sut.gapChecker "2001.01"    "2001.03"    );
    testGapChecker_disj_YMtoYM_sY_2               = ( ! sut.gapChecker "2001.03"    "2001.05"    );

    testGapChecker_cont_YMtoYM_xY                 = (   sut.gapChecker "2001.12"    "2002.01"    );
    testGapChecker_disj_YMtoYM_xY_1               = ( ! sut.gapChecker "2001.12"    "2002.03"    );
    testGapChecker_disj_YMtoYM_xY_2               = ( ! sut.gapChecker "2001.01"    "2002.01"    );

    testGapChecker_cont_YMDtoYMD_sY_sM_1          = (   sut.gapChecker "2001.01.01" "2001.01.02" );
    testGapChecker_cont_YMDtoYMD_sY_sM_2          = (   sut.gapChecker "2001.01.12" "2001.01.13" );
    testGapChecker_disj_YMDtoYMD_sY_sM            = ( ! sut.gapChecker "2001.01.12" "2001.01.15" );

    testGapChecker_cont_YMDtoYMD_JanToFeb_1       = (   sut.gapChecker "2001.01.30" "2001.01.31" );
    testGapChecker_cont_YMDtoYMD_JanToFeb_2       = (   sut.gapChecker "2001.01.31" "2001.02.01" );
    testGapChecker_cont_YMDtoYMD_JanToFeb_3       = (   sut.gapChecker "2001.01.31" "2001.02"    );
    testGapChecker_disj_YMDtoYMD_JanToFeb_1       = ( ! sut.gapChecker "2001.01.29" "2001.01.31" );
    testGapChecker_disj_YMDtoYMD_JanToFeb_2       = ( ! sut.gapChecker "2001.01.30" "2001.02.01" );
    testGapChecker_disj_YMDtoYMD_JanToFeb_3       = ( ! sut.gapChecker "2001.01.31" "2001.02.02" );

    testGapChecker_cont_YMDtoYMD_FebToMar_Yndv4_1 = (   sut.gapChecker "2001.02.27" "2001.02.28" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Yndv4_2 = (   sut.gapChecker "2001.02.28" "2001.03.01" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Yndv4_3 = (   sut.gapChecker "2001.02.28" "2001.03"    );
    testGapChecker_disj_YMDtoYMD_FebToMar_Yndv4_1 = ( ! sut.gapChecker "2001.02.26" "2001.02.28" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Yndv4_2 = ( ! sut.gapChecker "2001.02.28" "2001.03.02" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Yndv4_3 = ( ! sut.gapChecker "2001.02.27" "2001.03.02" );

    testGapChecker_cont_YMDtoYMD_FebToMar_Y4_1    = (   sut.gapChecker "2004.02.28" "2004.02.29" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Y4_2    = (   sut.gapChecker "2004.02.29" "2004.03.01" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Y4_3    = (   sut.gapChecker "2004.02.29" "2004.03"    );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y4_1    = ( ! sut.gapChecker "2004.02.27" "2004.02.29" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y4_2    = ( ! sut.gapChecker "2004.02.29" "2004.03.02" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y4_3    = ( ! sut.gapChecker "2004.02.28" "2004.03.01" );

    testGapChecker_cont_YMDtoYMD_FebToMar_Y100_1  = (   sut.gapChecker "1900.02.27" "1900.02.28" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Y100_2  = (   sut.gapChecker "1900.02.28" "1900.03.01" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Y100_3  = (   sut.gapChecker "1900.02.28" "1900.03"    );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y100_1  = ( ! sut.gapChecker "1900.02.26" "1900.02.28" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y100_2  = ( ! sut.gapChecker "1900.02.28" "1900.03.02" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y100_3  = ( ! sut.gapChecker "1900.02.27" "1900.03.02" );

    testGapChecker_cont_YMDtoYMD_FebToMar_Y400_1  = (   sut.gapChecker "2000.02.28" "2000.02.29" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Y400_2  = (   sut.gapChecker "2000.02.29" "2000.03.01" );
    testGapChecker_cont_YMDtoYMD_FebToMar_Y400_3  = (   sut.gapChecker "2000.02.29" "2000.03"    );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y400_1  = ( ! sut.gapChecker "2000.02.27" "2000.02.29" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y400_2  = ( ! sut.gapChecker "2000.02.29" "2000.03.02" );
    testGapChecker_disj_YMDtoYMD_FebToMar_Y400_3  = ( ! sut.gapChecker "2000.02.28" "2000.03.01" );

    testGapChecker_cont_YMDtoYMD_MarToApr_1       = (   sut.gapChecker "2001.03.30" "2001.03.31" );
    testGapChecker_cont_YMDtoYMD_MarToApr_2       = (   sut.gapChecker "2001.03.31" "2001.04.01" );
    testGapChecker_cont_YMDtoYMD_MarToApr_3       = (   sut.gapChecker "2001.03.31" "2001.04"    );
    testGapChecker_disj_YMDtoYMD_MarToApr_1       = ( ! sut.gapChecker "2001.03.29" "2001.03.31" );
    testGapChecker_disj_YMDtoYMD_MarToApr_2       = ( ! sut.gapChecker "2001.03.30" "2001.04.01" );
    testGapChecker_disj_YMDtoYMD_MarToApr_3       = ( ! sut.gapChecker "2001.03.31" "2001.04.02" );

    testGapChecker_cont_YMDtoYMD_AprToMay_1       = (   sut.gapChecker "2001.04.29" "2001.04.30" );
    testGapChecker_cont_YMDtoYMD_AprToMay_2       = (   sut.gapChecker "2001.04.30" "2001.05.01" );
    testGapChecker_cont_YMDtoYMD_AprToMay_3       = (   sut.gapChecker "2001.04.30" "2001.05"    );
    testGapChecker_disj_YMDtoYMD_AprToMay_1       = ( ! sut.gapChecker "2001.04.28" "2001.04.30" );
    testGapChecker_disj_YMDtoYMD_AprToMay_2       = ( ! sut.gapChecker "2001.04.29" "2001.05.01" );
    testGapChecker_disj_YMDtoYMD_AprToMay_3       = ( ! sut.gapChecker "2001.04.30" "2001.05.02" );

    testGapChecker_cont_YMDtoYMD_MayToJun_1       = (   sut.gapChecker "2001.05.30" "2001.05.31" );
    testGapChecker_cont_YMDtoYMD_MayToJun_2       = (   sut.gapChecker "2001.05.31" "2001.06.01" );
    testGapChecker_cont_YMDtoYMD_MayToJun_3       = (   sut.gapChecker "2001.05.31" "2001.06"    );
    testGapChecker_disj_YMDtoYMD_MayToJun_1       = ( ! sut.gapChecker "2001.05.29" "2001.05.31" );
    testGapChecker_disj_YMDtoYMD_MayToJun_2       = ( ! sut.gapChecker "2001.05.30" "2001.06.01" );
    testGapChecker_disj_YMDtoYMD_MayToJun_3       = ( ! sut.gapChecker "2001.05.31" "2001.06.02" );

    testGapChecker_cont_YMDtoYMD_JunToJul_1       = (   sut.gapChecker "2001.06.29" "2001.06.30" );
    testGapChecker_cont_YMDtoYMD_JunToJul_2       = (   sut.gapChecker "2001.06.30" "2001.07.01" );
    testGapChecker_cont_YMDtoYMD_JunToJul_3       = (   sut.gapChecker "2001.06.30" "2001.07"    );
    testGapChecker_disj_YMDtoYMD_JunToJul_1       = ( ! sut.gapChecker "2001.06.28" "2001.06.30" );
    testGapChecker_disj_YMDtoYMD_JunToJul_2       = ( ! sut.gapChecker "2001.06.29" "2001.07.01" );
    testGapChecker_disj_YMDtoYMD_JunToJul_3       = ( ! sut.gapChecker "2001.06.30" "2001.07.02" );

    testGapChecker_cont_YMDtoYMD_JulToAug_1       = (   sut.gapChecker "2001.07.30" "2001.07.31" );
    testGapChecker_cont_YMDtoYMD_JulToAug_2       = (   sut.gapChecker "2001.07.31" "2001.08.01" );
    testGapChecker_cont_YMDtoYMD_JulToAug_3       = (   sut.gapChecker "2001.07.31" "2001.08"    );
    testGapChecker_disj_YMDtoYMD_JulToAug_1       = ( ! sut.gapChecker "2001.07.29" "2001.07.31" );
    testGapChecker_disj_YMDtoYMD_JulToAug_2       = ( ! sut.gapChecker "2001.07.30" "2001.08.01" );
    testGapChecker_disj_YMDtoYMD_JulToAug_3       = ( ! sut.gapChecker "2001.07.31" "2001.08.02" );

    testGapChecker_cont_YMDtoYMD_AugToSep_1       = (   sut.gapChecker "2001.08.30" "2001.08.31" );
    testGapChecker_cont_YMDtoYMD_AugToSep_2       = (   sut.gapChecker "2001.08.31" "2001.09.01" );
    testGapChecker_cont_YMDtoYMD_AugToSep_3       = (   sut.gapChecker "2001.08.31" "2001.09"    );
    testGapChecker_disj_YMDtoYMD_AugToSep_1       = ( ! sut.gapChecker "2001.08.29" "2001.08.31" );
    testGapChecker_disj_YMDtoYMD_AugToSep_2       = ( ! sut.gapChecker "2001.08.30" "2001.09.01" );
    testGapChecker_disj_YMDtoYMD_AugToSep_3       = ( ! sut.gapChecker "2001.08.31" "2001.09.02" );

    testGapChecker_cont_YMDtoYMD_SepToOct_1       = (   sut.gapChecker "2001.09.29" "2001.09.30" );
    testGapChecker_cont_YMDtoYMD_SepToOct_2       = (   sut.gapChecker "2001.09.30" "2001.10.01" );
    testGapChecker_cont_YMDtoYMD_SepToOct_3       = (   sut.gapChecker "2001.09.30" "2001.10"    );
    testGapChecker_disj_YMDtoYMD_SepToOct_1       = ( ! sut.gapChecker "2001.09.28" "2001.09.30" );
    testGapChecker_disj_YMDtoYMD_SepToOct_2       = ( ! sut.gapChecker "2001.09.29" "2001.10.01" );
    testGapChecker_disj_YMDtoYMD_SepToOct_3       = ( ! sut.gapChecker "2001.09.30" "2001.10.02" );

    testGapChecker_cont_YMDtoYMD_OctToNov_1       = (   sut.gapChecker "2001.10.30" "2001.10.31" );
    testGapChecker_cont_YMDtoYMD_OctToNov_2       = (   sut.gapChecker "2001.10.31" "2001.11.01" );
    testGapChecker_cont_YMDtoYMD_OctToNov_3       = (   sut.gapChecker "2001.10.31" "2001.11"    );
    testGapChecker_disj_YMDtoYMD_OctToNov_1       = ( ! sut.gapChecker "2001.10.29" "2001.10.31" );
    testGapChecker_disj_YMDtoYMD_OctToNov_2       = ( ! sut.gapChecker "2001.10.30" "2001.11.01" );
    testGapChecker_disj_YMDtoYMD_OctToNov_3       = ( ! sut.gapChecker "2001.10.31" "2001.11.02" );

    testGapChecker_cont_YMDtoYMD_NovToDec_1       = (   sut.gapChecker "2001.11.29" "2001.11.30" );
    testGapChecker_cont_YMDtoYMD_NovToDec_2       = (   sut.gapChecker "2001.11.30" "2001.12.01" );
    testGapChecker_cont_YMDtoYMD_NovToDec_3       = (   sut.gapChecker "2001.11.30" "2001.12"    );
    testGapChecker_disj_YMDtoYMD_NovToDec_1       = ( ! sut.gapChecker "2001.11.28" "2001.11.30" );
    testGapChecker_disj_YMDtoYMD_NovToDec_2       = ( ! sut.gapChecker "2001.11.29" "2001.12.01" );
    testGapChecker_disj_YMDtoYMD_NovToDec_3       = ( ! sut.gapChecker "2001.11.30" "2001.12.02" );

    testGapChecker_cont_YMDtoYMD_DecToJan_1       = (   sut.gapChecker "2001.12.30" "2001.12.31" );
    testGapChecker_cont_YMDtoYMD_DecToJan_2       = (   sut.gapChecker "2001.12.31" "2002.01.01" );
    testGapChecker_cont_YMDtoYMD_DecToJan_3       = (   sut.gapChecker "2001.12.31" "2002.01"    );
    testGapChecker_disj_YMDtoYMD_DecToJan_1       = (   sut.gapChecker "2001.12.31" "2002"       );
    testGapChecker_disj_YMDtoYMD_DecToJan_2       = ( ! sut.gapChecker "2001.12.29" "2001.12.31" );
    testGapChecker_disj_YMDtoYMD_DecToJan_3       = ( ! sut.gapChecker "2001.12.30" "2002.01.01" );
    testGapChecker_disj_YMDtoYMD_DecToJan_4       = ( ! sut.gapChecker "2001.12.31" "2002.01.02" );

    testGapChecker_badDate_1 = test.evalShouldFail (sut.gapChecker "2000-01-01" ""           );
    testGapChecker_badDate_2 = test.evalShouldFail (sut.gapChecker ""           "2000-01-01" );

  }
