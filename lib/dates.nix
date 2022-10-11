/*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/
{
  nixpkgs,
  lib ? nixpkgs.lib
}:

let
  common = import ./common.nix { inherit nixpkgs; };

  inherit (builtins) compareVersions elemAt getAttr length map match toString;

  inherit (lib.asserts) assertMsg;

  inherit (lib.lists) genList;

  inherit (lib.strings) escapeNixString toInt;

  inherit (lib.trivial) flip mod pipe;

  inherit (lib.versions) splitVersion major;

  inherit (common) toEscapedNixStr;

  /* Parses a version string representation of a date "Y.M.D" into a list of integers [ Y M D ]. */
  toDate = (flip pipe) [
    (splitVersion)
    (map (match "0*([123456789][[:digit:]]*)"))
    (map (x: if x == null then throw "Invalid Date Format: ${toEscapedNixStr x}" else elemAt x 0))
    (map toInt)
  ];

  /* Reports if a given year is a leap year or not. */
  isLeapYear = year: (mod year 4 == 0) && ((mod year 100 != 0) || (mod year 400 == 0));

  gregorianCalDaysPerMonth = {
     "1" = y: 31;
    "01" = y: 31;
     "2" = y: if isLeapYear y then 29 else 28;
    "02" = y: if isLeapYear y then 29 else 28;
     "3" = y: 31;
    "03" = y: 31;
     "4" = y: 30;
    "04" = y: 30;
     "5" = y: 31;
    "05" = y: 31;
     "6" = y: 30;
    "06" = y: 30;
     "7" = y: 31;
    "07" = y: 31;
     "8" = y: 31;
    "08" = y: 31;
     "9" = y: 30;
    "09" = y: 30;
    "10" = y: 31;
    "11" = y: 30;
    "12" = y: 31;
  };

  daysPerMonth = year: monthStr: (getAttr monthStr gregorianCalDaysPerMonth) year;

in {

  inherit toDate isLeapYear;

  /* Default set of date formats to support. */
  dateFormats = {
    # Single Year
    year = {
      p = "([[:digit:]]{4})";
      fn = x: {
        start = "${elemAt x 0}.1.1";
        end   = "${elemAt x 0}.12.31";
      };
    };

    # Year Range
    yearToYear = {
      p = "([[:digit:]]{4})-([[:digit:]]{4})";
      fn = x: {
        start = "${elemAt x 0}.1.1";
        end   = "${elemAt x 1}.12.31";
      };
    };

    # Decade Wildcard
    decade = {
      p = "([[:digit:]]{3})[Xx]";
      fn = x: {
        start = "${elemAt x 0}0.1.1";
        end   = "${elemAt x 0}9.12.31";
      };
    };

    # Single Month
    month = {
      p = "([[:digit:]]{4})-([[:digit:]]{1,2})";
      fn = x: let
        y = elemAt x 0;
        m = elemAt x 1;
      in {
        start = "${y}.${m}.1";
        end   = "${y}.${m}.${toString (daysPerMonth (toInt y) m)}";
      };
    };

    # Month Range within a Year
    yearMonthToMonth = {
      p = "([[:digit:]]{4})-([[:digit:]]{1,2})--([[:digit:]]{1,2})";
      fn = x: let
        y  = elemAt x 0;
        m1 = elemAt x 1;
        m2 = elemAt x 2;
      in {
        start = "${y}.${m1}.1";
        end   = "${y}.${m2}.${toString (daysPerMonth (toInt y) m2)}";
      };
    };

    # Day Range
    dayToDay = {
      p = (
          "([[:digit:]]{4})-([[:digit:]]{1,2})-([[:digit:]]{1,2})"
        + "--"
        + "([[:digit:]]{4})-([[:digit:]]{1,2})-([[:digit:]]{1,2})"
        );
      fn = x: {
        start = (elemAt x 0) + "." + (elemAt x 1) + "." + (elemAt x 2);
        end   = (elemAt x 3) + "." + (elemAt x 4) + "." + (elemAt x 5);
      };
    };
  };

  /* Gap checker supporting down to month level granularity w/ mostly accurate day granularity. */
  gapChecker = firstEnd: secondStart: let

    first = toDate firstEnd;
    second = toDate secondStart;

    year = (flip elemAt) 0;
    hasYear = x: (length x) > 0;

    month = (flip elemAt) 1;
    hasMonth = x: (length x) > 1;

    day = (flip elemAt) 2;
    hasDay = x: (length x) > 2;

    isFirstMonthOfYear = x: (month x) == 1;
    isLastMonthOfYear = x: (month x) == 12;

    isFirstDayOfMonth = x: (day x) == 1;
    isLastDayOfMonth = x: (day x) == daysPerMonth (year x) (toString (month x));

    isMonthValid = x: (hasMonth x) -> (((month x) >= 1) && ((month x) <= 12));
    isDayValid = x: (hasDay x) -> (
      ((day x) >= 1) && ((day x) <= daysPerMonth (year x) (toString (month x)))
    );

    monthErrStr = x: "Month value ${toEscapedNixStr (month x)} of "
      + "date ${toEscapedNixStr x} is invalid.";
    dayErrStr = x: "Day value ${toEscapedNixStr (day x)} of "
      + "date ${toEscapedNixStr x} is invalid.";
    leapYearCtxStr = x: if (! hasMonth x) || (! hasDay x) || (month x) != 2 then ""
      else if isLeapYear (year x) then " Context: Date is during a leap year."
      else " Context: Date is not during a leap year.";

    validateMonth = x: if isMonthValid x then true else throw (monthErrStr x);
    validateDay = x: if isDayValid x then true else throw (dayErrStr x + leapYearCtxStr x);

    # Validate Year -> Year
    bothHaveYear = (hasYear first) && (hasYear second);
    isSameYear = (year first) == (year second);
    isSequentialYears = (year first + 1) == (year second);

    firstEndYearErrStr = "End of first range ${toEscapedNixStr first} is missing a valid year";
    secondStartYearErrStr = "Start of second range ${toEscapedNixStr second} is missing "
      + "a valid year";
    yearValidationGeneralError = "Parse error in year for either end of first range: "
      + "${toEscapedNixStr first} or start of second range: ${toEscapedNixStr second}.";

    validateYears = if bothHaveYear then true
      else if ! hasYear first then throw firstEndYearErrStr
      else if ! hasYear second then throw secondStartYearErrStr
      else throw yearValidationGeneralError;

    # Validate Year -> Month
    isYearToMonth = isSequentialYears && (! hasMonth first) && hasMonth second;
    isYearToMonthNoGap = isFirstMonthOfYear second;

    # Validate Month -> Year
    isMonthToYear= isSequentialYears && hasMonth first && (! hasMonth second);
    isMonthToYearNoGap = isLastMonthOfYear first;

    # Validate Month -> Month within same year
    isSameMonth = month first == month second;
    isMonthToMonthSameYear = isSameYear && hasMonth first && hasMonth second && (! isSameMonth);
    isMonthToMonthSameYearNoGap = (month first + 1) == month second;

    # Validate Month -> Month at edge of years
    isMonthToMonthCrossYear = isSequentialYears && hasMonth first && hasMonth second;
    isMonthToMonthCrossYearNoGap = isLastMonthOfYear first && isFirstMonthOfYear second;

    # Validate Day -> Day
    isMonthToMonth = (isMonthToMonthSameYear || isMonthToMonthCrossYear);
    isDayToDay = hasDay first && hasDay second;

    isDayToDayCrossMonthNoGap = (
      isMonthToMonth && isLastDayOfMonth first && isFirstDayOfMonth second
    );
    isDayToDaySameMonthNoGap = (
      (! isMonthToMonth) && (! isLastDayOfMonth first) && (day first + 1) == day second
    );

    isDayToDayNoGap = isDayToDayCrossMonthNoGap || isDayToDaySameMonthNoGap;

    # Validate Day -> Month
    isDayToMonth = hasDay first && hasMonth second && (! hasDay second);
    isDayToMonthNoGap = isMonthToMonth && isLastDayOfMonth first;

    # Validate Month -> Day
    isMonthToDay = hasMonth first && (! hasDay first) && hasDay second;
    isMonthToDayNoGap = isMonthToMonth && isFirstDayOfMonth second;

    # Validate Day -> Year
    isDayToYear = isMonthToYear && hasDay first && (! hasDay second);
    isDayToYearNoGap = isLastDayOfMonth first && isMonthToYearNoGap;

    # Validate Year -> Day
    isYearToDay = isYearToMonth && (! hasDay first) && hasDay second;
    isYearToDayNoGap = isYearToMonthNoGap && isFirstDayOfMonth second;

  in ( validateYears
  && ( validateMonth first )
  && ( validateMonth second )
  && ( validateDay first )
  && ( validateDay second )
  && ( isSameYear || isSequentialYears )
  && ( isYearToMonth -> isYearToMonthNoGap )
  && ( isMonthToYear -> isMonthToYearNoGap )
  && ( isMonthToMonthSameYear -> isMonthToMonthSameYearNoGap )
  && ( isMonthToMonthCrossYear -> isMonthToMonthCrossYearNoGap )
  && ( isDayToDay -> isDayToDayNoGap )
  && ( isDayToMonth -> isDayToMonthNoGap )
  && ( isMonthToDay -> isMonthToDayNoGap )
  && ( isDayToYear -> isDayToYearNoGap )
  && ( isYearToDay -> isYearToDayNoGap )
  );

  journalPeriods = {
    byYear = {
      /* File identifier for a given period from the corresponding date range. */
      toIdentifier = dateRange: "${major dateRange.start}";

      /* Date range for a given period from the identifier. */
      fromIdentifier =
        ident:
        let
          startYear = toInt ident;
        in
          { start = "${toString startYear}.1.1"; end = "${toString startYear}.12.31"; };

      /* Sorted list of periods contained within the date range. */
      toPeriods =
        dateRange:
        let
          startYear = toInt (major dateRange.start);
          endYear = toInt (major dateRange.end);
          numPeriods = endYear - startYear + 1;
          periodList = genList (i: toString (startYear + i)) numPeriods;

          badRangeError = "Start date ${escapeNixString dateRange.start} must come "
          + "before end date ${escapeNixString dateRange.end}.";

        in
          if endYear < startYear
          then throw badRangeError
          else periodList;
    };
  };

  periodsOverlap = lhs: rhs:
    let
      lhsStartBeforeRhsEnd   = (compareVersions lhs.start rhs.end)   <= 0;
      lhsEndAfterRhsStart    = (compareVersions lhs.end   rhs.start) >= 0;

    in
      lhsStartBeforeRhsEnd && lhsEndAfterRhsStart;


}
