import Float "mo:core@1/Float";
import FloatX "../src/FloatX";
import Nat8 "mo:core@1/Nat8";
import Util "../src/Util";
import { test } "mo:test";
import Runtime "mo:core@1/Runtime";

func testFloat(bytes : [Nat8], expected : Float) {
  let precision = switch (bytes.size()) {
    case (2) #f16;
    case (4) #f32;
    case (8) #f64;
    case (_) Runtime.trap("Invalid byte size: " # debug_show (bytes.size()));
  };
  let actualFX = FloatX.fromBytes(bytes.vals(), precision, #msb);
  let expectedFX = FloatX.fromFloat(expected, precision);
  switch (actualFX) {
    case (null) Runtime.trap("Invalid bytes for float: " # debug_show (bytes));
    case (?v) {
      if (v != expectedFX) {
        Runtime.trap("Invalid value.\nExpected: " # debug_show (expectedFX) # "\nActual:   " # debug_show (v) # "\nExpected Value: " # Float.format(#exact, expected) # "\nBytes: " # Util.toHexString(bytes));
      };
      let actualFloat : Float = FloatX.toFloat(v);
      // TODO shouldnt they be exact?
      if (Float.abs(actualFloat - expected) > 0.00000001) {
        Runtime.trap("Invalid value.\nExpected: " # Float.format(#exact, expected) # "\nActual:   " # Float.format(#exact, actualFloat) # "\nBytes: " # Util.toHexString(bytes));
      };
    };
  };
};

test(
  "float",
  func() {
    testFloat([0x00, 0x00], 0);
    testFloat([0x00, 0x01], 0.000000059604645);
    testFloat([0x03, 0xff], 0.000060975552);
    // TODO no negative powers????
    testFloat([0x04, 0x00], 0.00006103515625);
    testFloat([0x35, 0x55], 0.33325195);
    testFloat([0x3b, 0xff], 0.99951172);
    testFloat([0x3c, 0x00], 1.0);
    testFloat([0x3c, 0x01], 1.00097656);
    testFloat([0x7b, 0xff], 65504.0);
    testFloat([0x7c, 0x00], 1.0 / 0.0); // Infinity
    testFloat([0x80, 0x00], -0.0);
    testFloat([0xc0, 0x00], -2.0);
    testFloat([0xfc, 0x00], -1.0 / 0.0); // -Infinity
    // TODO Float API doesn't allow getting the mantissa of NaN, so we use 1 as a placeholder
    testFloat([0x7C, 0x01], 0.0 / 0.0); // NaN with mantissa = 1
    testFloat([0x41, 0xb8, 0x00, 0x00], 23.0);
    testFloat([0x40, 0x37, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], 23.0);
  },
);

test(
  "isNaN",
  func() {
    assert FloatX.isNaN(FloatX.fromFloat(0.0 / 0.0, #f16));
    assert FloatX.isNaN(FloatX.fromFloat(0.0 / 0.0, #f32));
    assert FloatX.isNaN(FloatX.fromFloat(0.0 / 0.0, #f64));
    assert not FloatX.isNaN(FloatX.fromFloat(1.0, #f16));
    assert not FloatX.isNaN(FloatX.fromFloat(1.0, #f32));
    assert not FloatX.isNaN(FloatX.fromFloat(1.0, #f64));
    assert not FloatX.isNaN(FloatX.fromFloat(1.0 / 0.0, #f16)); // Infinity
    assert not FloatX.isNaN(FloatX.fromFloat(1.0 / 0.0, #f32)); // Infinity
    assert not FloatX.isNaN(FloatX.fromFloat(1.0 / 0.0, #f64)); // Infinity
    assert not FloatX.isNaN(FloatX.fromFloat(-1.0 / 0.0, #f16)); // -Infinity
    assert not FloatX.isNaN(FloatX.fromFloat(-1.0 / 0.0, #f32)); // -Infinity
    assert not FloatX.isNaN(FloatX.fromFloat(-1.0 / 0.0, #f64)); // -Infinity
  },
);

test(
  "isPosInf",
  func() {
    assert FloatX.isPosInf(FloatX.fromFloat(1.0 / 0.0, #f16));
    assert FloatX.isPosInf(FloatX.fromFloat(1.0 / 0.0, #f32));
    assert FloatX.isPosInf(FloatX.fromFloat(1.0 / 0.0, #f64));
    assert not FloatX.isPosInf(FloatX.fromFloat(0.0 / 0.0, #f16)); // NaN
    assert not FloatX.isPosInf(FloatX.fromFloat(0.0 / 0.0, #f32)); // NaN
    assert not FloatX.isPosInf(FloatX.fromFloat(0.0 / 0.0, #f64)); // NaN
    assert not FloatX.isPosInf(FloatX.fromFloat(1.0, #f16));
    assert not FloatX.isPosInf(FloatX.fromFloat(1.0, #f32));
    assert not FloatX.isPosInf(FloatX.fromFloat(1.0, #f64));
    assert not FloatX.isPosInf(FloatX.fromFloat(-1.0 / 0.0, #f16)); // -Infinity
    assert not FloatX.isPosInf(FloatX.fromFloat(-1.0 / 0.0, #f32)); // -Infinity
    assert not FloatX.isPosInf(FloatX.fromFloat(-1.0 / 0.0, #f64)); // -Infinity
  },
);

test(
  "isNegInf",
  func() {
    assert FloatX.isNegInf(FloatX.fromFloat(-1.0 / 0.0, #f16));
    assert FloatX.isNegInf(FloatX.fromFloat(-1.0 / 0.0, #f32));
    assert FloatX.isNegInf(FloatX.fromFloat(-1.0 / 0.0, #f64));
    assert not FloatX.isNegInf(FloatX.fromFloat(0.0 / 0.0, #f16)); // NaN
    assert not FloatX.isNegInf(FloatX.fromFloat(0.0 / 0.0, #f32)); // NaN
    assert not FloatX.isNegInf(FloatX.fromFloat(0.0 / 0.0, #f64)); // NaN
    assert not FloatX.isNegInf(FloatX.fromFloat(1.0 / 0.0, #f16)); // Infinity
    assert not FloatX.isNegInf(FloatX.fromFloat(1.0 / 0.0, #f32)); // Infinity
    assert not FloatX.isNegInf(FloatX.fromFloat(1.0 / 0.0, #f64)); // Infinity
    assert not FloatX.isNegInf(FloatX.fromFloat(1.0, #f16));
    assert not FloatX.isNegInf(FloatX.fromFloat(1.0, #f32));
    assert not FloatX.isNegInf(FloatX.fromFloat(1.0, #f64));
  },
);
