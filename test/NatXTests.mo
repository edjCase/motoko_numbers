import Array "mo:base/Array";
import List "mo:base/List";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import NatX "../src/NatX";
import TestUtil "./TestUtil";


module {

    public func run(){
        testNat8([0x00], 0);
        testNat8([0x01], 1);
        testNat8([0xff], 255);


        testNat16([0x00, 0x00], 0);
        testNat16([0x00, 0x01], 1);
        testNat16([0x01, 0x00], 0);
        testNat16([0x00, 0xff], 255);
        testNat16([0xff, 0xff], 0);
    };

    private func testNat8(bytes: [Nat8], expected: Nat8) {
        testNatX(NatX.decodeNat8, encodeNat8, Nat8.equal, Nat8.toText, bytes, expected);
    };
    private func testNat16(bytes: [Nat8], expected: Nat16) {
        testNatX(NatX.decodeNat16, NatX.encodeNat16, Nat16.equal, Nat16.toText, bytes, expected);
    };
    private func testNat32(bytes: [Nat8], expected: Nat32) {
        testNatX(NatX.decodeNat32, NatX.encodeNat32, Nat32.equal, Nat32.toText, bytes, expected);
    };
    private func testNat64(bytes: [Nat8], expected: Nat64) {
        testNatX(NatX.decodeNat64, NatX.encodeNat64, Nat64.equal, Nat64.toText, bytes, expected);
    };
    private func testNat(bytes: [Nat8], expected: Nat) {
        let actual: ?Nat = NatX.decodeNat(Iter.fromArray(bytes), #leb128);
        switch (actual) {
            case (null) Debug.trap("Unable to parse nat from bytes: " # TestUtil.toHexString(bytes));
            case (?a) {
                if(a == expected) {
                    Debug.trap("Expected: " # Nat.toText(expected) # "\nActual: " # Nat.toText(a) # "\nBytes: " # TestUtil.toHexString(bytes));
                };
                let buffer = Buffer.Buffer<Nat8>(bytes.size());
                let _ = NatX.encodeNat(buffer, expected, #leb128);
                let expectedBytes: [Nat8] = buffer.toArray();
                if (not TestUtil.bytesAreEqual(bytes, expectedBytes)){
                    Debug.trap("Expected Bytes: " # TestUtil.toHexString(expectedBytes) # "\nActual Bytes: " # TestUtil.toHexString(bytes));
                };
            };
        }
    };

    private func encodeNat8(buffer: Buffer.Buffer<Nat8>, value: Nat8, encoding: {#lsb; #msb}) {
        NatX.encodeNat8(buffer, value);
    };

    private func testNatX<T>(
        decode: (Iter.Iter<Nat8>, {#lsb; #msb}) -> ?T,
        encode: (Buffer.Buffer<Nat8>, T, {#lsb; #msb}) -> (),
        equal: (T, T) -> Bool,
        toText: (T) -> Text,
        bytes: [Nat8],
        expected: T
    ) {
        testNatXInternal<T>(decode, encode, equal, toText, bytes, expected, #msb);
        let reverseBytes = List.toArray(List.reverse(List.fromArray(bytes)));
        testNatXInternal<T>(decode, encode, equal, toText, reverseBytes, expected, #lsb);

    };

    private func testNatXInternal<T>(
        decode: (Iter.Iter<Nat8>, {#lsb; #msb}) -> ?T,
        encode: (Buffer.Buffer<Nat8>, T, {#lsb; #msb}) -> (),
        equal: (T, T) -> Bool,
        toText: (T) -> Text,
        bytes: [Nat8],
        expected: T,
        encoding: {#lsb; #msb}
    ) {
        let actual: ?T = decode(Iter.fromArray(bytes), encoding);
        switch (actual) {
            case (null) Debug.trap("Unable to parse nat from bytes: " # TestUtil.toHexString(bytes));
            case (?a) {
                if(not equal(a, expected)) {
                    Debug.trap("Expected: " # toText(expected) # "\nActual: " # toText(a) # "\nBytes: " # TestUtil.toHexString(bytes));
                };
                let buffer = Buffer.Buffer<Nat8>(bytes.size());
                encode(buffer, expected, encoding);
                let expectedBytes: [Nat8] = buffer.toArray();
                if (not TestUtil.bytesAreEqual(bytes, expectedBytes)){
                    Debug.trap("Expected Bytes: " # TestUtil.toHexString(expectedBytes) # "\nActual Bytes: " # TestUtil.toHexString(bytes));
                };
            };
        }

    };
}