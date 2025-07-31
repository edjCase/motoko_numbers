import Buffer "mo:buffer";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Int64 "mo:core/Int64";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Nat "mo:core/Nat";
import Nat64 "mo:core/Nat64";
import NatX "./NatX";

module {

  public type FloatPrecision = { #f16; #f32; #f64 };

  public type FloatX = {
    precision : FloatPrecision;
    isNegative : Bool;
    exponent : ?Int;
    mantissa : Nat;
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

};
