import List "mo:core/List";
import Buffer "mo:buffer";
import Iter "mo:core/Iter";
import Nat8 "mo:core/Nat8";
import Nat16 "mo:core/Nat16";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Nat "mo:core/Nat";
import NatX "../src/NatX";
import TestUtil "./TestUtil";
import Util "../src/Util";
import { test } "mo:test";
import Runtime "mo:core/Runtime";

func testToText(value : Nat, expected : { binary : Text; decimal : Text; hexadecimal : Text }) {
  testToTextInternal(value, expected.binary, #binary);
  testToTextInternal(value, expected.decimal, #decimal);
  testToTextInternal(value, expected.hexadecimal, #hexadecimal);
};

func testToTextInternal(value : Nat, expected : Text, base : NatX.Format) {
  let actual = NatX.toTextAdvanced(value, base);
  if (actual != expected) {
    Runtime.trap("Failed converting Nat to Text.\n\nExpected:\n" # expected # "\n\nActual:\n" # actual);
  };
  let n = switch (NatX.fromTextAdvanced(actual, base, null)) {
    case (null) Runtime.trap("Failed to convert " # debug_show (value) # " to text.");
    case (?n) n;
  };
  if (n != value) {
    Runtime.trap("Failed converting Text to Nat.\n\nExpected:\n" # debug_show (value) # "\n\nActual:\n" # debug_show (n));
  };
};

func testNat8(bytes : [Nat8], expected : Nat8) {
  testNatX(NatX.decodeNat8, encodeNat8, Nat8.equal, Nat8.toText, bytes, expected);
};
func testNat16(bytes : [Nat8], expected : Nat16) {
  testNatX(NatX.decodeNat16, NatX.encodeNat16, Nat16.equal, Nat16.toText, bytes, expected);
};
func testNat32(bytes : [Nat8], expected : Nat32) {
  testNatX(NatX.decodeNat32, NatX.encodeNat32, Nat32.equal, Nat32.toText, bytes, expected);
};
func testNat64(bytes : [Nat8], expected : Nat64) {
  testNatX(NatX.decodeNat64, NatX.encodeNat64, Nat64.equal, Nat64.toText, bytes, expected);
};

func testNat(bytes : [Nat8], expected : Nat, encoding : { #unsignedLEB128; #lsb; #msb }) {
  let actual : ?Nat = NatX.decodeNat(Iter.fromArray(bytes), encoding);
  switch (actual) {
    case (null) Runtime.trap("Unable to parse nat from bytes: " # Util.toHexString(bytes));
    case (?a) {
      if (a != expected) {
        Runtime.trap("Expected: " # Nat.toText(expected) # "\nActual: " # Nat.toText(a) # "\nBytes: " # Util.toHexString(bytes));
      };
      let buffer = List.empty<Nat8>();
      NatX.encodeNat(Buffer.fromList(buffer), expected, encoding);
      let expectedBytes : [Nat8] = List.toArray(buffer);
      if (not TestUtil.bytesAreEqual(bytes, expectedBytes)) {
        Runtime.trap("Expected Bytes: " # Util.toHexString(expectedBytes) # "\nActual Bytes: " # Util.toHexString(bytes));
      };
    };
  };
};

func encodeNat8(buffer : Buffer.Buffer<Nat8>, value : Nat8, _ : { #lsb; #msb }) {
  NatX.encodeNat8(buffer, value);
};

func testNatX<T>(
  decode : (Iter.Iter<Nat8>, { #lsb; #msb }) -> ?T,
  encode : (Buffer.Buffer<Nat8>, T, { #lsb; #msb }) -> (),
  equal : (T, T) -> Bool,
  toText : (T) -> Text,
  bytes : [Nat8],
  expected : T,
) {
  testNatXInternal<T>(decode, encode, equal, toText, bytes, expected, #msb);
  let reverseBytes = List.toArray(List.reverse(List.fromArray<Nat8>(bytes)));
  testNatXInternal<T>(decode, encode, equal, toText, reverseBytes, expected, #lsb);

};

func testNatXInternal<T>(
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
    case (null) Runtime.trap("Unable to parse nat from bytes: " # Util.toHexString(bytes));
    case (?a) {
      if (not equal(a, expected)) {
        Runtime.trap("Expected: " # toText(expected) # "\nActual: " # toText(a) # "\nBytes: " # Util.toHexString(bytes));
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
  "Nat8",
  func() {
    testNat8([0x00], 0);
    testNat8([0x01], 1);
    testNat8([0xff], 255);
  },
);

test(
  "Nat16",
  func() {
    testNat16([0x00, 0x00], 0);
    testNat16([0x00, 0x01], 1);
    testNat16([0x00, 0xff], 255);
    testNat16([0x01, 0x00], 256);
    testNat16([0xff, 0xff], 65535);
  },
);
test(
  "Nat32",
  func() {
    testNat32([0x00, 0x00, 0x00, 0x00], 0);
    testNat32([0x00, 0x00, 0x00, 0x01], 1);
    testNat32([0x00, 0x00, 0x00, 0xff], 255);
    testNat32([0x00, 0x00, 0x01, 0x00], 256);
    testNat32([0x00, 0x00, 0xff, 0xff], 65535);
    testNat32([0xff, 0xff, 0xff, 0xff], 4294967295);
  },
);

test(
  "Nat64",
  func() {
    testNat64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 0);
    testNat64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01], 1);
    testNat64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff], 255);
    testNat64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00], 256);
    testNat64([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff], 65535);
    testNat64([0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff], 4294967295);
    testNat64([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], 18446744073709551615);
  },
);

test(
  "Nat",
  func() {
    testNat([0x00], 0, #unsignedLEB128);
    testNat([0x01], 1, #unsignedLEB128);
    testNat([0x7f], 127, #unsignedLEB128);
    testNat([0xe5, 0x8e, 0x26], 624485, #unsignedLEB128);

    testNat([0x00], 0, #msb);
    testNat([0x10], 16, #msb);
    testNat([0x7F], 127, #msb);
    testNat([0x80], 128, #msb);
    testNat([0xFF], 255, #msb);
    testNat([0x01, 0x00], 256, #msb);
    testNat([0x09, 0x87, 0x65], 624485, #msb);
    testNat([0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], 9223372036854775807, #msb);
    testNat([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 9223372036854775808, #msb);

    testNat([0x00], 0, #lsb);
    testNat([0x10], 16, #lsb);
    testNat([0x7F], 127, #lsb);
    testNat([0x80], 128, #lsb);
    testNat([0xFF], 255, #lsb);
    testNat([0x00, 0x01], 256, #lsb);
    testNat([0x65, 0x87, 0x09], 624485, #lsb);
    testNat([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F], 9223372036854775807, #lsb);
    testNat([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80], 9223372036854775808, #lsb);

    testNat(
      // Expected 32-byte little-endian encoding of y
      [0xE5, 0x56, 0x43, 0x00, 0xC3, 0x60, 0xAC, 0x72, 0x90, 0x86, 0xE2, 0xCC, 0x80, 0x6E, 0x82, 0x8A, 0x84, 0x87, 0x7F, 0x1E, 0xB8, 0xE5, 0xD9, 0x74, 0xD8, 0x73, 0xE0, 0x65, 0x22, 0x49, 0x01, 0x55],
      // The Nat value for y
      38448863731492799660668882834560725606410712239157980760146247592118262650597,
      // Endianness
      #lsb,
    );

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
      123456789099999999999999999999999999999999999999999999999999999999999999,
      {
        binary = "100011110001101000100010011011111100001111111100000101010001010010001100000101010110000101011001100000101110110110110000100000101101111010011010101110010100110110111001100101011111111111111111111111111111111111111111111111111111111111111";
        decimal = "123456789099999999999999999999999999999999999999999999999999999999999999";
        hexadecimal = "11E3444DF87F82A29182AC2B305DB6105BD35729B732BFFFFFFFFFFFFFFF";
      },
    );
  },
);
