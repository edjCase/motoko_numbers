import Array "mo:base/Array";
import List "mo:base/List";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Int "mo:base/Int";
import IntX "../src/IntX";
import TestUtil "./TestUtil";


module {

    public func run(){
        testInt8([0x00], 0);
        testInt8([0x01], 1);
        testInt8([0xff], 255);


        testInt16([0x00, 0x00], 0);
        testInt16([0x00, 0x01], 1);
        testInt16([0x00, 0xff], 255);
        testInt16([0x01, 0x00], 256);
        testInt16([0xff, 0xff], 65535);


        testInt32([0x00, 0x00, 0x00, 0x00], 0);
        testInt32([0x00, 0x00, 0x00, 0x01], 1);
        testInt32([0x00, 0x00, 0x00, 0xff], 255);
        testInt32([0x00, 0x00, 0x01, 0x00], 256);
        testInt32([0x00, 0x00, 0xff, 0xff], 65535);
        testInt32([0xff, 0xff, 0xff, 0xff], 4294967295);


        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 0);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01], 1);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff], 255);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00], 256);
        testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff], 65535);
        testInt64([0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff], 4294967295);
        testInt64([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], 18446744073709551615);

        testInt([0xc0, 0xbb, 0x78], -123456, #signedLEB128);
        testInt([0xbc, 0x7f], -68, #signedLEB128);
        testInt([0x71], -15, #signedLEB128);
        testInt([0x7c], -4, #signedLEB128);
        testInt([0x00], 0, #signedLEB128);
        testInt([0x10], 16, #signedLEB128);
        testInt([0x80, 0x01], 128, #signedLEB128);
        testInt([0xe5, 0x8e, 0x26], 624485, #signedLEB128);



        [InlineData(0, "00")]
        [InlineData(16, "10")]
        [InlineData(-4, "7C")]
        [InlineData(-15, "71")]
        [InlineData(-68, "BC7F")]
        [InlineData(624485, "E58E26")]
        [InlineData(-123456, "C0BB78")]
        [InlineData(128, "8001")]
         
    };

    private func testInt8(bytes: [Int8], expected: Int8) {
        testIntX(IntX.decodeInt8, encodeInt8, Int8.equal, Int8.toText, bytes, expected);
    };
    private func testInt16(bytes: [Int8], expected: Int16) {
        testIntX(IntX.decodeInt16, IntX.encodeInt16, Int16.equal, Int16.toText, bytes, expected);
    };
    private func testInt32(bytes: [Int8], expected: Int32) {
        testIntX(IntX.decodeInt32, IntX.encodeInt32, Int32.equal, Int32.toText, bytes, expected);
    };
    private func testInt64(bytes: [Int8], expected: Int64) {
        testIntX(IntX.decodeInt64, IntX.encodeInt64, Int64.equal, Int64.toText, bytes, expected);
    };

    private func testInt(bytes: [Int8], expected: Int, encoding: {#signedLEB128}) {
        let actual: ?Int = IntX.decodeInt(Iter.fromArray(bytes), encoding);
        switch (actual) {
            case (null) Debug.trap("Unable to parse nat from bytes: " # TestUtil.toHexString(bytes));
            case (?a) {
                if(a == expected) {
                    Debug.trap("Expected: " # Int.toText(expected) # "\nActual: " # Int.toText(a) # "\nBytes: " # TestUtil.toHexString(bytes));
                };
                let buffer = Buffer.Buffer<Int8>(bytes.size());
                let _ = IntX.encodeInt(buffer, expected, encoding);
                let expectedBytes: [Int8] = buffer.toArray();
                if (not TestUtil.bytesAreEqual(bytes, expectedBytes)){
                    Debug.trap("Expected Bytes: " # TestUtil.toHexString(expectedBytes) # "\nActual Bytes: " # TestUtil.toHexString(bytes));
                };
            };
        }
    };

    private func encodeInt8(buffer: Buffer.Buffer<Int8>, value: Int8, encoding: {#lsb; #msb}) {
        IntX.encodeInt8(buffer, value);
    };

    private func testIntX<T>(
        decode: (Iter.Iter<Int8>, {#lsb; #msb}) -> ?T,
        encode: (Buffer.Buffer<Int8>, T, {#lsb; #msb}) -> (),
        equal: (T, T) -> Bool,
        toText: (T) -> Text,
        bytes: [Int8],
        expected: T
    ) {
        testIntXInternal<T>(decode, encode, equal, toText, bytes, expected, #msb);
        let reverseBytes = List.toArray(List.reverse(List.fromArray(bytes)));
        testIntXInternal<T>(decode, encode, equal, toText, reverseBytes, expected, #lsb);

    };

    private func testIntXInternal<T>(
        decode: (Iter.Iter<Int8>, {#lsb; #msb}) -> ?T,
        encode: (Buffer.Buffer<Int8>, T, {#lsb; #msb}) -> (),
        equal: (T, T) -> Bool,
        toText: (T) -> Text,
        bytes: [Int8],
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
                let buffer = Buffer.Buffer<Int8>(bytes.size());
                encode(buffer, expected, encoding);
                let expectedBytes: [Int8] = buffer.toArray();
                if (not TestUtil.bytesAreEqual(bytes, expectedBytes)){
                    Debug.trap("Expected Bytes: " # TestUtil.toHexString(expectedBytes) # "\nActual Bytes: " # TestUtil.toHexString(bytes));
                };
            };
        }

    };
}