import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import NatX "./NatX";
import Debug "mo:base/Debug";
  
  module {
    public type FloatPrecision = {#f16; #f32; #f64};

    public type FloatX = {
        precision: FloatPrecision;
        isNegative: Bool;
        exponent: Nat64;
        mantissa: Nat64;
    };

    public type PrecisionBitInfo = {
        exponentBitLength: Nat64;
        mantissaBitLength: Nat64;
    };

    public func getPrecisionBitInfo(precision: FloatPrecision) : PrecisionBitInfo {
        switch (precision) {
            case (#f16) {
                {
                    exponentBitLength = 5;
                    mantissaBitLength = 10;
                };
            };
            case (#f32) {
                {
                    exponentBitLength = 8;
                    mantissaBitLength = 23;
                };
            };
            case (#f64) {
                {
                    exponentBitLength = 11;
                    mantissaBitLength = 52;
                };
            };
        };
    };

    public func floatToFloatX(float: Float, precision: FloatPrecision) : FloatX {
      let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(precision);
      
      let isNegative = float < 0;

      // exponent is the power of 2 that is closest to the value without going over
      // exponent = trunc(log2(|value|))
      // where log2(x) = log(x)/log(2)
      let e = Float.log(Float.abs(float))/Float.log(2);
      let exponent: Nat64 = Int64.toNat64(Float.toInt64(e)); // Truncate
      // Max bit value is how many values can fit in the bit length
      let maxBitValue: Nat64 = Int64.toNat64(Float.toInt64(Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.exponentBitLength)))));
      // Exponent bits is a range of -(2^expBitLength/2) -1 -> (2^expBitLength/2)
      let exponentBits: Nat64 = exponent + ((maxBitValue / 2) - 1);

      // mantissaMaxOffset = 2 ^ mantissaBitLength
      let mantissaMaxOffset: Nat64 = Int64.toNat64(Float.toInt64(Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.mantissaBitLength)))));
      // The mantissa is the % of the exponent as the remainder between exponent and real value
      let mantissa: Float = (float / Float.pow(2, Float.fromInt64(Int64.fromNat64(exponent)))) - 1;
      // Bits represent how many offsets there are between the exponent and the value
      let mantissaBits: Nat64 = Int64.toNat64(Float.toInt64(Float.nearest(mantissa * Float.fromInt64(Int64.fromNat64(mantissaMaxOffset)))));
      {
        precision = precision;
        isNegative = isNegative;
        exponent = exponent;
        mantissa = mantissaBits
      };
    };

    public func floatXToFloat(fX: FloatX) : Float {
      let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(fX.precision);
      // Convert bits into numbers
      // e = 2 ^ (exponent - (2 ^ exponentBitLength / 2 - 1))
      let e: Int64 = Int64.pow(2, Int64.fromNat64(fX.exponent) - ((Int64.fromNat64(Nat64.pow(2, bitInfo.exponentBitLength) / 2)) - 1));
      // moi = 2 ^ (mantissaBitLength * -1)
      let maxOffsetInverse: Float = Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.mantissaBitLength)) * -1);
      // m = 1 + mantissa * moi
      let m: Float = 1.0 + (Float.fromInt64(Int64.fromNat64(fX.mantissa)) * maxOffsetInverse);
      // v = e * m
      var floatValue: Float = Float.fromInt64(e) * m;

      if (fX.isNegative) {
          floatValue := Float.mul(floatValue, -1.0);
      };
      
      floatValue;
    };



  public func encodeFloatX(buffer: Buffer.Buffer<Nat8>, value: FloatX, encoding: {#lsb; #msb}) {
      encodeFloatInternal(buffer, value, encoding);
  };


  public func decodeFloat(bytes: [Nat8], encoding: {#lsb; #msb}) : ?Float {
    do ? {
        let fX: FloatX = decodeFloatX(bytes, #f64, encoding)!;
        floatXToFloat(fX);
    };
  };

  public func decodeFloatX(bytes: [Nat8], precision: {#f16; #f32; #f64}, encoding: {#lsb; #msb}) : ?FloatX {
    do ? {
      let bytesIter = Iter.fromArray(bytes);
      let bits: Nat64 = switch(precision) {
        case (#f16) NatX.from16To64(NatX.decodeNat16(bytesIter, encoding)!);
        case (#f32) NatX.from32To64(NatX.decodeNat32(bytesIter, encoding)!);
        case (#f64) NatX.decodeNat64(bytesIter, encoding)!;
      };
      let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(precision);
      let (exponentBitLength: Nat64, mantissaBitLength: Nat64) = (bitInfo.exponentBitLength, bitInfo.mantissaBitLength);
      // Bitshift to get mantissa, exponent and sign bits
      let mantissa: Nat64 = bits & (Nat64.pow(2, mantissaBitLength + 1) - 1);
      Debug.print(debug_show(bits));
      let exponentBits: Nat64 = (bits >> mantissaBitLength) & (Nat64.pow(2, exponentBitLength) - 1);
      let exponent: Nat64 = exponentBits - ((2 ** (exponentBitLength - 1)) - 1);
      let signBits: Nat64 = (bits >> (mantissaBitLength + exponentBitLength)) & 0x01;
      
      // Make negative if sign bit is 1
      let isNegative: Bool = signBits == 1;
      {
          precision = precision;
          isNegative = isNegative;
          exponent = exponent;
          mantissa = mantissa;
      }
    }
  };




  private func encodeFloatInternal(buffer: Buffer.Buffer<Nat8>, value: FloatX, encoding: {#lsb; #msb}) {
      var bits: Nat64 = 0;
      if(value.isNegative) {
          bits |= 0x01;
      };
      let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(value.precision);
      bits <<= bitInfo.exponentBitLength;
      let exponentBits: Nat64 = value.exponent + (2 ** (bitInfo.exponentBitLength - 1)) - 1;
      bits |= exponentBits;
      bits <<= bitInfo.mantissaBitLength;
      let mantissaBits = value.mantissa;
      bits |= mantissaBits;

      switch (value.precision) {
          case (#f16) {
              let nat16 = NatX.from64To16(bits);
              NatX.encodeNat16(buffer, nat16, encoding);
          };
          case (#f32) {
              let nat32 = NatX.from64To32(bits);
              NatX.encodeNat32(buffer, nat32, encoding);
          };
          case (#f64) {
              NatX.encodeNat64(buffer, bits, encoding);
          };
      }
  };

  }