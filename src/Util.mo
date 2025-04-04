import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";
import Debug "mo:base/Debug";

module {
    /// Converts a natural number to its binary representation as an array of booleans.
    ///
    /// ```motoko
    /// let bits = Util.natToLeastSignificantBits(10, 8, false);
    /// // bits is [false, true, false, true, false, false, false, false]
    /// ```
    public func natToLeastSignificantBits(value : Nat, byteLength : Nat, hasSign : Bool) : [Bool] {
        let buffer = Buffer.Buffer<Bool>(64);
        var remainingValue : Nat = value;
        while (remainingValue > 0) {
            let bit : Bool = remainingValue % 2 == 1;
            buffer.add(bit);
            remainingValue /= 2;
        };
        while (buffer.size() % byteLength != 0) {
            buffer.add(false); // Pad 0's for full byte
        };
        if (hasSign) {
            let mostSignificantBit : Bool = buffer.get(buffer.size() - 1);
            if (mostSignificantBit) {
                // If most significant bit is a 1, overflow to another byte
                for (i in Iter.range(1, byteLength)) {
                    buffer.add(false);
                };
            };
        };
        // Least Sigficant Bit first
        Buffer.toArray(buffer);
    };

    /// Encodes an array of booleans into a buffer of bytes using invariable length encoding.
    ///
    /// ```motoko
    /// let bits = [true, false, true, false, true, false, true, false];
    /// let buffer = Buffer.Buffer<Nat8>(1);
    /// Util.invariableLengthBytesEncode(buffer, bits);
    /// // buffer now contains [0x55]
    /// ```
    public func invariableLengthBytesEncode(buffer : Buffer.Buffer<Nat8>, bits : [Bool]) {

        let byteCount : Nat = (bits.size() / 7) + (if (bits.size() % 7 != 0) 1 else 0); // 7, not 8, the 8th bit is to indicate end of number

        label f for (byteIndex in Iter.range(0, byteCount - 1)) {
            var byte : Nat8 = 0;
            for (bitOffset in Iter.range(0, 6)) {
                let bit : Bool = bits[byteIndex * 7 + bitOffset];
                if (bit) {
                    // Set bit
                    byte := Nat8.bitset(byte, bitOffset);
                };
            };
            let hasMoreBits = bits.size() > (byteIndex + 1) * 7;
            if (hasMoreBits) {
                // Have most left of byte be 1 if there is another byte
                byte := Nat8.bitset(byte, 7);
            };
            buffer.add(byte);
        };
    };

    /// Decodes a byte iterator into an array of booleans using invariable length decoding.
    ///
    /// ```motoko
    /// let bytes : [Nat8] = [0x55];
    /// let bits = Util.invariableLengthBytesDecode(bytes.vals());
    /// // bits is [true, false, true, false, true, false, true]
    /// ```
    public func invariableLengthBytesDecode(bytes : Iter.Iter<Nat8>) : [Bool] {

        let buffer = Buffer.Buffer<Bool>(1);
        label f for (byte in bytes) {
            for (i in Iter.range(0, 6)) {
                let bit = Nat8.bittest(byte, i);
                buffer.add(bit);
            };
            let hasNext = Nat8.bittest(byte, 7);
            if (not hasNext) {
                break f;
            };
        };
        Buffer.toArray(buffer);
    };

    /// Performs two's complement on an array of booleans.
    ///
    /// ```motoko
    /// let bits = [true, false, true, false];
    /// let complemented = Util.twosCompliment(bits);
    /// // complemented is [true, true, false, true]
    /// ```
    public func twosCompliment(bits : [Bool]) : [Bool] {
        // Ones compliment, flip all bits
        let flippedBits = Array.map(bits, func(b : Bool) : Bool { not b });

        // Twos compliment, add 1
        let lastIndex : Nat = flippedBits.size() - 1;
        let varBits : [var Bool] = Array.thaw(flippedBits);

        // Loop through adding 1 to the LSB, and carry the 1 if neccessary
        label l for (n in Iter.range(0, lastIndex)) {
            varBits[n] := not varBits[n]; // flip
            if (varBits[n]) {
                // If flipped to 1, end
                break l;
            } else {
                // If flipped to 0, carry the one till the first 0
            };
        };
        Array.freeze(varBits);
    };

    /// Reverses the two's complement operation on an array of booleans.
    ///
    /// ```motoko
    /// let bits = [true, true, false, true];
    /// let reversed = Util.reverseTwosCompliment(bits);
    /// // reversed is [true, false, true, false]
    /// ```
    public func reverseTwosCompliment(bits : [Bool]) : [Bool] {
        // Reverse Twos compliment, remove 1
        // Find the 1 closest to the lsb, then convert it to 0 and everything toward lsb 1
        let varBits : [var Bool] = Array.thaw(bits);
        label f for (n in Iter.range(0, bits.size() - 1)) {
            let index = Int.abs(n);
            if (varBits[index]) {
                varBits[index] := false;
                for (i in Iter.revRange(index - 1, 0)) {
                    varBits[Int.abs(i)] := true;
                };
                break f;
            };
        };
        let newBits = Array.freeze(varBits);

        // Reverse Ones compliment, flip all bits
        Array.map(newBits, func(b : Bool) : Bool { not b });
    };

    /// Converts an array of booleans to a text representation.
    ///
    /// ```motoko
    /// let bits = [true, false, true, false];
    /// let text = Util.bitsToText(bits, #msb);
    /// // text is "0b1010"
    /// ```
    public func bitsToText(bits : [Bool], order : { #lsb; #msb }) : Text {
        let range = switch (order) {
            case (#msb) Iter.range(0, bits.size() - 1);
            case (#lsb) Iter.revRange(bits.size() - 1, 0);
        };
        "0b" # Text.fromIter(Iter.map<Int, Char>(range, func(i : Int) { if (bits[Int.abs(i)]) '1' else '0' }));
    };

    /// Converts an array of Nat8 to a hexadecimal string representation.
    ///
    /// ```motoko
    /// let bytes : [Nat8] = [0x12, 0x34, 0xAB];
    /// let hexString = Util.toHexString(bytes);
    /// // hexString is "0x12, 0x34, 0xAB"
    /// ```
    public func toHexString(array : [Nat8]) : Text {
        Array.foldLeft<Nat8, Text>(
            array,
            "",
            func(accum, w8) {
                var pre = "";
                if (accum != "") {
                    pre #= ", ";
                };
                accum # pre # encodeW8(w8);
            },
        );
    };
    private let base : Nat8 = 0x10;

    private let symbols = [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
    ];
    /**
    * Encode an unsigned 8-bit integer in hexadecimal format.
    */
    private func encodeW8(w8 : Nat8) : Text {
        let c1 = symbols[Nat8.toNat(w8 / base)];
        let c2 = symbols[Nat8.toNat(w8 % base)];
        "0x" # Char.toText(c1) # Char.toText(c2);
    };

    /// Converts Nat to LSB bits, pads to multiple of 8.
    public func natToPaddedBitsLSB(val : Nat) : [Bool] {
        let bitsBuffer = Buffer.Buffer<Bool>(64);
        if (val == 0) {
            // Need at least one byte for zero if requested this way
            // However, the Classic functions handle 0 separately.
            // If called with 0, produce empty bits? Or 8 false bits?
            // Let's assume the Classic wrappers handle 0, so this only sees val > 0.
        } else {
            var currentVal = val;
            while (currentVal > 0) {
                bitsBuffer.add(currentVal % 2 != 0);
                currentVal /= 2;
            };
        };

        // Pad bits to multiple of 8 (add false=0 at MSB end)
        while (bitsBuffer.size() == 0 or bitsBuffer.size() % 8 != 0) {
            bitsBuffer.add(false);
        };
        Buffer.toArray(bitsBuffer);
    };

    /// Converts LSB bits (must be multiple of 8) to LSB-ordered bytes.
    public func bitsLSBToBytesLSB(bits : [Bool]) : [Nat8] {
        if (bits.size() % 8 != 0) {
            // This shouldn't happen if natToPaddedBitsLSB is used correctly
            Debug.trap("bitsLSBToBytesLSB: Input bits count not multiple of 8");
        };
        let numBytes = bits.size() / 8;
        if (numBytes == 0) return [];

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
        Buffer.toArray(bytes);
    };

    /// Writes bytes to buffer respecting encoding order.
    public func writeBytes(buffer : Buffer.Buffer<Nat8>, bytes : [Nat8], encoding : { #lsb; #msb }) {
        switch (encoding) {
            case (#lsb) {
                // Add LSB first
                for (byte in bytes.vals()) {
                    buffer.add(byte);
                };
            };
            case (#msb) {
                // Add MSB first (reverse the LSB-ordered bytes)
                let numBytes = bytes.size();
                if (numBytes > 0) {
                    for (i in Iter.revRange(numBytes - 1, 0)) {
                        buffer.add(bytes[Int.abs(i)]);
                    };
                };
            };
        };
    };

    /// Reads all bytes from iterator. Returns null if iterator is initially empty.
    public func readAllBytes(iter : Iter.Iter<Nat8>) : ?[Nat8] {
        let bytesBuffer = Buffer.Buffer<Nat8>(16);
        var hasBytes = false;
        for (byte in iter) {
            hasBytes := true;
            bytesBuffer.add(byte);
        };
        if (not hasBytes) { return null } else {
            return ?Buffer.toArray(bytesBuffer);
        };
    };

    /// Converts bytes (ordered by encoding) to LSB-ordered bits.
    public func bytesToBitsLSB(bytes : [Nat8], encoding : { #lsb; #msb }) : [Bool] {
        let numBytes = bytes.size();
        if (numBytes == 0) return [];

        let totalBits = numBytes * 8;
        var bits = Buffer.Buffer<Bool>(totalBits);
        let byteRange = switch (encoding) {
            case (#lsb) Iter.range(0, numBytes - 1); // Process LSB byte first
            case (#msb) Iter.revRange(numBytes - 1, 0); // Process MSB byte first
        };

        // Always build the 'bits' array in LSB order
        for (i in byteRange) {
            let byte = bytes[Int.abs(i)]; // Use Nat.abs for revRange index
            for (j in Iter.range(0, 7)) {
                // LSB (bit 0) to MSB (bit 7) within byte
                bits.add(Nat8.bittest(byte, j));
            };
        };
        Buffer.toArray(bits);
    };

    /// Converts LSB-ordered bits to Nat.
    public func bitsLSBToNat(bits : [Bool]) : Nat {
        var value : Nat = 0;
        var powerOfTwo : Nat = 1; // Start with 2^0
        let lastIndex : Nat = bits.size() - 1;
        for (i in Iter.range(0, lastIndex)) {
            if (bits[i]) {
                value += powerOfTwo;
            };
            if (i < lastIndex) {
                // Avoid overflow on last iteration if Nat has limits
                powerOfTwo *= 2; // Safe arbitrary precision Nat handles large powers
            };
        };
        value;
    };
};
