import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Float "mo:base/Float";

module {
  public func from64To8(value: Nat64) : Nat8 {
      Nat8.fromNat(Nat64.toNat(value));
  };

  public func from64To16(value: Nat64) : Nat16 {
      Nat16.fromNat(Nat64.toNat(value));
  };

  public func from64To32(value: Nat64) : Nat32 {
      Nat32.fromNat(Nat64.toNat(value));
  };

  public func from64ToNat(value: Nat64) : Nat {
      Nat64.toNat(value);
  };

  
  public func from32To8(value: Nat32) : Nat8 {
      Nat8.fromNat(Nat32.toNat(value));
  };

  public func from32To16(value: Nat32) : Nat16 {
      Nat16.fromNat(Nat32.toNat(value));
  };

  public func from32To64(value: Nat32) : Nat64 {
      Nat64.fromNat(Nat32.toNat(value));
  };

  public func from32ToNat(value: Nat32) : Nat {
      Nat32.toNat(value);
  };


  public func from16To8(value: Nat16) : Nat8 {
      Nat8.fromNat(Nat16.toNat(value));
  };

  public func from16To32(value: Nat16) : Nat32 {
      Nat32.fromNat(Nat16.toNat(value));
  };

  public func from16To64(value: Nat16) : Nat64 {
      Nat64.fromNat(Nat16.toNat(value));
  };

  public func from16ToNat(value: Nat16) : Nat {
      Nat16.toNat(value);
  };


  public func from8To16(value: Nat8) : Nat16 {
      Nat16.fromNat(Nat8.toNat(value));
  };

  public func from8To32(value: Nat8) : Nat32 {
      Nat32.fromNat(Nat8.toNat(value));
  };

  public func from8To64(value: Nat8) : Nat64 {
      Nat64.fromNat(Nat8.toNat(value));
  };

  public func from8ToNat(value: Nat8) : Nat {
      Nat8.toNat(value);
  };


  public func encodeNat(buffer: Buffer.Buffer<Nat8>, value: Nat, encoding: {#leb128}) : Nat {
    let initialLength = buffer.size();
    switch(encoding) {
      case (#leb128) {
        // Unsigned LEB128 - https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128
        //       10011000011101100101  In raw binary
        //      010011000011101100101  Padded to a multiple of 7 bits
        //  0100110  0001110  1100101  Split into 7-bit groups
        // 00100110 10001110 11100101  Add high 1 bits on all but last (most significant) group to form bytes
        let bits: [Bool] = natToBits(value);
        
        let byteCount: Nat = (bits.size() / 7) + (if (bits.size() % 7 != 0) 1 else 0); // 7, not 8, the 8th bit is to indicate end of number
        let lebBytes = Buffer.Buffer<Nat8>(byteCount);
        label f for (byteIndex in Iter.range(0, byteCount))
        {
          var byte: Nat8 = 0;
          for (bitOffset in Iter.range(0, 7)) {
            let bit: Bool = bits[byteIndex * 7 + bitOffset];
            if (bit) {
                // Set bit
                byte := Nat8.bitset(byte, 7 - bitOffset);
            };
          };
          var hasMoreBits = false;
          label l for (i in Iter.range((byteIndex + 1) * 7, byteCount * 7)) {
            if (bits[i]) {
              hasMoreBits := true;
              break l;
            }
          };
          if (hasMoreBits)
          {
            // Have most left of byte be 1 if there is another byte
            byte := Nat8.bitset(byte, 0);
          };
          lebBytes.add(byte);
        };
        buffer.append(lebBytes);
      };
    };
    buffer.size() - initialLength;
  };

  public func encodeNat8(buffer: Buffer.Buffer<Nat8>, value: Nat8) {
    buffer.add(value);
  };

  public func encodeNat16(buffer: Buffer.Buffer<Nat8>, value: Nat16, encoding: {#lsb; #msb}) {
    encodeNatX(buffer, Nat64.fromNat(Nat16.toNat(value)), encoding, #b16);
  };

  public func encodeNat32(buffer: Buffer.Buffer<Nat8>, value: Nat32, encoding: {#lsb; #msb}) {
    encodeNatX(buffer, Nat64.fromNat(Nat32.toNat(value)), encoding, #b32);
  };

  public func encodeNat64(buffer: Buffer.Buffer<Nat8>, value: Nat64, encoding: {#lsb; #msb}) {
    encodeNatX(buffer, value, encoding, #b64);
  };


  public func decodeNat(bytes: Iter.Iter<Nat8>, encoding: {#leb128}) : ?Nat {
    // TODO
    null;
  };

  public func decodeNat8(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat8 {
    bytes.next();
  };

  public func decodeNat16(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat16 {
    do ? { 
      let value: Nat64 = decodeNatX(bytes, encoding, #b16)!;
      from64To16(value);
    };
  };

  public func decodeNat32(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat32 {
    do ? { 
      let value: Nat64 = decodeNatX(bytes, encoding, #b32)!;
      from64To32(value);
    };
  };

  public func decodeNat64(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat64 {
    decodeNatX(bytes, encoding, #b64);
  };



  private func decodeNatX(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}, size: {#b16; #b32; #b64}) : ?Nat64 {
    let byteLength: Nat64 = getByteLength(size);
    var nat64 : Nat64 = 0;
    let lastIndex : Nat64 = byteLength - 1;
    for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
      let mask: Nat64 = switch(bytes.next()) {
        case (null) return null; // Unexpected end of bytes
        case (?b) from8To64(b) << ((lastIndex - Nat64.fromNat(i)) * 8);
      };
      nat64 |= mask;
    };
    ?nat64;
  };

  private func encodeNatX(buffer: Buffer.Buffer<Nat8>, value: Nat64, encoding: {#lsb; #msb}, size: {#b16; #b32; #b64}) {
    let byteLength: Nat64 = getByteLength(size);
    for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
      let byteOffset: Nat64 = switch (encoding) {
        case (#lsb) Nat64.fromNat(i);
        case (#msb) Nat64.fromNat(Nat64.toNat(byteLength) - i);
      };
      let byte: Nat8 = Nat8.fromNat(Nat64.toNat(value >> byteOffset));
      buffer.add(byte);
    };
  };


  private func getByteLength(size: {#b16; #b32; #b64}) : Nat64 {
    switch(size) {
      case (#b16) 2;
      case (#b32) 4;
      case (#b64) 8;
    }
  };

  private func natToBits(value: Nat) : [Bool] {
    let buffer = Buffer.Buffer<Bool>(64);
    var remainingValue: Nat = value;
    while (remainingValue > 0) {
      let bit: Bool = remainingValue % 2 == 1;
      buffer.add(bit);
      remainingValue /= 2;
    };
    // Least Sigficant Bit first
    buffer.toArray();
  };
}