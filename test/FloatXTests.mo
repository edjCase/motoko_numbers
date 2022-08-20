import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import FloatX "../src/FloatX";
import Nat8 "mo:base/Nat8";


module {

    public func run(){
        testFloat([0x00, 0x00], 0);
        testFloat([0x00, 0x01], 0.000000059604645);
        testFloat([0x03, 0xff], 0.000060975552);
        // TODO no negative powers????
        testFloat([0x04, 0x00], 0.00006103515625);
        testFloat([0x35, 0x55], 0.33325195);
        testFloat([0x3b, 0xff], 0.99951172);
        testFloat([0x3c, 0x00], 1);
        testFloat([0x3c, 0x01], 1.00097656);
        testFloat([0x7b, 0xff], 65504.0);
        // TODO
        // testFloat([0x7c, 0x00], INFINITY);
        // testFloat([0x80, 0x00], -0);
        testFloat([0xc0, 0x00], -2);
        // testFloat([0xfc, 0x00], -INFINITY);
        testFloat([0x41, 0xb8, 0x00, 0x00], 23.0);
        testFloat([0x40, 0x37, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 23.0);
    };

    func testFloat(bytes: [Nat8], expected: Float) {
        let precision = switch(bytes.size()) {
            case (2) #f16;
            case (4) #f32;
            case (8) #f64;
            case (a) Debug.trap("Invalid byte size: " # debug_show(bytes.size()));
        };
        let actualFX = FloatX.decodeFloatX(bytes, precision, #msb);
        let expectedFX = FloatX.floatToFloatX(expected, precision);
        switch(actualFX){
            case (null) Debug.trap("Invalid bytes for float: " # debug_show(bytes));
            case (?v){
                if(v != expectedFX) {
                    Debug.trap("Invalid value.\nExpected: " # debug_show(expectedFX) # "\nActual:   " # debug_show(v) # "\nExpected Value: " # Float.format(#exact, expected) # "\nBytes: " # toHexString(bytes));
                };
                let actualFloat: Float = FloatX.floatXToFloat(v);
                // TODO shouldnt they be exact?
                if(Float.abs(actualFloat - expected) > 0.00000001) {
                    Debug.trap("Invalid value.\nExpected: " # Float.format(#exact, expected) # "\nActual:   " # Float.format(#exact, actualFloat) # "\nBytes: " # toHexString(bytes));
                }
            }
        }
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

}