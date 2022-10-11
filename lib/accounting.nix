/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{
  nixpkgs,
  lib ? nixpkgs.lib,
  mkDerivation ? nixpkgs.stdenv
}:

let
  inherit (builtins) all baseNameOf compareVersions elemAt filter head length listToAttrs map match
  readDir replaceStrings;

  inherit (lib.asserts) assertMsg;

  inherit (lib.attrsets) attrValues mapAttrs mapAttrsToList nameValuePair zipAttrs;

  inherit (lib.lists) compareLists concatMap drop findFirst flatten genList groupBy init last
  optional sort zipListsWith;

  inherit (lib.strings) concatStrings concatStringsSep optionalString splitString toInt;

  inherit (lib.trivial) compare flip mod pipe;

  inherit (lib.versions) splitVersion major;

  dates = import ./dates.nix { inherit nixpkgs; };
  paths = import ./paths.nix { inherit nixpkgs; };

in {

  /*
  Configuration attributes for journal handling.

  fmts: List of attribute sets matching a date format to a specific date range format. Dates
  containing days are not supported and can not be used properly.

  isNoGapFn: Predicate reporting the edges of two given date ranges have no gaps. Values are held
  as version strings.

  journalPeriod: Attribute set representing the way to batch transactions into discrete periods.

  */
  config = {
    fmts = attrValues dates.dateFormats;

    isNoGapFn = dates.gapChecker;

    journalPeriod = dates.journalPeriods.byYear;
  };

  /*
  Converts the batch of statements into date ranges. Also validates that history is not missing,
  does not overlap, and that all filenames correspond to understood date ranges.

  type: statementPath = { date = date-range attrset pair } // srcPath
  */
  statementDates =
    # Date Range Formatters and Date range gap reporting.
    {fmts, isNoGapFn}:
    # Source paths. type: [ srcPath... ]
    srcs:
    let
      # type: date-range attrset pair
      srcToDate = (flip pipe) [
        (x: head (splitString "." (baseNameOf x)))
        (x: map (v: (r: optional (r != null) (v.fn r)) (match v.p x)) fmts)
        (findFirst (x: x != []) [])
        (x: assert assertMsg (x != []) "Statement with invalid date format"; head x)
      ];

      dates = pipe srcs [
        (map (x: { date = srcToDate x.file; } // x))
        (sort (a: b: (compareVersions a.date.start b.date.start) < 0))
      ];

      # List matching the start of each element with the end of the next
      cmpRangeList = pipe dates [
        (x: (zipAttrs x).date)
        (x: { lhs = [] ++ init x; rhs = (drop 1 x) ++ []; })
        (x: zipListsWith (a: b: { lhs = a.end; rhs = b.start; }) x.lhs x.rhs)
      ];
      isNotOverlap = pipe cmpRangeList [
        (map (mapAttrs (k: v: splitVersion v)))
        (all ({lhs, rhs}: (compareLists compare lhs rhs) < 0))
      ];
      isNoGaps = all ({lhs, rhs}: isNoGapFn lhs rhs) cmpRangeList;
    in
      if ! isNoGaps then throw "Missing statements"
      else if ! isNotOverlap then throw "Overlapping statements"
      else dates;

  /*
  Builds a set of periods with corresponding statement dependencies for each period. If a statement
  falls into the period, even partially, it is included. Statements can be included into multiple
  periods.

  type: [ { period = date-range attrset pair; statements = [ list of statements ]; } ... ]
  */
  batchStatementsByPeriod =
    # The period format to use.
    journalPeriodSpec:
    # Sorted list of statements.
    statements:
    let
      jSpec = journalPeriodSpec;
      fullRange = { start = (head statements).date.start; end = (last statements).date.end; };
      periodRanges = map jSpec.fromIdentifier (jSpec.toPeriods fullRange);
      batchFn = p: {
        period = p;
        statements = filter (s: dates.periodsOverlap p s.date) statements;
      };
    in
      map batchFn periodRanges;

  /* Builds a "generated" journal from a set of statements. */
  generatedJournal =
    # A preconfigured derivation set (prior to mkderivation) for the builder missing the name and
    # sources.
    baseDrv:
    {
      # Base name for derivations.
      baseName,
      # Name of the directory for the generated statement journals.
      rawStatementDirName,
      # Date range. type: date-range attrset pair
      statementWindow,
      # Source files paths. type: [ statementPath ]
      srcPaths
    }:
    let
    #  # TODO: Make sure it makes sense
    #  # Matches
    #  fMatch = match "([^.]+)[.].*" srcPath.file;
    #  relpMatch = match "import/(.*)/${rawStatementDirName}(.*)" srcPath.dir;

    #  # Updated Path
    #  f = "${head fMatch}.journal";
    #  relp = "export/generated/${elemAt relpMatch 0}/journal${elemAt relpMatch 1}";
    #  genName = replaceStrings ["/"] ["-"] relp;

    #  drvSet = baseDrv // {
    #    name = "${baseName}-${genName}";
    #    src = srcPath.path;

    #    # Must be a single file.
    #    outputHashMode = "flat";

    #    expectedPath = "${relp}/${f}";
    #  };

    #in mkDerivation drvSet;
    in [];

  /*
  Calculates the diff for a given statement journal against the corresponding journal
  generated from the backing data.
  */
  journalDiffs = x: {/* TODO */};

  /*
  Calculates the opening and closing balances for a given year. The opening_balance file contains
  the balances of all accounts, revenue, and expenses at the start of the period. The
  closing_balance file for the previous period contains the exact opposite (negation of the
  balances at the end of the period), bringing the balance down to zero. These files allow chaining
  of multiple periods together when viewing all transactions over a span of time (rather than only
  being able to view one period at a time). In short:

  Opening Balance: Included before a journal to "open" it, bringing it up from zero to the balances
  at the start of the period.

  Closing Balance: Included after a journal to "close" it, zeroing out all balances at the end of
  the period.

  Ex: import/.../journal/2020-12.journal -> {
  opening_balance = export/generated/.../opening_balance/2021-01.journal;
  closing_balance = export/generated/.../closing_balance/2020-12.journal;
  }
  */
  accountPeriodBalances = x: {/* TODO */};

  /*
  Calculates the individual interest transactions for an account from an interest schedule file.
  */
  accountInterestTxFromSchedule = x: {/* TODO */};

  /*
  Generated journals for "top level" periods such as years, decades, or the entire history all
  together. These journals include all sub-journals that compose their period.
  */
  topLevelJournals = x: {/* TODO */};

  # Working regex pattern
  # sourceByRegex ./. [ "import(/bank(/xxxx_NNNN(/ofx(/file.ofx)?)?)?)?" ]

  # TODO: Determine scheme for including new accounts to nix.
  # TODO: Determine scheme for preparing data for taxes.

  #srcs = lib.sources.sourceFilesBySuffices dir exts;
  #journals = mkDerivation {

  #};

  /*
  Test case builder to validate sources before construction. Checks for gaps between statements,
  overlap between statements, conformance with period rules (calendar year vs fiscal year, month vs
  week, etc), and that all statements fit within their periods.
  */
  statementDateTester = x: {/* TODO */};

# Basic Use
# for list of accounts: makeAccount {
#     statementDateSplitter -> statementDateTester -> generatedJournals -> journalDiffTester -> {
#       accountPeriodBalances
#       accountInterestTxFromSchedule
#     } -> topLevelJournals
# } ->
#

}
