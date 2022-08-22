import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";

module {
  public func natToLeastSignificantBits(value: Nat, byteSize: Nat) : [Bool] {
    let buffer = Buffer.Buffer<Bool>(64);
    var remainingValue: Nat = value;
    while (remainingValue > 0) {
      let bit: Bool = remainingValue % 2 == 1;
      buffer.add(bit);
      remainingValue /= 2;
    };
    while (buffer.size() % byteSize != 0) {
      buffer.add(false); // Pad 0's for full byte
    };
    // Least Sigficant Bit first
    buffer.toArray();
  };

  public func invariableLengthBytesEncode(buffer: Buffer.Buffer<Nat8>, bits: [Bool]) {
    
    let byteCount: Nat = (bits.size() / 7) + (if (bits.size() % 7 != 0) 1 else 0); // 7, not 8, the 8th bit is to indicate end of number
    
    let lebBytes = Buffer.Buffer<Nat8>(byteCount);
    label f for (byteIndex in Iter.range(0, byteCount - 1))
    {
        var byte: Nat8 = 0;
        for (bitOffset in Iter.range(0, 6)) {
        let bit: Bool = bits[byteIndex * 7 + bitOffset];
        if (bit) {
            // Set bit
            byte := Nat8.bitset(byte, bitOffset);
        };
        };
        let hasMoreBits = bits.size() > (byteIndex + 1) * 7;
        if (hasMoreBits)
        {
        // Have most left of byte be 1 if there is another byte
        byte := Nat8.bitset(byte, 7);
        };
        lebBytes.add(byte);
    };
    
    buffer.append(lebBytes);
  }
}