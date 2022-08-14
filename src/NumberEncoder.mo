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

  public func encodeNat(buffer: Buffer<Nat8>, value: Nat, format: {#leb128}) {
    switch(format) {
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
            byte := Nat8.bitset(byte, bitOffset);;
          }
          lebBytes.add(byteValue);
        };
        return lebBytes;
      };
    }
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