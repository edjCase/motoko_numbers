import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Array "mo:base/Array";
import List "mo:base/List";
import Text "mo:base/Text";

module {
  type Buffer<T> = Buffer.Buffer<T>;

  public func encodeNat(buffer: Buffer<Nat8>, value: Nat, encoding: {#leb128}) : Nat {
    let initialLength = buffer.size();
    switch(encoding) {
      case (#leb128) {
        // Unsigned LEB128 - https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128
        //       10011000011101100101  In raw binary
        //      010011000011101100101  Padded to a multiple of 7 bits
        //  0100110  0001110  1100101  Split into 7-bit groups
        // 00100110 10001110 11100101  Add high 1 bits on all but last (most significant) group to form bytes
        let bits: [Bool] = natToBits(value);
        
        let byteCount: Nat64 = Float.ceil(Float.fromInt(bits.size()) / 7.0); // 7, not 8, the 8th bit is to indicate end of number
        let lebBytes = Buffer<Nat8>(byteCount);
        let bitList: List.List<Bool> = List.fromArray(bits);
        label f for (byteIndex in Iter.range(0, byteCount))
        {
          var byte: Nat8 = 0;
          for (bitOffset in Iter.range(0, 7)) {
            let bit = bitList.pop();
            switch (bit) {
              case (?true) {
                // Set bit
                byte := Nat8.bitset(byte, 7 - bitOffset);
              };
              case (?false) {}; // Do nothing
              case (null) break f; // End of bits
            }
          };
          let nextValue: Bool = bitList.pop();
          bitList.push(nextValue);
          if (nextValue)
          {
            // Have most left of byte be 1 if there is another byte
            byte := Nat8.bitset(byte, 0);;
          }
          lebBytes.add(byte);
        };
        buffer.append(lebBytes);
      };
    }
    buffer.size() - initialLength;
  };

  public func encodeNat8(buffer: Buffer<Nat8>, value: Nat8) : Nat {
    buffer.add(value);
    1;
  };

  public func encodeNat16(buffer: Buffer<Nat8>, value: Nat16, encoding: {#lsb; #msb}) : Nat {
    encodeNatX(buffer, Nat64.fromNat(Nat16.toNat(value)), encoding, 2);
  };

  public func encodeNat32(buffer: Buffer<Nat8>, value: Nat32, encoding: {#lsb; #msb}) : Nat {
    encodeNatX(buffer, Nat64.fromNat(Nat32.toNat(value)), encoding, 4);
  };

  public func encodeNat64(buffer: Buffer<Nat8>, value: Nat64, encoding: {#lsb; #msb}) : Nat {
    encodeNatX(buffer, value, encoding, 8);
  };

  public func encodeInt(buffer: Buffer<Nat8>, value: Int, encoding: {#lsb; #msb}) : Nat {
    // TODO
  };

  public func encodeInt8(buffer: Buffer<Nat8>, value: Int8, encoding: {#lsb; #msb}) : Nat {
    buffer.add(Int8.toNat8(value));
    1;
  };

  public func encodeInt16(buffer: Buffer<Nat8>, value: Int16, encoding: {#lsb; #msb}) : Nat {
    encodeIntX(buffer, Int64.fromInt(Int64.toInt(value)), encoding, 2);
  };

  public func encodeInt32(buffer: Buffer<Nat8>, value: Int32, encoding: {#lsb; #msb}) : Nat {
    encodeIntX(buffer, Int64.fromInt(Int64.toInt(value)), encoding, 4);
  };

  public func encodeInt64(buffer: Buffer<Nat8>, value: Int64, encoding: {#lsb; #msb}) : Nat {
    encodeIntX(buffer, Int64.fromInt(Int64.toInt(value)), encoding, 8);
  };

  public func encodeFloatX(buffer: Buffer<Nat8>, value: FloatX.FloatX, precision: {#f16; #f32; #f64}, encoding: {#lsb; #msb}) : Nat {
      let bitInfo: FloatBitInfo = FloatX.getPrecisionInfo(precision);
      let bits: Nat64 = switch(precision) {
        case (#f16) {

        };
      }
  };

  public func encodeFloatX(f: FloatX) : [Nat8] {
      encodeFloatInternal(f.isNegative, f.exponentBits, f.mantissaBits, bitInfo);
  };





  public func decodeNat(bytes: Iter.Iter<Nat8>, encoding: {#leb128}) : Result.Result<Nat, {}> {
    // TODO
  };

  public func decodeNat8(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat8 {
    bytes.next();
  };

  public func decodeNat16(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat16 {
    decodeNatX(bytes, encoding, 2);
  };

  public func decodeNat32(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat32 {
    decodeNatX(bytes, encoding, 4);
  };

  public func decodeNat64(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat64 {
    decodeNatX(bytes, encoding, 8);
  };

  public func decodeFloat(bytes: [Nat8]) : ?Float {
      switch(decodeFloatX(bytes)) {
          case (?fX) {
              let bitInfo = getBitInfo(fX.precision);
              ?floatXToFloatInternal(fX.isNegative, fX.exponentBits, fX.mantissaBits, bitInfo);
          };
          case (x) null;
      };
  };

  public func decodeFloatX(bytes: [Nat8]) : ?(FloatX, FloatPrecision) {
      var bits: Nat64 = Binary.BigEndian.toNat64(bytes);
      let bitInfo: FloatBitInfo = switch(bytes.size()) {
          case (2) float16BitInfo;
          case (4) float32BitInfo;
          case (8) float64BitInfo;
          case (a) return null; 
      };
      let (exponentBitLength: Nat64, mantissaBitLength: Nat64) = (bitInfo.exponentBitLength, bitInfo.mantissaBitLength);
      // Bitshift to get mantissa, exponent and sign bits
      let mantissaBits: Nat64 = bits & (Nat64.pow(2, mantissaBitLength) - 1);
      let exponentBits: Nat64 = (bits >> mantissaBitLength) & (Nat64.pow(2, exponentBitLength) - 1);
      let signBits: Nat64 = (bits >> (mantissaBitLength + exponentBitLength)) & 0x01;
      
      // Make negative if sign bit is 1
      let isNegative: Bool = signBits == 1;
      let precision = switch(bytes.size()) {
          case (2) #f16;
          case (4) #f32;
          case (8) #f64;
          case (a) return null;
      };
      ?{
          precision = precision;
          isNegative = isNegative;
          exponentBits = exponentBits;
          mantissaBits = mantissaBits;
      }
  };


  private func decodeNatX(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}, byteLength: Nat64) : Nat64 {

  };


  private func encodeFloatInternal(isNegative: Bool, exponentBits: Nat64, mantissaBits: Nat64, bitInfo: FloatBitInfo) : [Nat8] {
      var bits: Nat64 = 0;
      if(isNegative) {
          bits |= 0x01;
      };
      bits <<= bitInfo.exponentBitLength;
      bits |= exponentBits;
      bits <<= bitInfo.mantissaBitLength;
      bits |= mantissaBits;

      switch (bitInfo.precision) {
          case (#f16) {
              let nat16 = Nat16.fromNat(Nat64.toNat(bits));
              Binary.BigEndian.fromNat16(nat16);
          };
          case (#f32) {
              let nat32 = Nat32.fromNat(Nat64.toNat(bits));
              Binary.BigEndian.fromNat32(nat32);
          };
          case (#f64) {
              Binary.BigEndian.fromNat64(bits);
          };
      }
  };

  private func encodeNatX(buffer: Buffer<Nat8>, value: Nat64, encoding: {#lsb; #msb}, byteLength: Nat64) : Nat {
    for (i in Iter.range(0, byteLength - 1)) {
      let byteOffset: Nat64 = switch (encoding) {
        case (#lsb) i;
        case (#msb) byteLength - i;
      }
      let byte: Nat8 = Nat8.fromNat(Nat64.toNat(value >> byteOffset));
      buffer.add(byte);
    };
    byteLength;
  };

  private func encodeIntX(buffer: Buffer<Nat8>, value: Int64, encoding: {#lsb; #msb}, byteLength: Nat64) : Nat {
    for (i in Iter.range(0, byteLength - 1)) {
      let byteOffset: Nat64 = switch (encoding) {
        case (#lsb) i;
        case (#msb) byteLength - i;
      }
      let byte: Nat8 = Nat8.fromNat(Nat64.toNat(Int64.toNat64(value >> byteOffset)));
      buffer.add(byte);
    };
    byteLength;
  };

  private func natToBits(value: Nat) : [Bool] {
    let buffer = Buffer<Bool>(64);
    var remainingValue: Nat = value;
    while (remainingValue > 0) {
      let bit: Bool = remainingValue % 2 == 1;
      buffer.add(bit);
      remainingValue /= 2;
    };
    // Least Sigficant Bit first
    buffer.toArray();
  }

}