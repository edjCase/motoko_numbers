import Buffer "mo:buffer@0";
import Float "mo:core@1/Float";
import Int "mo:core@1/Int";
import Int64 "mo:core@1/Int64";
import Iter "mo:core@1/Iter";
import List "mo:core@1/List";
import Nat "mo:core@1/Nat";
import Nat64 "mo:core@1/Nat64";
import NatX "./NatX";
import Char "mo:core@1/Char";
import Text "mo:core@1/Text";
import Nat32 "mo:core@1/Nat32";

module {

  public type FloatPrecision = { #f16; #f32; #f64 };

  public type FloatX = {
    precision : FloatPrecision;
    isNegative : Bool;
    exponent : ?Int;
    mantissa : Nat;
  };

  public type ToTextOptions = {
    exponent : { #none; #scientific; #engineering; #auto };
    precision : ?Nat; // Null = shortest accurate
  };

  /// Compares two floating-point numbers for near equality within specified tolerances.
  ///
  /// ```motoko
  /// let a : Float = 0.1;
  /// let b : Float = 0.10000000000000001;
  /// let result = nearlyEqual(a, b, 1e-15, 1e-15);
  /// // result is true
  /// ```
  public func nearlyEqual(a : Float, b : Float, relativeTolerance : Float, absoluteTolerance : Float) : Bool {
    let maxAbsoluteValue : Float = Float.max(Float.abs(a), Float.abs(b));
    Float.abs(a - b) <= Float.max(relativeTolerance * maxAbsoluteValue, absoluteTolerance);
  };

  /// Converts a `Float` to a `FloatX` with the specified precision.
  ///
  /// ```motoko
  /// let float : Float = 3.14159;
  /// let floatX : FloatX = fromFloat(float, #f32);
  /// ```
  public func fromFloat(float : Float, precision : FloatPrecision) : FloatX {
    let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(precision);
    let isNegative = Float.copySign(1.0, float) < 0;

    // Handle special values first
    if (Float.isNaN(float)) {
      return {
        precision = precision;
        isNegative = isNegative;
        exponent = ?getExponentWithAllOnes(bitInfo); // all 1s
        // TODO unable to get mantissa from NaN Float, so put in 1 as default
        mantissa = 1; // non-zero mantissa indicates NaN
      };
    };

    // Check for infinity
    if (float == (1.0 / 0.0)) {
      // +inf
      return {
        precision = precision;
        isNegative = false;
        exponent = ?getExponentWithAllOnes(bitInfo); // all 1s
        mantissa = 0; // zero mantissa indicates infinity
      };
    };

    if (float == (-1.0 / 0.0)) {
      // -inf
      return {
        precision = precision;
        isNegative = true;
        exponent = ?getExponentWithAllOnes(bitInfo); // all 1s
        mantissa = 0; // zero mantissa indicates infinity
      };
    };

    if (float == 0.0) {
      return {
        precision = precision;
        isNegative = isNegative;
        exponent = null;
        mantissa = 0;
      };
    };

    // maxMantissa = 2 ^ mantissaBitLength
    // e = 2^exponent * (x + mantissa/maxMantissa)
    // float = sign * e
    // where x is 1 if exponent > 0 else 0
    // where sign is 1 if positive else -1

    // Normal number are numbers that are represented by 2^minExponent -> 2^maxExponent - 1
    // Sub normal numbers are numbers represented by 2^minExponent * 1/maxMantissa -> 2^minExponent * (maxMantissa - 1)/maxMantissa
    let isNormalNumber : Bool = Float.abs(float) >= bitInfo.smallestNormalNumber;
    let (exponent : ?Int, x : Int) = if (isNormalNumber) {
      // If is normal number then x is 1
      // e is 2^exponent + (number less than 2)
      // so if you get the log2(e), truncate the remainder, it will represent the exponent
      let e : Int = Float.toInt(Float.floor(Float.log(Float.abs(float)) / Float.log(2)));
      (?e, 1);
    } else {
      // If smaller than 2^minExponent then x is 0
      // e is 2^exponent + (number less than 1)
      // exponent is min value
      (null, 0);
    };

    // m = (|float|/2^exponent) - x
    // mantissa = m * maxMantissa
    // The m is the % of the exponent as the remainder between exponent and real value
    let exp = switch (exponent) {
      case (null) bitInfo.minExponent; // If null, its subnormal. use min exponent here
      case (?e) e;
    };
    let m : Float = (Float.abs(float) / calculateExponent(2, Float.fromInt(exp)) - Float.fromInt(x));
    // Mantissa represent how many offsets there are between the exponent and the value
    let mantissa : Nat = Int.abs(Float.toInt(Float.nearest(m * Float.fromInt(bitInfo.maxMantissaDenomiator))));

    {
      precision = precision;
      isNegative = isNegative;
      exponent = exponent;
      mantissa = mantissa;
    };
  };
  /// Converts a `FloatX` to a `Float`.
  ///
  /// ```motoko
  /// let floatX : FloatX = {
  ///   precision = #f32;
  ///   isNegative = false;
  ///   exponent = ?1;
  ///   mantissa = 5033165;
  /// };
  /// let float : Float = toFloat(floatX);
  /// ```
  public func toFloat(fX : FloatX) : Float {
    let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(fX.precision);

    // Handle special values
    let all1sValue : Int = getExponentWithAllOnes(bitInfo);
    if (fX.exponent == ?all1sValue) {
      if (fX.mantissa == 0) {
        // Infinity
        return if (fX.isNegative) (-1.0 / 0.0) else (1.0 / 0.0);
      } else {
        // NaN
        return (0.0 / 0.0);
      };
    };

    // e = 2^exponent * (x + mantissa/maxMantissa)
    // float = sign * e
    // where x is 1 if exponent > 0 else 0
    // where sign is 1 if positive else -1

    let sign = if (fX.isNegative) -1.0 else 1.0;
    let (exponent : Int, x : Nat) = switch (fX.exponent) {
      case (null) (-14, 0); // If null, its subnormal. use min exponent here
      case (?exponent) (exponent, 1);
    };
    let expValue : Float = calculateExponent(2, Float.fromInt(exponent));
    sign * expValue * (Float.fromInt(x) + Float.fromInt(fX.mantissa) / Float.fromInt(bitInfo.maxMantissaDenomiator));
  };

  /// Encodes a `FloatX` to a byte array.
  ///
  /// ```motoko
  /// let floatX : FloatX = fromFloat(3.14159, #f32);
  /// let bytes = toBytes(floatX, #lsb);
  /// ```
  public func toBytes(value : FloatX, encoding : { #lsb; #msb }) : [Nat8] {
    let list = List.empty<Nat8>();
    let buffer = Buffer.fromList(list);
    toBytesBuffer(buffer, value, encoding);
    List.toArray(list);
  };

  /// Encodes a `FloatX` to a byte buffer.
  ///
  /// ```motoko
  /// let floatX : FloatX = fromFloat(3.14159, #f32);
  /// let buffer = Buffer.Buffer<Nat8>(4);
  /// toBytesBuffer(buffer, floatX, #lsb);
  /// ```
  public func toBytesBuffer(buffer : Buffer.Buffer<Nat8>, value : FloatX, encoding : { #lsb; #msb }) {
    var bits : Nat64 = 0;
    if (value.isNegative) {
      bits |= 0x01;
    };
    let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(value.precision);
    bits <<= Nat64.fromNat(bitInfo.exponentBitLength);

    let exponentBits : Nat64 = switch (value.exponent) {
      case (null) 0;
      case (?exponent) Int64.toNat64(Int64.fromInt(exponent + bitInfo.maxExponent));
    };
    bits |= exponentBits;
    bits <<= Nat64.fromNat(bitInfo.mantissaBitLength);
    let mantissaBits : Nat64 = Nat64.fromNat(value.mantissa);
    bits |= mantissaBits;

    switch (value.precision) {
      case (#f16) {
        let nat16 = NatX.from64To16(bits);
        NatX.toNat16BytesBuffer(buffer, nat16, encoding);
      };
      case (#f32) {
        let nat32 = NatX.from64To32(bits);
        NatX.toNat32BytesBuffer(buffer, nat32, encoding);
      };
      case (#f64) {
        NatX.toNat64BytesBuffer(buffer, bits, encoding);
      };
    };
  };

  /// Decodes a `FloatX` from an iteration of bytes.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [64, 73, 15, 219]; // Encoded bytes for 3.14159 (f32)
  /// let result = fromBytes(bytes.vals(), #f32, #lsb);
  /// switch (result) {
  ///   case (null) { /* Handle decoding error */ };
  ///   case (?floatX) { /* Use decoded FloatX */ };
  /// };
  /// ```
  public func fromBytes(bytes : Iter.Iter<Nat8>, precision : { #f16; #f32; #f64 }, encoding : { #lsb; #msb }) : ?FloatX {
    do ? {
      let bits : Nat64 = switch (precision) {
        case (#f16) NatX.from16To64(NatX.fromNat16Bytes(bytes, encoding)!);
        case (#f32) NatX.from32To64(NatX.fromNat32Bytes(bytes, encoding)!);
        case (#f64) NatX.fromNat64Bytes(bytes, encoding)!;
      };
      let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(precision);
      if (bits == 0) {
        return ?{
          precision = precision;
          isNegative = false;
          exponent = null;
          mantissa = 0;
        };
      };
      let (exponentBitLength : Nat64, mantissaBitLength : Nat64) = (Nat64.fromNat(bitInfo.exponentBitLength), Nat64.fromNat(bitInfo.mantissaBitLength));
      // Bitshift to get mantissa, exponent and sign bits
      let mantissa : Nat = Nat64.toNat(bits & (2 ** mantissaBitLength - 1));
      // Extract out exponent bits with bitshift and mask
      let exponentBits : Nat64 = (bits >> mantissaBitLength) & (2 ** exponentBitLength - 1);
      let exponent : ?Int = if (exponentBits == 0) {
        // If not bits are set, then it is sub normal
        null;
      } else {
        // Get real exponent from the exponent bits
        ?(Nat64.toNat(exponentBits) - bitInfo.maxExponent);
      };
      let signBits : Nat64 = (bits >> (mantissaBitLength + exponentBitLength)) & 0x01;

      // Make negative if sign bit is 1
      let isNegative : Bool = signBits == 1;
      {
        precision = precision;
        isNegative = isNegative;
        exponent = exponent;
        mantissa = mantissa;
      };
    };
  };
  /// Checks if a `FloatX` represents NaN (Not a Number).
  ///
  /// ```motoko
  /// let floatX : FloatX = fromFloat(0.0/0.0, #f32);
  /// let result = isNaN(floatX);
  /// // result is true
  /// ```
  public func isNaN(fX : FloatX) : Bool {
    switch (fX.exponent) {
      case (?exp) fX.mantissa != 0 and exp == getExponentWithAllOnes(getPrecisionBitInfo(fX.precision));
      case (null) false;
    };
  };

  /// Checks if a `FloatX` represents positive infinity.
  ///
  /// ```motoko
  /// let posInf : FloatX = fromFloat(1.0/0.0, #f32);
  /// let negInf : FloatX = fromFloat(-1.0/0.0, #f32);
  /// let result1 = isPosInf(posInf); // true
  /// let result2 = isPosInf(negInf); // false
  /// ```
  public func isPosInf(fX : FloatX) : Bool {
    switch (fX.exponent) {
      case (?exp) fX.mantissa == 0 and not fX.isNegative and exp == getExponentWithAllOnes(getPrecisionBitInfo(fX.precision));
      case (null) false;
    };
  };

  /// Checks if a `FloatX` represents negative infinity.
  ///
  /// ```motoko
  /// let posInf : FloatX = fromFloat(1.0/0.0, #f32);
  /// let negInf : FloatX = fromFloat(-1.0/0.0, #f32);
  /// let result1 = isNegInf(posInf); // false
  /// let result2 = isNegInf(negInf); // true
  /// ```
  public func isNegInf(fX : FloatX) : Bool {
    switch (fX.exponent) {
      case (?exp) fX.mantissa == 0 and fX.isNegative and exp == getExponentWithAllOnes(getPrecisionBitInfo(fX.precision));
      case (null) false;
    };
  };

  /// Converts a `FloatX` to its textual representation.
  /// Equivalent to `toTextAdvanced` with auto exponent and null precision.
  ///
  /// ```motoko
  /// let floatX : FloatX = fromFloat(3.14159, #f32);
  /// let text : Text = toText(floatX); // Text is "3.14159"
  /// ```
  public func toText(fX : FloatX) : Text {
    toTextAdvanced(fX, { exponent = #auto; precision = null });
  };

  /// Converts a `FloatX` to its textual representation.
  ///
  /// ```motoko
  /// let floatX : FloatX = fromFloat(23.0, #f32);
  /// let options = { exponent = #scientific; precision = ?3; };
  /// let formattedText = toTextAdvanced(floatX, options); // Text is "2.300e+1"
  /// ```
  public func toTextAdvanced(fX : FloatX, options : ToTextOptions) : Text {

    if (isNaN(fX)) return "NaN";
    if (isPosInf(fX)) return "inf";
    if (isNegInf(fX)) return "-inf";

    let sign = if (fX.isNegative) "-" else "";

    if (fX.mantissa == 0 and fX.exponent == null) {
      return sign # "0.0";
    };

    let float = toFloat(fX);
    let absFloat = if (fX.isNegative) -float else float;
    if (absFloat == 0.0) return sign # "0.0";

    let (useScientific, isEngineering) = switch (options.exponent) {
      case (#scientific) (true, false);
      case (#auto) (absFloat < 0.0001 or absFloat >= 1000000.0, false);
      case (#engineering) (true, true);
      case (#none) (false, false);
    };

    if (useScientific) {
      var exp = Float.toInt(Float.floor(Float.log(absFloat) / Float.log(10.0)));

      var mantissa = absFloat / power(10.0, exp);

      // Fix floating point precision issues
      while (mantissa >= 10.0) {
        exp += 1;
        mantissa := absFloat / power(10.0, exp);
      };

      // apply engineering notation to the corrected exponent (multiple of 3)
      if (isEngineering) {
        let floorDiv = Float.floor(Float.fromInt(exp) / 3.0);
        exp := Float.toInt(floorDiv) * 3;
        mantissa := absFloat / power(10.0, exp);
      };

      let mantissaStr = floatToFixedPrecision(mantissa, options.precision);
      sign # mantissaStr # "e" # (if (exp >= 0) "+" else "") # Int.toText(exp);
    } else {
      sign # floatToFixedPrecision(absFloat, options.precision);
    };
  };

  /// Parses a text string to create a `FloatX` with the specified precision.
  /// Supports standard decimal notation, scientific notation (e.g., "1.5e-10"),
  /// and special values like "NaN", "inf", and "-inf".
  ///
  /// ```motoko
  /// let floatX1 = fromText("3.14159", #f32);
  /// let floatX2 = fromText("1.5e-10", #f64);
  /// let floatX3 = fromText("NaN", #f32);
  /// ```
  public func fromText(text : Text, precision : FloatPrecision) : ?FloatX {
    let trimmed = Text.trim(
      text,
      #predicate(Char.isWhitespace),
    );

    if (trimmed == "" or trimmed == "NaN" or trimmed == "nan") {
      return ?fromFloat(0.0 / 0.0, precision);
    };
    if (trimmed == "inf" or trimmed == "Infinity" or trimmed == "+inf") {
      return ?fromFloat(1.0 / 0.0, precision);
    };
    if (trimmed == "-inf" or trimmed == "-Infinity") {
      return ?fromFloat(-1.0 / 0.0, precision);
    };

    parseFloat(trimmed, precision);
  };

  private func calculateExponent(value : Float, exponent : Float) : Float {
    if (exponent < 0) {
      // Negative exponents arent allowed??
      // Have to do inverse of the exponent value
      1 / value ** (-1 * exponent);
    } else {
      value ** exponent;
    };
  };

  private type PrecisionBitInfo = {
    exponentBitLength : Nat;
    mantissaBitLength : Nat;
    maxMantissaDenomiator : Nat;
    minExponent : Int;
    maxExponent : Int;
    smallestNormalNumber : Float;
  };

  private func getPrecisionBitInfo(precision : FloatPrecision) : PrecisionBitInfo {
    let (exponentBitLength : Nat, mantissaBitLength : Nat) = switch (precision) {
      case (#f16) (5, 10);
      case (#f32) (8, 23);
      case (#f64) (11, 52);
    };
    let maxExponent : Int = 2 ** (exponentBitLength - 1) - 1;
    let minExponent : Int = -1 * (maxExponent - 1);

    let smallestNormalNumber : Float = calculateExponent(2, Float.fromInt(minExponent));
    {
      exponentBitLength = exponentBitLength;
      mantissaBitLength = mantissaBitLength;
      minExponent = minExponent;
      maxExponent = maxExponent;
      maxMantissaDenomiator = 2 ** mantissaBitLength;
      smallestNormalNumber = smallestNormalNumber;
    };
  };

  private func getExponentWithAllOnes(bitInfo : PrecisionBitInfo) : Int {
    2 ** bitInfo.exponentBitLength - 1 - bitInfo.maxExponent; // all 1s
  };

  private func parseFloat(text : Text, precision : FloatPrecision) : ?FloatX {
    let chars = Text.toArray(text);
    if (chars.size() == 0) return null;

    var pos = 0;
    var isNegative = false;

    // Parse sign
    if (chars[pos] == '-') {
      isNegative := true;
      pos += 1;
    } else if (chars[pos] == '+') {
      pos += 1;
    };

    if (pos >= chars.size()) return null;

    // Parse decimal float
    parseDecimalFloat(chars, pos, isNegative, precision);
  };

  private func parseDecimalFloat(
    chars : [Char],
    start : Nat,
    isNegative : Bool,
    precision : FloatPrecision,
  ) : ?FloatX {
    var pos = start;
    var intPart : Nat = 0;
    var fracPart : Nat = 0;
    var fracDigits : Nat = 0;
    var hasDecimal = false;
    var exponentOrNull : ?Int = null;

    // Parse integer part
    while (pos < chars.size() and Char.isDigit(chars[pos])) {
      intPart := intPart * 10 + Nat32.toNat(Char.toNat32(chars[pos]) - Char.toNat32('0'));
      pos += 1;
    };

    // Parse decimal point and fractional part
    if (pos < chars.size() and chars[pos] == '.') {
      hasDecimal := true;
      pos += 1;
      while (pos < chars.size() and Char.isDigit(chars[pos])) {
        fracPart := fracPart * 10 + Nat32.toNat(Char.toNat32(chars[pos]) - Char.toNat32('0'));
        fracDigits += 1;
        pos += 1;
      };
    };

    // Parse exponent
    if (pos < chars.size() and (chars[pos] == 'e' or chars[pos] == 'E')) {
      pos += 1;
      if (pos >= chars.size()) return null;

      var expNeg = false;
      if (chars[pos] == '-') {
        expNeg := true;
        pos += 1;
      } else if (chars[pos] == '+') {
        pos += 1;
      };

      var exp : Nat = 0;
      while (pos < chars.size() and Char.isDigit(chars[pos])) {
        exp := exp * 10 + Nat32.toNat(Char.toNat32(chars[pos]) - Char.toNat32('0'));
        pos += 1;
      };
      if (exp > 0) {
        exponentOrNull := ?(if (expNeg) -exp else exp);
      };
    };

    // Reconstruct the float value
    var value : Float = Float.fromInt(intPart);
    if (fracDigits > 0) {
      let divisor = power(10.0, fracDigits);
      value += Float.fromInt(fracPart) / divisor;
    };
    switch (exponentOrNull) {
      case (null) ();
      case (?exponent) value *= power(10.0, exponent);
    };
    if (isNegative) {
      value := -value;
    };

    ?fromFloat(value, precision);
  };

  private func floatToFixedPrecision(value : Float, precisionOrNull : ?Nat) : Text {
    let intPart = Float.toInt(Float.floor(value));
    let fracPart = value - Float.fromInt(intPart);

    if (fracPart == 0.0 and precisionOrNull == null) {
      return Int.toText(intPart) # ".0";
    };

    var result = Int.toText(intPart) # ".";

    var frac = fracPart;

    let endCaseCheck = switch (precisionOrNull) {
      case (null) func() : Bool {
        frac == 0.0;
      };
      case (?precsion) {
        var p : Int = precsion;
        func() : Bool {
          let result = p <= 0;
          p -= 1;
          result;
        };
      };
    };

    label l loop {
      if (endCaseCheck()) break l;
      frac *= 10.0;
      let digit = Float.toInt(Float.floor(frac + 0.5e-9)); // Add small epsilon before floor
      result #= Int.toText(digit);
      frac -= Float.fromInt(digit);
    };

    result;
  };

  private func power(base : Float, exp : Int) : Float {
    if (exp == 0) return 1.0;
    if (exp > 0) {
      var result : Float = 1.0;
      var e = exp;
      while (e > 0) {
        result *= base;
        e -= 1;
      };
      result;
    } else {
      var result : Float = 1.0;
      var e = -exp;
      while (e > 0) {
        result /= base;
        e -= 1;
      };
      result;
    };
  };

};
