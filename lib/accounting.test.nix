/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{ nixpkgs, lib ? nixpkgs.lib, test }:

let
  inherit (builtins) tryEval;

  inherit (lib.debug) runTests testAllTrue;

  paths = import ./paths.nix { inherit nixpkgs; };
  sut = import ./accounting.nix { inherit nixpkgs; };

  dummyRelPaths = [
    "import/bank/xxxx_XXXX/csv/200X.csv"
    "import/bank/xxxx_XXXX/csv/2010.csv"
    "import/bank/xxxx_XXXX/csv/2011.csv"
    "import/bank/xxxx_XXXX/csv/2012-2019.csv"
    "import/bank/xxxx_XXXX/csv/2020-01.csv"
    "import/bank/xxxx_XXXX/csv/2020-02.csv"
    "import/bank/xxxx_XXXX/csv/2020-03--12.csv"
  ];

  # Statement Dates
  dummySrcs = paths.flattenPathTree (test.fakePathTree ./. dummyRelPaths);
  statementDatesCfg = { fmts = sut.config.fmts; isNoGapFn = sut.config.isNoGapFn; };
  statements = sut.statementDates statementDatesCfg dummySrcs;

  # Journal Batching
  stmtBatches = sut.batchStatementsByPeriod sut.config.journalPeriod statements;
  batchDenoiseFn = x: {
    period = x.period;
    statements = map (v: v.date) x.statements;
  };

in
  runTests {

    testStatementDates = {
      expr = map (x: x.date) statements;
      expected = [
        { start = "2000.01.01";  end = "2009.12.31"; }
        { start = "2010.01.01";  end = "2010.12.31"; }
        { start = "2011.01.01";  end = "2011.12.31"; }
        { start = "2012.01.01";  end = "2019.12.31"; }
        { start = "2020.01.01"; end = "2020.01.31"; }
        { start = "2020.02.01"; end = "2020.02.29"; }
        { start = "2020.03.01"; end = "2020.12.31"; }
      ];
    };

    testBatchStatementsByPeriod = {
      expr = map batchDenoiseFn stmtBatches;
      expected = [
        {
          period = { start = "2000.01.01"; end = "2000.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2001.01.01"; end = "2001.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2002.01.01"; end = "2002.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2003.01.01"; end = "2003.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2004.01.01"; end = "2004.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2005.01.01"; end = "2005.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2006.01.01"; end = "2006.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2007.01.01"; end = "2007.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2008.01.01"; end = "2008.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2009.01.01"; end = "2009.12.31"; };
          statements = [ { start = "2000.01.01"; end = "2009.12.31"; } ];
        } {
          period = { start = "2010.01.01"; end = "2010.12.31"; };
          statements = [ { start = "2010.01.01"; end = "2010.12.31"; } ];
        } {
          period = { start = "2011.01.01"; end = "2011.12.31"; };
          statements = [ { start = "2011.01.01"; end = "2011.12.31"; } ];
        } {
          period = { start = "2012.01.01"; end = "2012.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2013.01.01"; end = "2013.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2014.01.01"; end = "2014.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2015.01.01"; end = "2015.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2016.01.01"; end = "2016.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2017.01.01"; end = "2017.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2018.01.01"; end = "2018.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2019.01.01"; end = "2019.12.31"; };
          statements = [ { start = "2012.01.01"; end = "2019.12.31"; } ];
        } {
          period = { start = "2020.01.01"; end = "2020.12.31"; };
          statements = [
            { start = "2020.01.01"; end = "2020.01.31"; }
            { start = "2020.02.01"; end = "2020.02.29"; }
            { start = "2020.03.01"; end = "2020.12.31"; }
          ];
        }
      ];
    };
  }
