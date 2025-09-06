import List "mo:core@1/List";
import Buffer "mo:buffer@0";
import Iter "mo:core@1/Iter";
import Int8 "mo:core@1/Int8";
import Int16 "mo:core@1/Int16";
import Int32 "mo:core@1/Int32";
import Int64 "mo:core@1/Int64";
import Int "mo:core@1/Int";
import IntX "../src/IntX";
import TestUtil "./TestUtil";
import Util "../src/Util";
import { test } "mo:test";
import Runtime "mo:core@1/Runtime";

func testToText(value : Int, expected : { binary : Text; decimal : Text; hexadecimal : Text }) {
  testToTextInternal(value, expected.binary, #binary);
  testToTextInternal(value, expected.decimal, #decimal);
  testToTextInternal(value, expected.hexadecimal, #hexadecimal);
};

func testToTextInternal(value : Int, expected : Text, base : IntX.Format) {
  let actual = IntX.toTextAdvanced(value, base);
  if (actual != expected) {
    Runtime.trap("Failed converting Int to Text.\n\nExpected:\n" # expected # "\n\nActual:\n" # actual);
  };
  let n = switch (IntX.fromTextAdvanced(actual, base, null)) {
    case (null) Runtime.trap("Failed to convert " # debug_show (value) # " to text.");
    case (?n) n;
  };
  if (n != value) {
    Runtime.trap("Failed converting Text to Int.\n\nExpected:\n" # debug_show (value) # "\n\nActual:\n" # debug_show (n));
  };
};

func testInt8(bytes : [Nat8], expected : Int8) {
  testIntX(IntX.fromInt8Bytes, toInt8BytesBuffer, Int8.equal, Int8.toText, bytes, expected);
};
func testInt16(bytes : [Nat8], expected : Int16) {
  testIntX(IntX.fromInt16Bytes, IntX.toInt16BytesBuffer, Int16.equal, Int16.toText, bytes, expected);
};
func testInt32(bytes : [Nat8], expected : Int32) {
  testIntX(IntX.fromInt32Bytes, IntX.toInt32BytesBuffer, Int32.equal, Int32.toText, bytes, expected);
};
func testInt64(bytes : [Nat8], expected : Int64) {
  testIntX(IntX.fromInt64Bytes, IntX.toInt64BytesBuffer, Int64.equal, Int64.toText, bytes, expected);
};

func testInt(bytes : [Nat8], expected : Int, encoding : { #signedLEB128; #lsb; #msb }) {
  let actual : ?Int = IntX.fromIntBytes(Iter.fromArray(bytes), encoding);
  switch (actual) {
    case (null) Runtime.trap("Unable to parse Int from bytes: " # Util.toHexString(bytes));
    case (?a) {
      if (a != expected) {
        Runtime.trap("\nExpected: " # Int.toText(expected) # "\nActual:   " # Int.toText(a) # "\nBytes: " # Util.toHexString(bytes));
      };
      let buffer = List.empty<Nat8>();
      IntX.toIntBytesBuffer(Buffer.fromList(buffer), expected, encoding);
      let actualBytes : [Nat8] = List.toArray(buffer);
      if (not TestUtil.bytesAreEqual(bytes, actualBytes)) {
        Runtime.trap("\nInt Value: " # Int.toText(expected) # "\nEncoding: " #debug_show (encoding) # "\nExpected Bytes: " # Util.toHexString(bytes) # "\nActual Bytes: " # Util.toHexString(actualBytes));
      };
    };
  };
};

func toInt8BytesBuffer(buffer : Buffer.Buffer<Nat8>, value : Int8, _ : { #lsb; #msb }) {
  IntX.toInt8BytesBuffer(buffer, value);
};

func testIntX<T>(
  decode : (Iter.Iter<Nat8>, { #lsb; #msb }) -> ?T,
  encode : (Buffer.Buffer<Nat8>, T, { #lsb; #msb }) -> (),
  equal : (T, T) -> Bool,
  toText : (T) -> Text,
  bytes : [Nat8],
  expected : T,
) {
  testIntXInternal<T>(decode, encode, equal, toText, bytes, expected, #msb);
  let reverseBytes = List.toArray(List.reverse(List.fromArray<Nat8>(bytes)));
  testIntXInternal<T>(decode, encode, equal, toText, reverseBytes, expected, #lsb);

};

func testIntXInternal<T>(
  decode : (Iter.Iter<Nat8>, { #lsb; #msb }) -> ?T,
  encode : (Buffer.Buffer<Nat8>, T, { #lsb; #msb }) -> (),
  equal : (T, T) -> Bool,
  toText : (T) -> Text,
  bytes : [Nat8],
  expected : T,
  encoding : { #lsb; #msb },
) {
  let actual : ?T = decode(Iter.fromArray(bytes), encoding);
  switch (actual) {
    case (null) Runtime.trap("Unable to parse Int from bytes: " # Util.toHexString(bytes));
    case (?a) {
      if (not equal(a, expected)) {
        Runtime.trap("Expected: " # toText(expected) # "\nActual:   " # toText(a) # "\nBytes: " # Util.toHexString(bytes));
      };
      let buffer = List.empty<Nat8>();
      encode(Buffer.fromList(buffer), expected, encoding);
      let expectedBytes : [Nat8] = List.toArray(buffer);
      if (not TestUtil.bytesAreEqual(bytes, expectedBytes)) {
        Runtime.trap("Expected Bytes: " # Util.toHexString(expectedBytes) # "\nActual Bytes: " # Util.toHexString(bytes));
      };
    };
  };

};

test(
  "Int8",
  func() {
    testInt8([0x00], 0);
    testInt8([0x01], 1);
    testInt8([0x7f], 127);
    testInt8([0xff], -1);
    testInt8([0x80], -128);
  },
);

test(
  "Int16",
  func() {
    testInt16([0x00, 0x00], 0);
    testInt16([0x00, 0x01], 1);
    testInt16([0x00, 0xff], 255);
    testInt16([0x01, 0x00], 256);
    testInt16([0x7f, 0xff], 32767);
    testInt16([0xff, 0xff], -1);
    testInt16([0x80, 0x00], -32768);
  },
);

test(
  "Int32",
  func() {
    testInt32([0x00, 0x00, 0x00, 0x00], 0);
    testInt32([0x00, 0x00, 0x00, 0x01], 1);
    testInt32([0x00, 0x00, 0x00, 0xff], 255);
    testInt32([0x00, 0x00, 0x01, 0x00], 256);
    testInt32([0x00, 0x00, 0xff, 0xff], 65535);
    testInt32([0x7f, 0xff, 0xff, 0xff], 2147483647);
    testInt32([0x80, 0x00, 0x00, 0x00], -2147483648);
    testInt32([0xff, 0xff, 0xff, 0xff], -1);
  },
);

test(
  "Int64",
  func() {
    testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 0);
    testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01], 1);
    testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff], 255);
    testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00], 256);
    testInt64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff], 65535);
    testInt64([0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff], 4294967295);
    testInt64([0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], 9223372036854775807);
    testInt64([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], -9223372036854775808);
    testInt64([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], -1);
  },
);

test(
  "Int",
  func() {
    // LEB128
    testInt([0xc0, 0xbb, 0x78], -123456, #signedLEB128);
    testInt([0xbc, 0x7f], -68, #signedLEB128);
    testInt([0x71], -15, #signedLEB128);
    testInt([0x7c], -4, #signedLEB128);
    testInt([0x00], 0, #signedLEB128);
    testInt([0x10], 16, #signedLEB128);
    testInt([0x80, 0x01], 128, #signedLEB128);
    testInt([0xe5, 0x8e, 0x26], 624485, #signedLEB128);

    // MSB
    testInt([0x00], 0, #msb);
    testInt([0x10], 16, #msb);
    testInt([0x7F], 127, #msb);
    testInt([0x00, 0x80], 128, #msb);
    testInt([0x00, 0xFF], 255, #msb);
    testInt([0x01, 0x00], 256, #msb);
    testInt([0xFF], -1, #msb);
    testInt([0xFC], -4, #msb);
    testInt([0xF1], -15, #msb);
    testInt([0xBC], -68, #msb);
    testInt([0x80], -128, #msb);
    testInt([0xFF, 0x7F], -129, #msb);
    testInt([0x09, 0x87, 0x65], 624485, #msb);
    testInt([0xFE, 0x1D, 0xC0], -123456, #msb);
    testInt([0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], 9223372036854775807, #msb); // Int64.max
    testInt([0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 9223372036854775808, #msb); // Int64.max + 1
    testInt([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], -9223372036854775808, #msb); // Int64.min
    testInt([0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], -9223372036854775809, #msb); // Int64.min - 1

    // LSB
    testInt([0x00], 0, #lsb);
    testInt([0x10], 16, #lsb);
    testInt([0x7F], 127, #lsb);
    testInt([0x80, 0x00], 128, #lsb);
    testInt([0xFF, 0x00], 255, #lsb);
    testInt([0x00, 0x01], 256, #lsb);
    testInt([0xFF], -1, #lsb);
    testInt([0xFC], -4, #lsb);
    testInt([0xF1], -15, #lsb);
    testInt([0xBC], -68, #lsb);
    testInt([0x80], -128, #lsb);
    testInt([0x7F, 0xFF], -129, #lsb);
    testInt([0x65, 0x87, 0x09], 624485, #lsb);
    testInt([0xC0, 0x1D, 0xFE], -123456, #lsb);
    testInt([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F], 9223372036854775807, #lsb); // Int64.max
    testInt([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00], 9223372036854775808, #lsb); // Int64.max + 1
    testInt([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80], -9223372036854775808, #lsb); // Int64.min
    testInt([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF], -9223372036854775809, #lsb); // Int64.min - 1

    testToText(
      0,
      {
        binary = "0";
        decimal = "0";
        hexadecimal = "0";
      },
    );

    testToText(
      1,
      {
        binary = "1";
        decimal = "1";
        hexadecimal = "1";
      },
    );
    testToText(
      -1,
      {
        binary = "-1";
        decimal = "-1";
        hexadecimal = "-1";
      },
    );
    testToText(
      9,
      {
        binary = "1001";
        decimal = "9";
        hexadecimal = "9";
      },
    );
    testToText(
      10,
      {
        binary = "1010";
        decimal = "10";
        hexadecimal = "A";
      },
    );
    testToText(
      100,
      {
        binary = "1100100";
        decimal = "100";
        hexadecimal = "64";
      },
    );
    testToText(
      1234567890,
      {
        binary = "1001001100101100000001011010010";
        decimal = "1234567890";
        hexadecimal = "499602D2";
      },
    );
    testToText(
      -1234567890,
      {
        binary = "-1001001100101100000001011010010";
        decimal = "-1234567890";
        hexadecimal = "-499602D2";
      },
    );
    testToText(
      123456789099999999999999999999999999999999999999999999999999999999999999,
      {
        binary = "100011110001101000100010011011111100001111111100000101010001010010001100000101010110000101011001100000101110110110110000100000101101111010011010101110010100110110111001100101011111111111111111111111111111111111111111111111111111111111111";
        decimal = "123456789099999999999999999999999999999999999999999999999999999999999999";
        hexadecimal = "11E3444DF87F82A29182AC2B305DB6105BD35729B732BFFFFFFFFFFFFFFF";
      },
    );
  },
);
