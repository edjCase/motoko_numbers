import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import NatX "./NatX";
  
  module {
    public type FloatPrecision = {#f16; #f32; #f64};

    public type FloatX = {
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

    public func floatToFloatX(f: Float, precision: FloatPrecision) : FloatX {
        let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(precision);
        floatToFloatXInternal(f, bitInfo);
    };



  public func encodeFloatX(buffer: Buffer.Buffer<Nat8>, value: FloatX, precision: {#f16; #f32; #f64}, encoding: {#lsb; #msb}) : Nat {
      let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(precision);
      encodeFloatInternal(buffer, value.isNegative, value.exponentBits, value.mantissaBits, bitInfo);
  };


  public func decodeFloat(bytes: [Nat8], encoding: {#lsb; #msb}) : ?Float {
    do ? {
        let floatX: FloatX = decodeFloatX(bytes, #f64, encoding)!;
        let bitInfo = getPrecisionBitInfo(#f64);
        floatXToFloatInternal(fX.isNegative, fX.exponentBits, fX.mantissaBits, bitInfo);
    };
  };

  public func decodeFloatX(bytes: [Nat8], precision: {#f16; #f32; #f64}, encoding: {#lsb; #msb}) : ?FloatX {
      var bits: Nat64 = switch(NatX.decodeNat64(Iter.fromArray(bytes), #msb)) {
        case (null) return null;
        case (?b) b;
      };
      let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(precision);
      let (exponentBitLength: Nat64, mantissaBitLength: Nat64) = (bitInfo.exponentBitLength, bitInfo.mantissaBitLength);
      // Bitshift to get mantissa, exponent and sign bits
      let mantissaBits: Nat64 = bits & (Nat64.pow(2, mantissaBitLength) - 1);
      let exponentBits: Nat64 = (bits >> mantissaBitLength) & (Nat64.pow(2, exponentBitLength) - 1);
      let signBits: Nat64 = (bits >> (mantissaBitLength + exponentBitLength)) & 0x01;
      
      // Make negative if sign bit is 1
      let isNegative: Bool = signBits == 1;
      ?{
          isNegative = isNegative;
          exponentBits = exponentBits;
          mantissaBits = mantissaBits;
      }
  };




  private func encodeFloatInternal(buffer: Buffer.Buffer<Nat8>, isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64, precision: {#f16; #f32; #f64}, encoding: {#lsb; #msb}) {
      var bits: Nat64 = 0;
      if(isNegative) {
          bits |= 0x01;
      };
      let bitInfo: PrecisionBitInfo = getPrecisionBitInfo(precision);
      bits <<= bitInfo.exponentBitLength;
      bits |= exponentBits;
      bits <<= bitInfo.mantissaBitLength;
      bits |= mantissaBits;

      switch (precision) {
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



    private func floatXToFloatInternal(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64, bitInfo: PrecisionBitInfo) : Float {
        // Convert bits into numbers
        // e = 2 ^ (exponent - (2 ^ exponentBitLength / 2 - 1))
        let e: Int64 = Int64.pow(2, Int64.fromNat64(exponentBits) - ((Int64.fromNat64(Nat64.pow(2, bitInfo.exponentBitLength) / 2)) - 1));
        // moi = 2 ^ (mantissaBitLength * -1)
        let maxOffsetInverse: Float = Float.pow(2, Float.fromInt64(Int64.fromNat64(bitInfo.mantissaBitLength)) * -1);
        // m = 1 + mantissa * moi
        let m: Float = 1.0 + (Float.fromInt64(Int64.fromNat64(mantissaBits)) * maxOffsetInverse);
        // v = e * m
        var floatValue: Float = Float.fromInt64(e) * m;

        if (isNegative) {
            floatValue := Float.mul(floatValue, -1.0);
        };
        
        floatValue;
    };

    private func floatToFloatXInternal(float: Float, bitInfo: PrecisionBitInfo) : FloatX {
        // TODO convert 
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
            isNegative = isNegative;
            exponentBits = exponentBits;
            mantissaBits = mantissaBits
        };
    };
  }