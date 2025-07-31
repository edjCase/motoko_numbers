import Buffer "mo:buffer";
import Int "mo:core/Int";
import Int16 "mo:core/Int16";
import Int32 "mo:core/Int32";
import Int64 "mo:core/Int64";
import Int8 "mo:core/Int8";
import Iter "mo:core/Iter";
import List "mo:core/List";
import Nat64 "mo:core/Nat64";
import Nat8 "mo:core/Nat8";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import NatX "./NatX";
import Util "./Util";
import Text "mo:core/Text";

module {
  public type Format = NatX.Format;

  /// Converts text representation of a decimal integer to an Int.
  ///
  /// ```motoko
  /// let result = IntX.fromText("-123");
  /// switch (result) {
  ///   case (null) { /* Invalid input */ };
  ///   case (?value) { /* value is -123 */ };
  /// };
  /// ```
  public func fromText(value : Text) : ?Int {
    fromTextAdvanced(value, #decimal, null);
  };

  /// Converts text representation of an integer in a specified format to an Int.
  ///
  /// ```motoko
  /// let result = IntX.fromTextAdvanced("-1010", #binary, null);
  /// switch (result) {
  ///   case (null) { /* Invalid input */ };
  ///   case (?value) { /* value is -10 */ };
  /// };
  /// ```
  public func fromTextAdvanced(value : Text, format : Format, seperator : ?Char) : ?Int {
    do ? {
      let isNegative = Text.startsWith(value, #char('-'));
      let natTextValue = if (isNegative) {
        // TODO better way to do substring?
        let iter = value.chars();
        let _ = iter.next(); // Skip first char '-'
        Text.fromIter(iter); // Negative sign, remove to make it a Nat
      } else {
        value; // No negative sign, use as is
      };
      let natValue = NatX.fromTextAdvanced(natTextValue, format, seperator)!;
      if (isNegative) { -1 * natValue } else { natValue }; // Revert to negative if was negative
    };
  };

  /// Converts an Int to its decimal text representation.
  ///
  /// ```motoko
  /// let text = IntX.toText(-123);
  /// // text is "-123"
  /// ```
  public func toText(value : Int) : Text {
    toTextAdvanced(value, #decimal);
  };

  /// Converts an Int to its text representation in a specified format.
  ///
  /// ```motoko
  /// let text = IntX.toTextAdvanced(-10, #binary);
  /// // text is "-1010"
  /// ```
  public func toTextAdvanced(value : Int, format : Format) : Text {
    let natValue : Nat = Int.abs(value); // Convert to nat to use NatX.toTextAdvanced
    let isNegative = natValue != value;
    let natTextValue = NatX.toTextAdvanced(natValue, format);
    if (isNegative) { "-" # natTextValue } else { natTextValue }; // Add negative sign if negative
  };

  /// Converts Int64 to Int8. Traps on overflow/underflow.
  ///
  /// ```motoko
  /// let value : Int64 = 127;
  /// let result : Int8 = IntX.from64To8(value);
  /// // result is 127
  /// ```
  public func from64To8(value : Int64) : Int8 {
    Int8.fromInt(Int64.toInt(value));
  };

  /// Converts Int64 to Int16. Traps on overflow/underflow.
  ///
  /// ```motoko
  /// let value : Int64 = 32767;
  /// let result : Int16 = IntX.from64To16(value);
  /// // result is 32767
  /// ```
  public func from64To16(value : Int64) : Int16 {
    Int16.fromInt(Int64.toInt(value));
  };

  /// Converts Int64 to Int32. Traps on overflow/underflow.
  ///
  /// ```motoko
  /// let value : Int64 = 2147483647;
  /// let result : Int32 = IntX.from64To32(value);
  /// // result is 2147483647
  /// ```
  public func from64To32(value : Int64) : Int32 {
    Int32.fromInt(Int64.toInt(value));
  };

  /// Converts Int64 to Int.
  ///
  /// ```motoko
  /// let value : Int64 = 9223372036854775807;
  /// let result : Int = IntX.from64ToInt(value);
  /// // result is 9223372036854775807
  /// ```
  public func from64ToInt(value : Int64) : Int {
    Int64.toInt(value);
  };

  /// Converts Int32 to Int8. Traps on overflow/underflow.
  ///
  /// ```motoko
  /// let value : Int32 = 127;
  /// let result : Int8 = IntX.from32To8(value);
  /// // result is 127
  /// ```
  public func from32To8(value : Int32) : Int8 {
    Int8.fromInt(Int32.toInt(value));
  };

  /// Converts Int32 to Int16. Traps on overflow/underflow.
  ///
  /// ```motoko
  /// let value : Int32 = 32767;
  /// let result : Int16 = IntX.from32To16(value);
  /// // result is 32767
  /// ```
  public func from32To16(value : Int32) : Int16 {
    Int16.fromInt(Int32.toInt(value));
  };

  /// Converts Int32 to Int64.
  ///
  /// ```motoko
  /// let value : Int32 = 2147483647;
  /// let result : Int64 = IntX.from32To64(value);
  /// // result is 2147483647
  /// ```
  public func from32To64(value : Int32) : Int64 {
    Int64.fromInt(Int32.toInt(value));
  };

  /// Converts Int32 to Int.
  ///
  /// ```motoko
  /// let value : Int32 = 2147483647;
  /// let result : Int = IntX.from32ToInt(value);
  /// // result is 2147483647
  /// ```
  public func from32ToInt(value : Int32) : Int {
    Int32.toInt(value);
  };

  /// Converts Int16 to Int8. Traps on overflow/underflow.
  ///
  /// ```motoko
  /// let value : Int16 = 127;
  /// let result : Int8 = IntX.from16To8(value);
  /// // result is 127
  /// ```
  public func from16To8(value : Int16) : Int8 {
    Int8.fromInt(Int16.toInt(value));
  };

  /// Converts Int16 to Int32.
  ///
  /// ```motoko
  /// let value : Int16 = 32767;
  /// let result : Int32 = IntX.from16To32(value);
  /// // result is 32767
  /// ```
  public func from16To32(value : Int16) : Int32 {
    Int32.fromInt(Int16.toInt(value));
  };

  /// Converts Int16 to Int64.
  ///
  /// ```motoko
  /// let value : Int16 = 32767;
  /// let result : Int64 = IntX.from16To64(value);
  /// // result is 32767
  /// ```
  public func from16To64(value : Int16) : Int64 {
    Int64.fromInt(Int16.toInt(value));
  };

  /// Converts Int16 to Int.
  ///
  /// ```motoko
  /// let value : Int16 = 32767;
  /// let result : Int = IntX.from16ToInt(value);
  /// // result is 32767
  /// ```
  public func from16ToInt(value : Int16) : Int {
    Int16.toInt(value);
  };

  /// Converts Int8 to Int16.
  ///
  /// ```motoko
  /// let value : Int8 = 127;
  /// let result : Int16 = IntX.from8To16(value);
  /// // result is 127
  /// ```
  public func from8To16(value : Int8) : Int16 {
    Int16.fromInt(Int8.toInt(value));
  };

  /// Converts Int8 to Int32.
  ///
  /// ```motoko
  /// let value : Int8 = 127;
  /// let result : Int32 = IntX.from8To32(value);
  /// // result is 127
  /// ```
  public func from8To32(value : Int8) : Int32 {
    Int32.fromInt(Int8.toInt(value));
  };

  /// Converts Int8 to Int64.
  ///
  /// ```motoko
  /// let value : Int8 = 127;
  /// let result : Int64 = IntX.from8To64(value);
  /// // result is 127
  /// ```
  public func from8To64(value : Int8) : Int64 {
    Int64.fromInt(Int8.toInt(value));
  };

  /// Converts Int8 to Int.
  ///
  /// ```motoko
  /// let value : Int8 = 127;
  /// let result : Int = IntX.from8ToInt(value);
  /// // result is 127
  /// ```
  public func from8ToInt(value : Int8) : Int {
    Int8.toInt(value);
  };

  /// Encodes an Int to a byte array using the specified encoding.
  ///
  /// ```motoko
  /// let bytes = IntX.toIntBytes(-123, #signedLEB128);
  /// // bytes contains the encoded bytes
  /// ```
  public func toIntBytes(value : Int, encoding : { #signedLEB128; #msb; #lsb }) : [Nat8] {
    let list = List.empty<Nat8>();
    let buffer = Buffer.fromList(list);
    toIntBytesBuffer(buffer, value, encoding);
    List.toArray(list);
  };

  /// Encodes an Int to a byte buffer using the specified encoding.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(8);
  /// IntX.toIntBytesBuffer(buffer, -123, #signedLEB128);
  /// // buffer now contains the encoded bytes
  /// ```
  public func toIntBytesBuffer(buffer : Buffer.Buffer<Nat8>, value : Int, encoding : { #signedLEB128; #msb; #lsb }) {
    switch (encoding) {
      case (#msb) encodeIntClassic(buffer, value, #msb);
      case (#lsb) encodeIntClassic(buffer, value, #lsb);
      case (#signedLEB128) {
        if (value == 0) {
          buffer.write(0);
          return;
        };
        // Signed LEB128 - https://en.wikipedia.org/wiki/LEB128#Signed_LEB128
        //         11110001001000000  Binary encoding of 123456
        //   00001_11100010_01000000  As a 21-bit number (multiple of 7)
        //   11110_00011101_10111111  Negating all bits (one's complement)
        //   11110_00011101_11000000  Adding one (two's complement) (Binary encoding of signed -123456)
        // 1111000  0111011  1000000  Split into 7-bit groups
        //01111000 10111011 11000000  Add high 1 bits on all but last (most significant) group to form bytes
        let positiveValue = Int.abs(value);
        var bits : [Bool] = Util.natToLeastSignificantBits(positiveValue, 7, true);
        if (value < 0) {
          // If negative, then get twos compliment
          bits := Util.twosCompliment(bits);
        };
        Util.invariableLengthBytesEncode(buffer, bits);
      };
    };
  };

  /// Encodes an Int to a byte buffer using the specified encoding.
  /// Encodes an Int8 to a byte array.
  ///
  /// ```motoko
  /// let bytes = IntX.toInt8Bytes(-123);
  /// // bytes contains the encoded byte
  /// ```
  public func toInt8Bytes(value : Int8) : [Nat8] {
    let list = List.empty<Nat8>();
    let buffer = Buffer.fromList(list);
    toInt8BytesBuffer(buffer, value);
    List.toArray(list);
  };

  /// Encodes an Int8 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(1);
  /// IntX.toInt8BytesBuffer(buffer, -123);
  /// // buffer now contains the encoded byte
  /// ```
  public func toInt8BytesBuffer(buffer : Buffer.Buffer<Nat8>, value : Int8) {
    buffer.write(Int8.toNat8(value));
  };

  /// Encodes an Int8 to a byte buffer.
  /// Encodes an Int16 to a byte array.
  ///
  /// ```motoko
  /// let bytes = IntX.toInt16Bytes(-12345, #lsb);
  /// // bytes contains the encoded bytes
  /// ```
  public func toInt16Bytes(value : Int16, encoding : { #lsb; #msb }) : [Nat8] {
    let list = List.empty<Nat8>();
    let buffer = Buffer.fromList(list);
    toInt16BytesBuffer(buffer, value, encoding);
    List.toArray(list);
  };

  /// Encodes an Int16 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(2);
  /// IntX.toInt16BytesBuffer(buffer, -12345, #lsb);
  /// // buffer now contains the encoded bytes
  /// ```
  public func toInt16BytesBuffer(buffer : Buffer.Buffer<Nat8>, value : Int16, encoding : { #lsb; #msb }) {
    encodeIntX(buffer, Int64.fromInt(Int16.toInt(value)), encoding, #b16);
  };

  /// Encodes an Int16 to a byte buffer.
  /// Encodes an Int32 to a byte array.
  ///
  /// ```motoko
  /// let bytes = IntX.toInt32Bytes(-1234567890, #lsb);
  /// // bytes contains the encoded bytes
  /// ```
  public func toInt32Bytes(value : Int32, encoding : { #lsb; #msb }) : [Nat8] {
    let list = List.empty<Nat8>();
    let buffer = Buffer.fromList(list);
    toInt32BytesBuffer(buffer, value, encoding);
    List.toArray(list);
  };

  /// Encodes an Int32 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(4);
  /// IntX.toInt32BytesBuffer(buffer, -1234567890, #lsb);
  /// // buffer now contains the encoded bytes
  /// ```
  public func toInt32BytesBuffer(buffer : Buffer.Buffer<Nat8>, value : Int32, encoding : { #lsb; #msb }) {
    encodeIntX(buffer, Int64.fromInt(Int32.toInt(value)), encoding, #b32);
  };

  /// Encodes an Int32 to a byte buffer.
  /// Encodes an Int64 to a byte array.
  ///
  /// ```motoko
  /// let bytes = IntX.toInt64Bytes(-1234567890123456789, #lsb);
  /// // bytes contains the encoded bytes
  /// ```
  public func toInt64Bytes(value : Int64, encoding : { #lsb; #msb }) : [Nat8] {
    let list = List.empty<Nat8>();
    let buffer = Buffer.fromList(list);
    toInt64BytesBuffer(buffer, value, encoding);
    List.toArray(list);
  };

  /// Encodes an Int64 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(8);
  /// IntX.toInt64BytesBuffer(buffer, -1234567890123456789, #lsb);
  /// // buffer now contains the encoded bytes
  /// ```
  public func toInt64BytesBuffer(buffer : Buffer.Buffer<Nat8>, value : Int64, encoding : { #lsb; #msb }) {
    encodeIntX(buffer, Int64.fromInt(Int64.toInt(value)), encoding, #b64);
  };

  /// Encodes an Int64 to a byte buffer.
  /// Decodes an Int from a byte iterator using signed LEB128 encoding.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0xc6, 0xf5, 0x08]; // -123456 in signed LEB128
  /// let result = IntX.fromIntBytes(bytes.vals(), #signedLEB128);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -123456 */ };
  /// };
  /// ```
  public func fromIntBytes(bytes : Iter.Iter<Nat8>, encoding : { #signedLEB128; #lsb; #msb }) : ?Int {
    do ? {
      switch (encoding) {
        case (#msb) return fromIntClassicBytes(bytes, #msb);
        case (#lsb) return fromIntClassicBytes(bytes, #lsb);
        case (#signedLEB128) {
          var bits : [Bool] = Util.invariableLengthBytesDecode(bytes);
          let isNegative = bits[bits.size() - 1];
          if (isNegative) {
            // Reverse twos compliment
            bits := Util.reverseTwosCompliment(bits);
          };
          var i = 0;
          let int = Array.foldLeft<Bool, Int>(
            bits,
            0,
            func(accum : Int, bit : Bool) {
              let newAccum = if (bit) {
                accum + Nat.pow(2, i); // Shift over 7 * i bits to get value to add, ignore first bit
              } else {
                accum;
              };
              i += 1;
              newAccum;
            },
          );
          if (isNegative) {
            int * -1;
          } else {
            int;
          };
        };
      };
    };
  };
  /// Decodes an Int8 from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0x85]; // -123 in two's complement
  /// let result = IntX.fromInt8Bytes(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -123 */ };
  /// };
  /// ```
  public func fromInt8Bytes(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int8 {
    do ? {
      let bits : [Bool] = fromIntXBytes(bytes, encoding, #b8)!;
      bitsToInt<Int8>(bits, 0, Int8.bitset);
    };
  };

  /// Decodes an Int16 from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0x30, 0xcf]; // -12496 in little-endian
  /// let result = IntX.fromInt16Bytes(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -12496 */ };
  /// };
  /// ```
  public func fromInt16Bytes(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int16 {
    do ? {
      let bits : [Bool] = fromIntXBytes(bytes, encoding, #b16)!;
      bitsToInt<Int16>(bits, 0, Int16.bitset);
    };
  };

  /// Decodes an Int32 from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0x2e, 0xf3, 0xff, 0xff]; // -3282 in little-endian
  /// let result = IntX.fromInt32Bytes(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -3282 */ };
  /// };
  /// ```
  public func fromInt32Bytes(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int32 {
    do ? {
      let bits : [Bool] = fromIntXBytes(bytes, encoding, #b32)!;
      bitsToInt<Int32>(bits, 0, Int32.bitset);
    };
  };

  /// Decodes an Int64 from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f]; // 9223372036854775807 in little-endian
  /// let result = IntX.fromInt64Bytes(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is 9223372036854775807 */ };
  /// };
  /// ```
  public func fromInt64Bytes(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int64 {
    do ? {
      let bits : [Bool] = fromIntXBytes(bytes, encoding, #b64)!;
      bitsToInt<Int64>(bits, 0, Int64.bitset);
    };
  };

  private func fromIntXBytes(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }, size : { #b8; #b16; #b32; #b64 }) : ?[Bool] {
    do ? {
      let byteLength : Nat64 = getByteLength(size);
      var nat64 : Nat64 = 0;
      for (i in Nat.range(0, Nat64.toNat(byteLength))) {
        let b : Nat8 = bytes.next()!;
        let byteOffset : Nat64 = switch (encoding) {
          case (#lsb) Nat64.fromNat(i);
          case (#msb) Nat64.fromNat(Nat64.toNat(byteLength - 1) - i);
        };
        nat64 |= NatX.from8To64(b) << (byteOffset * 8);
      };
      // Convert to bits in LSB order
      var bits : [Bool] = Array.tabulate<Bool>(Nat64.toNat(byteLength * 8), func(i : Nat) { Nat64.bittest(nat64, i) });
      bits;
    };
  };

  private func bitsToInt<T>(bits : [Bool], initial : T, bitset : (T, Nat) -> T) : T {
    var bitOffset = 0;
    Array.foldLeft<Bool, T>(
      bits,
      initial,
      func(accum : T, x : Bool) {
        let newAccum : T = if (not x) {
          accum; // Dont set if 0
        } else {
          bitset(accum, bitOffset); // Set if 1
        };
        bitOffset += 1;
        newAccum;
      },
    );
  };

  private func getByteLength(size : { #b8; #b16; #b32; #b64 }) : Nat64 {
    switch (size) {
      case (#b8) 1;
      case (#b16) 2;
      case (#b32) 4;
      case (#b64) 8;
    };
  };

  private func encodeIntX(buffer : Buffer.Buffer<Nat8>, value : Int64, encoding : { #lsb; #msb }, size : { #b16; #b32; #b64 }) {
    let byteLength : Nat64 = getByteLength(size);
    for (i in Nat.range(0, Nat64.toNat(byteLength))) {
      let byteOffset : Int64 = switch (encoding) {
        case (#lsb) Int64.fromInt(i);
        case (#msb) Int64.fromInt(Nat64.toNat(byteLength - 1) - i);
      };
      let byte : Int64 = (value >> (byteOffset * 8)) & 0xff;
      buffer.write(Nat8.fromNat(Int.abs(Int64.toInt(byte))));
    };
  };

  /// Encodes an arbitrary precision Int using MSB or LSB classic two's complement.
  private func encodeIntClassic(buffer : Buffer.Buffer<Nat8>, value : Int, encoding : { #lsb; #msb }) {
    if (value == 0) {
      buffer.write(0); // Handle 0 separately
      return;
    };

    let isNegative = value < 0;
    let natValue = Int.abs(value);

    // Use helper for bits from absolute value
    var bits = Util.natToPaddedBitsLSB(natValue);

    // Int specific: Apply two's complement if negative
    if (isNegative) {
      bits := Util.twosCompliment(bits); // Assumes Util.twosCompliment exists and works on LSB bits
    };

    // Int specific: Check MSB for sign extension necessity
    if (bits.size() > 0) {
      // Ensure not empty (shouldn't be if value != 0)
      let msbIndex : Nat = bits.size() - 1;
      let msb = bits[msbIndex];

      if (isNegative and not msb) {
        // Negative number requires MSB=1. Pad with 0xFF byte (8 true bits at MSB end)
        let newBits = List.empty<Bool>();
        for (b in bits.vals()) { List.add(newBits, b) };
        for (_ in Nat.range(1, 9)) { List.add(newBits, true) }; // Add 8 'true' bits
        bits := List.toArray(newBits);
      } else if (not isNegative and msb) {
        // Positive number requires MSB=0. Pad with 0x00 byte (8 false bits at MSB end)
        let newBits = List.empty<Bool>();
        for (b in bits.vals()) { List.add(newBits, b) };
        for (_ in Nat.range(1, 9)) { List.add(newBits, false) }; // Add 8 'false' bits
        bits := List.toArray(newBits);
      };
    };

    // Use helpers for final steps
    let bytes = Util.bitsLSBToBytesLSB(bits);
    Util.writeBytes(buffer, bytes, encoding);
  };

  /// Decodes an arbitrary precision Int using MSB or LSB classic two's complement.
  /// Reads all bytes from the iterator.
  private func fromIntClassicBytes(bytesIter : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int {
    // Use helper to read bytes
    let bytesOpt = Util.readAllBytes(bytesIter);
    let bytes = switch (bytesOpt) {
      case (null) return null;
      case (?b) b;
    };
    // Handle all zero bytes case -> 0
    var allZero = true;
    label f for (b in bytes.vals()) {
      if (b != 0) { allZero := false; break f };
    };
    if (allZero) return ?0;

    // Use helper to get LSB bits
    var bits = Util.bytesToBitsLSB(bytes, encoding);

    // Int specific: Check sign bit (MSB of the number = last bit in LSB order)
    let isNegative = if (bits.size() == 0) false else bits[bits.size() - 1];

    // Int specific: Apply reverse two's complement if negative
    if (isNegative) {
      bits := Util.reverseTwosCompliment(bits);
    };

    // Use helper to convert (potentially positive-ified) bits to Nat
    let natValue = Util.bitsLSBToNat(bits);

    // Int specific: Negate if necessary
    if (isNegative) {
      return ?(-natValue);
    } else {
      return ?natValue;
    };
  };

};
