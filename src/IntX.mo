import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import NatX "./NatX";
import Util "./Util";
import Text "mo:base/Text";

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

  /// Encodes an Int to a byte buffer using signed LEB128 encoding.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(8);
  /// IntX.encodeInt(buffer, -123, #signedLEB128);
  /// // buffer now contains the encoded bytes
  /// ```
  public func encodeInt(buffer : Buffer.Buffer<Nat8>, value : Int, encoding : { #signedLEB128; #msb; #lsb }) {
    switch (encoding) {
      case (#msb) encodeIntClassic(buffer, value, #msb);
      case (#lsb) encodeIntClassic(buffer, value, #lsb);
      case (#signedLEB128) {
        if (value == 0) {
          buffer.add(0);
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

  /// Encodes an Int8 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(1);
  /// IntX.encodeInt8(buffer, -123);
  /// // buffer now contains the encoded byte
  /// ```
  public func encodeInt8(buffer : Buffer.Buffer<Nat8>, value : Int8) {
    buffer.add(Int8.toNat8(value));
  };

  /// Encodes an Int16 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(2);
  /// IntX.encodeInt16(buffer, -12345, #lsb);
  /// // buffer now contains the encoded bytes
  /// ```
  public func encodeInt16(buffer : Buffer.Buffer<Nat8>, value : Int16, encoding : { #lsb; #msb }) {
    encodeIntX(buffer, Int64.fromInt(Int16.toInt(value)), encoding, #b16);
  };

  /// Encodes an Int32 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(4);
  /// IntX.encodeInt32(buffer, -1234567890, #lsb);
  /// // buffer now contains the encoded bytes
  /// ```
  public func encodeInt32(buffer : Buffer.Buffer<Nat8>, value : Int32, encoding : { #lsb; #msb }) {
    encodeIntX(buffer, Int64.fromInt(Int32.toInt(value)), encoding, #b32);
  };

  /// Encodes an Int64 to a byte buffer.
  ///
  /// ```motoko
  /// let buffer = Buffer.Buffer<Nat8>(8);
  /// IntX.encodeInt64(buffer, -1234567890123456789, #lsb);
  /// // buffer now contains the encoded bytes
  /// ```
  public func encodeInt64(buffer : Buffer.Buffer<Nat8>, value : Int64, encoding : { #lsb; #msb }) {
    encodeIntX(buffer, Int64.fromInt(Int64.toInt(value)), encoding, #b64);
  };

  /// Decodes an Int from a byte iterator using signed LEB128 encoding.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0xc6, 0xf5, 0x08]; // -123456 in signed LEB128
  /// let result = IntX.decodeInt(bytes.vals(), #signedLEB128);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -123456 */ };
  /// };
  /// ```
  public func decodeInt(bytes : Iter.Iter<Nat8>, encoding : { #signedLEB128; #lsb; #msb }) : ?Int {
    do ? {
      switch (encoding) {
        case (#msb) return decodeIntClassic(bytes, #msb);
        case (#lsb) return decodeIntClassic(bytes, #lsb);
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
  /// let result = IntX.decodeInt8(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -123 */ };
  /// };
  /// ```
  public func decodeInt8(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int8 {
    do ? {
      let bits : [Bool] = decodeIntX(bytes, encoding, #b8)!;
      bitsToInt<Int8>(bits, 0, Int8.bitset);
    };
  };

  /// Decodes an Int16 from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0x30, 0xcf]; // -12496 in little-endian
  /// let result = IntX.decodeInt16(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -12496 */ };
  /// };
  /// ```
  public func decodeInt16(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int16 {
    do ? {
      let bits : [Bool] = decodeIntX(bytes, encoding, #b16)!;
      bitsToInt<Int16>(bits, 0, Int16.bitset);
    };
  };

  /// Decodes an Int32 from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0x2e, 0xf3, 0xff, 0xff]; // -3282 in little-endian
  /// let result = IntX.decodeInt32(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is -3282 */ };
  /// };
  /// ```
  public func decodeInt32(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int32 {
    do ? {
      let bits : [Bool] = decodeIntX(bytes, encoding, #b32)!;
      bitsToInt<Int32>(bits, 0, Int32.bitset);
    };
  };

  /// Decodes an Int64 from a byte iterator.
  ///
  /// ```motoko
  /// let bytes : [Nat8] = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f]; // 9223372036854775807 in little-endian
  /// let result = IntX.decodeInt64(bytes.vals(), #lsb);
  /// switch (result) {
  ///   case (null) { /* Decoding error */ };
  ///   case (?value) { /* value is 9223372036854775807 */ };
  /// };
  /// ```
  public func decodeInt64(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int64 {
    do ? {
      let bits : [Bool] = decodeIntX(bytes, encoding, #b64)!;
      bitsToInt<Int64>(bits, 0, Int64.bitset);
    };
  };

  private func decodeIntX(bytes : Iter.Iter<Nat8>, encoding : { #lsb; #msb }, size : { #b8; #b16; #b32; #b64 }) : ?[Bool] {
    do ? {
      let byteLength : Nat64 = getByteLength(size);
      var nat64 : Nat64 = 0;
      for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
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
    for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
      let byteOffset : Int64 = switch (encoding) {
        case (#lsb) Int64.fromInt(i);
        case (#msb) Int64.fromInt(Nat64.toNat(byteLength - 1) - i);
      };
      let byte : Int64 = (value >> (byteOffset * 8)) & 0xff;
      buffer.add(Nat8.fromNat(Int.abs(Int64.toInt(byte))));
    };
  };

  /// Encodes an arbitrary precision Int using MSB or LSB classic two's complement.
  private func encodeIntClassic(buffer : Buffer.Buffer<Nat8>, value : Int, encoding : { #lsb; #msb }) {
    if (value == 0) {
      buffer.add(0);
      return;
    };

    let isNegative = value < 0;
    let natValue = Int.abs(value);

    // 1. Get bits of absolute value (LSB order) using manual loop
    var currentVal = natValue;
    let bitsBuffer = Buffer.Buffer<Bool>(64); // Start with reasonable capacity
    if (currentVal == 0) {
      // Should not happen if value != 0, but safety
      bitsBuffer.add(false);
    } else {
      while (currentVal > 0) {
        bitsBuffer.add(currentVal % 2 != 0);
        currentVal /= 2;
      };
    };

    // 2. Pad to multiple of 8 bits (add false=0 at MSB end)
    while (bitsBuffer.size() % 8 != 0) {
      bitsBuffer.add(false);
    };

    var bits = Buffer.toArray(bitsBuffer);

    // 3. Apply two's complement if negative
    if (isNegative) {
      bits := Util.twosCompliment(bits);
    };

    // 4. Check MSB for sign extension necessity
    let msbIndex : Nat = bits.size() - 1;
    if (isNegative and not bits[msbIndex]) {
      // Negative number requires MSB to be 1. Pad with 0xFF byte (8 true bits at MSB end)
      let currentSize = bits.size();
      let newBits = Buffer.Buffer<Bool>(currentSize + 8);
      for (b in bits.vals()) { newBits.add(b) };
      for (_ in Iter.range(1, 8)) { newBits.add(true) };
      bits := Buffer.toArray(newBits);
    } else if (not isNegative and bits[msbIndex]) {
      // Positive number requires MSB to be 0. Pad with 0x00 byte (8 false bits at MSB end)
      let currentSize = bits.size();
      let newBits = Buffer.Buffer<Bool>(currentSize + 8);
      for (b in bits.vals()) { newBits.add(b) };
      for (_ in Iter.range(1, 8)) { newBits.add(false) };
      bits := Buffer.toArray(newBits);
    };

    // 5. Convert LSB-ordered bits to bytes
    let numBytes = bits.size() / 8;
    var bytes = Buffer.Buffer<Nat8>(numBytes);
    for (i in Iter.range(0, numBytes - 1)) {
      var byte : Nat8 = 0;
      for (j in Iter.range(0, 7)) {
        let bitIndex = i * 8 + j;
        if (bits[bitIndex]) {
          byte := Nat8.bitset(byte, j);
        };
      };
      bytes.add(byte);
    };

    // 6. Add bytes to output buffer in correct order
    let bytesArray = Buffer.toArray(bytes);
    switch (encoding) {
      case (#lsb) {
        // Add LSB first
        for (byte in bytesArray.vals()) {
          buffer.add(byte);
        };
      };
      case (#msb) {
        // Add MSB first (reverse the generated LSB-first bytes)
        for (i in Iter.revRange(numBytes - 1, 0)) {
          buffer.add(bytesArray[Int.abs(i)]);
        };
      };
    };
  };

  /// Decodes an arbitrary precision Int using MSB or LSB classic two's complement.
  /// Reads all bytes from the iterator.
  private func decodeIntClassic(bytesIter : Iter.Iter<Nat8>, encoding : { #lsb; #msb }) : ?Int {
    // 1. Read all bytes from iterator
    let bytesBuffer = Buffer.Buffer<Nat8>(16); // Start with some capacity
    for (byte in bytesIter) {
      bytesBuffer.add(byte);
    };

    if (bytesBuffer.size() < 1) {
      return null; // No input bytes
    };
    if (bytesBuffer.size() == 1 and bytesBuffer.get(0) == 0) {
      return ?0; // Special case for zero
    };

    let bytesArray = Buffer.toArray(bytesBuffer);
    let numBytes = bytesArray.size();

    // 2. Convert bytes to LSB-ordered bits
    let totalBits = numBytes * 8;
    var bits = Buffer.Buffer<Bool>(totalBits);
    let byteRange = switch (encoding) {
      case (#lsb) Iter.range(0, numBytes - 1); // Process LSB byte first
      case (#msb) Iter.revRange(numBytes - 1, 0); // Process MSB byte first, but add its bits LSB->MSB
    };

    // Always build the 'bits' array in LSB order
    for (i in byteRange) {
      let byte = bytesArray[Int.abs(i)]; // Use Nat.abs for revRange index
      for (j in Iter.range(0, 7)) {
        // LSB (bit 0) to MSB (bit 7) within byte
        bits.add(Nat8.bittest(byte, j));
      };
    };
    let finalBits = Buffer.toArray(bits);

    // 3. Check sign bit (MSB of the entire sequence, which is the last bit in LSB order)
    let isNegative = finalBits[finalBits.size() - 1];

    // 4. Convert bits to Int
    if (isNegative) {
      // Negative: reverse two's complement, convert to Nat, then negate
      let positiveBits = Util.reverseTwosCompliment(finalBits);
      let natValue = bitsToNatLSB(positiveBits);
      return ?-natValue;
    } else {
      // Positive: convert directly to Nat, then to Int
      let natValue = bitsToNatLSB(finalBits);
      return ?natValue;
    };
  };

  /// Helper to convert LSB-ordered bits to Nat
  private func bitsToNatLSB(bits : [Bool]) : Nat {
    var value : Nat = 0;
    var powerOfTwo : Nat = 1; // Start with 2^0
    for (i in Iter.range(0, bits.size() - 1)) {
      if (bits[i]) {
        value += powerOfTwo;
      };
      powerOfTwo *= 2; // Move to next power of 2
    };
    value;
  };
};
