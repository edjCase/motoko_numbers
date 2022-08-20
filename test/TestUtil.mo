import Char "mo:base/Char";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module {
    public func bytesAreEqual(b1: [Nat8], b2: [Nat8]) : Bool {

        if (b1.size() != b2.size()) {
            return false;
        };
        for (i in Iter.range(0, b1.size() - 1)) {
            if(b1[i] != b2[i]){
                return false;
            };
        };
        true;
    };


    public func toHexString(array : [Nat8]) : Text {
        Array.foldLeft<Nat8, Text>(array, "", func (accum, w8) {
            var pre = "";
            if(accum != ""){
                pre #= ", ";
            };
            accum # pre # encodeW8(w8);
        });
    };
    private let base : Nat8 = 0x10; 

    private let symbols = [
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
    ];
    /**
    * Encode an unsigned 8-bit integer in hexadecimal format.
    */
    private func encodeW8(w8 : Nat8) : Text {
        let c1 = symbols[Nat8.toNat(w8 / base)];
        let c2 = symbols[Nat8.toNat(w8 % base)];
        "0x" # Char.toText(c1) # Char.toText(c2);
    };
};