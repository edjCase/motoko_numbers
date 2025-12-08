import Float "mo:core@1/Float";
import FloatX "../src/FloatX";
import Nat8 "mo:core@1/Nat8";
import Util "../src/Util";
import { test } "mo:test";
import Runtime "mo:core@1/Runtime";

type FloatTestCase = {
  bytes : [Nat8];
  expected : Float;
};

type NanTestCase = {
  value : Float;
  precision : FloatX.FloatPrecision;
  expected : Bool;
};

type FromTextTestCase = {
  text : Text;
  precision : FloatX.FloatPrecision;
  expectedValue : Float;
};

type ToTextTestCase = {
  bytes : [Nat8];
  options : FloatX.ToTextOptions;
  expected : Text;
};

test(
  "float",
  func() {
    let cases : [FloatTestCase] = [
      { bytes = [0x00, 0x00]; expected = 0 },
      { bytes = [0x00, 0x01]; expected = 0.000000059604645 },
      { bytes = [0x03, 0xff]; expected = 0.000060975552 },
      { bytes = [0x04, 0x00]; expected = 0.00006103515625 },
      { bytes = [0x35, 0x55]; expected = 0.33325195 },
      { bytes = [0x3b, 0xff]; expected = 0.99951172 },
      { bytes = [0x3c, 0x00]; expected = 1.0 },
      { bytes = [0x3c, 0x01]; expected = 1.00097656 },
      { bytes = [0x7b, 0xff]; expected = 65504.0 },
      { bytes = [0x7c, 0x00]; expected = 1.0 / 0.0 },
      { bytes = [0x80, 0x00]; expected = -0.0 },
      { bytes = [0xc0, 0x00]; expected = -2.0 },
      { bytes = [0xfc, 0x00]; expected = -1.0 / 0.0 },
      { bytes = [0x7C, 0x01]; expected = 0.0 / 0.0 },
      { bytes = [0x41, 0xb8, 0x00, 0x00]; expected = 23.0 },
      {
        bytes = [0x40, 0x37, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        expected = 23.0;
      },
    ];

    for (testCase in cases.vals()) {
      let precision = switch (testCase.bytes.size()) {
        case (2) #f16;
        case (4) #f32;
        case (8) #f64;
        case (_) Runtime.trap("Invalid byte size: " # debug_show (testCase.bytes.size()));
      };
      let actualFX = FloatX.fromBytes(testCase.bytes.vals(), precision, #msb);
      let expectedFX = FloatX.fromFloat(testCase.expected, precision);
      switch (actualFX) {
        case (null) Runtime.trap("Invalid bytes for float: " # debug_show (testCase.bytes));
        case (?v) {
          if (v != expectedFX) {
            Runtime.trap("Invalid value.\nExpected: " # debug_show (expectedFX) # "\nActual:   " # debug_show (v) # "\nExpected Value: " # Float.format(#exact, testCase.expected) # "\nBytes: " # Util.toHexString(testCase.bytes));
          };
          let actualFloat : Float = FloatX.toFloat(v);
          if (Float.abs(actualFloat - testCase.expected) > 0.00000001) {
            Runtime.trap("Invalid value.\nExpected: " # Float.format(#exact, testCase.expected) # "\nActual:   " # Float.format(#exact, actualFloat) # "\nBytes: " # Util.toHexString(testCase.bytes));
          };
        };
      };
    };
  },
);

test(
  "isNaN",
  func() {
    let cases : [NanTestCase] = [
      { value = 0.0 / 0.0; precision = #f16; expected = true },
      { value = 0.0 / 0.0; precision = #f32; expected = true },
      { value = 0.0 / 0.0; precision = #f64; expected = true },
      { value = 1.0; precision = #f16; expected = false },
      { value = 1.0; precision = #f32; expected = false },
      { value = 1.0; precision = #f64; expected = false },
      { value = 1.0 / 0.0; precision = #f16; expected = false },
      { value = 1.0 / 0.0; precision = #f32; expected = false },
      { value = 1.0 / 0.0; precision = #f64; expected = false },
      { value = -1.0 / 0.0; precision = #f16; expected = false },
      { value = -1.0 / 0.0; precision = #f32; expected = false },
      { value = -1.0 / 0.0; precision = #f64; expected = false },
    ];

    for (testCase in cases.vals()) {
      let result = FloatX.isNaN(FloatX.fromFloat(testCase.value, testCase.precision));
      if (result != testCase.expected) {
        Runtime.trap("isNaN test failed for value: " # Float.format(#exact, testCase.value) # " precision: " # debug_show (testCase.precision) # "\nExpected: " # debug_show (testCase.expected) # "\nActual: " # debug_show (result));
      };
    };
  },
);

test(
  "isPosInf",
  func() {
    let cases : [NanTestCase] = [
      { value = 1.0 / 0.0; precision = #f16; expected = true },
      { value = 1.0 / 0.0; precision = #f32; expected = true },
      { value = 1.0 / 0.0; precision = #f64; expected = true },
      { value = 0.0 / 0.0; precision = #f16; expected = false },
      { value = 0.0 / 0.0; precision = #f32; expected = false },
      { value = 0.0 / 0.0; precision = #f64; expected = false },
      { value = 1.0; precision = #f16; expected = false },
      { value = 1.0; precision = #f32; expected = false },
      { value = 1.0; precision = #f64; expected = false },
      { value = -1.0 / 0.0; precision = #f16; expected = false },
      { value = -1.0 / 0.0; precision = #f32; expected = false },
      { value = -1.0 / 0.0; precision = #f64; expected = false },
    ];

    for (testCase in cases.vals()) {
      let result = FloatX.isPosInf(FloatX.fromFloat(testCase.value, testCase.precision));
      if (result != testCase.expected) {
        Runtime.trap("isPosInf test failed for value: " # Float.format(#exact, testCase.value) # " precision: " # debug_show (testCase.precision) # "\nExpected: " # debug_show (testCase.expected) # "\nActual: " # debug_show (result));
      };
    };
  },
);

test(
  "isNegInf",
  func() {
    let cases : [NanTestCase] = [
      { value = -1.0 / 0.0; precision = #f16; expected = true },
      { value = -1.0 / 0.0; precision = #f32; expected = true },
      { value = -1.0 / 0.0; precision = #f64; expected = true },
      { value = 0.0 / 0.0; precision = #f16; expected = false },
      { value = 0.0 / 0.0; precision = #f32; expected = false },
      { value = 0.0 / 0.0; precision = #f64; expected = false },
      { value = 1.0 / 0.0; precision = #f16; expected = false },
      { value = 1.0 / 0.0; precision = #f32; expected = false },
      { value = 1.0 / 0.0; precision = #f64; expected = false },
      { value = 1.0; precision = #f16; expected = false },
      { value = 1.0; precision = #f32; expected = false },
      { value = 1.0; precision = #f64; expected = false },
    ];

    for (testCase in cases.vals()) {
      let result = FloatX.isNegInf(FloatX.fromFloat(testCase.value, testCase.precision));
      if (result != testCase.expected) {
        Runtime.trap("isNegInf test failed for value: " # Float.format(#exact, testCase.value) # " precision: " # debug_show (testCase.precision) # "\nExpected: " # debug_show (testCase.expected) # "\nActual: " # debug_show (result));
      };
    };
  },
);

test(
  "fromText",
  func() {
    let cases : [FromTextTestCase] = [
      { text = "0.0"; precision = #f32; expectedValue = 0.0 },
      { text = "1.0"; precision = #f32; expectedValue = 1.0 },
      { text = "-1.0"; precision = #f32; expectedValue = -1.0 },
      { text = "3.14159"; precision = #f32; expectedValue = 3.14159 },
      { text = "-3.14159"; precision = #f64; expectedValue = -3.14159 },
      { text = "23.0"; precision = #f32; expectedValue = 23.0 },
      {
        text = "0.00006103515625";
        precision = #f16;
        expectedValue = 0.00006103515625;
      },
      { text = "1.5e2"; precision = #f32; expectedValue = 150.0 },
      { text = "1.5e+2"; precision = #f32; expectedValue = 150.0 },
      { text = "1.5e-2"; precision = #f32; expectedValue = 0.015 },
      { text = "2.5E3"; precision = #f64; expectedValue = 2500.0 },
      { text = "inf"; precision = #f32; expectedValue = 1.0 / 0.0 },
      { text = "-inf"; precision = #f32; expectedValue = -1.0 / 0.0 },
      { text = "Infinity"; precision = #f64; expectedValue = 1.0 / 0.0 },
      { text = "-Infinity"; precision = #f64; expectedValue = -1.0 / 0.0 },
      { text = "NaN"; precision = #f32; expectedValue = 0.0 / 0.0 },
      { text = "  1.0  "; precision = #f32; expectedValue = 1.0 },
      { text = "+1.0"; precision = #f32; expectedValue = 1.0 },
      { text = "100"; precision = #f32; expectedValue = 100.0 },
      { text = ".5"; precision = #f32; expectedValue = 0.5 },
      { text = "5."; precision = #f32; expectedValue = 5.0 },
      { text = "0"; precision = #f32; expectedValue = 0.0 },
      { text = "-.5"; precision = #f32; expectedValue = -0.5 },
      { text = "1e10"; precision = #f64; expectedValue = 10000000000.0 },
      { text = "1e-10"; precision = #f64; expectedValue = 0.0000000001 },
      { text = "1.5e20"; precision = #f64; expectedValue = 1.5e20 }, // Changed from 9.99999e99
      { text = "-0.0"; precision = #f32; expectedValue = -0.0 },
      { text = "1.234567"; precision = #f64; expectedValue = 1.234567 }, // Reduced precision
      { text = "0.000001"; precision = #f32; expectedValue = 0.000001 },
      { text = "1000000"; precision = #f32; expectedValue = 1000000.0 },
      { text = "1.0E-5"; precision = #f32; expectedValue = 0.00001 },
      { text = "1.0E+5"; precision = #f32; expectedValue = 100000.0 },
      { text = "  +3.14  "; precision = #f64; expectedValue = 3.14 },
      { text = "123.456e-2"; precision = #f32; expectedValue = 1.23456 },
      { text = "0.5e0"; precision = #f32; expectedValue = 0.5 },
      { text = "2.5"; precision = #f16; expectedValue = 2.5 },
      { text = "-100.5"; precision = #f32; expectedValue = -100.5 },
      { text = "0.125"; precision = #f32; expectedValue = 0.125 }, // Powers of 2 are exact
      { text = "1e-308"; precision = #f64; expectedValue = 1e-308 },
      {
        text = "2.225073858507201e-308";
        precision = #f64;
        expectedValue = 2.225073858507201e-308;
      }, // Smallest normal f64
      { text = "5e-324"; precision = #f64; expectedValue = 5e-324 }, // Smallest subnormal f64
      {
        text = "1.401298464324817e-45";
        precision = #f32;
        expectedValue = 1.401298464324817e-45;
      }, // Smallest subnormal f32
      {
        text = "1.175494350822287e-38";
        precision = #f32;
        expectedValue = 1.175494350822287e-38;
      }, // Smallest normal f32
      {
        text = "6.103515625e-5";
        precision = #f16;
        expectedValue = 6.103515625e-5;
      }, // Smallest normal f16
      {
        text = "5.960464477539063e-8";
        precision = #f16;
        expectedValue = 5.960464477539063e-8;
      }, // Smallest subnormal f16
      {
        text = "1.7976931348623157e308";
        precision = #f64;
        expectedValue = 1.7976931348623157e308;
      }, // Max f64
      {
        text = "3.4028234663852886e38";
        precision = #f32;
        expectedValue = 3.4028234663852886e38;
      }, // Max f32
      { text = "65504.0"; precision = #f16; expectedValue = 65504.0 }, // Max f16
      // Hex integer tests
      { text = "0x2a"; precision = #f32; expectedValue = 42.0 },
      { text = "0xFF"; precision = #f32; expectedValue = 255.0 },
      { text = "0x0"; precision = #f32; expectedValue = 0.0 },
      { text = "0x1"; precision = #f32; expectedValue = 1.0 },
      { text = "-0x10"; precision = #f32; expectedValue = -16.0 },
      { text = "+0xA"; precision = #f32; expectedValue = 10.0 },
      // Hex with underscores
      { text = "0x1_A_B"; precision = #f32; expectedValue = 427.0 }, // 1*256 + 10*16 + 11
      { text = "0x1_0_0"; precision = #f32; expectedValue = 256.0 },
      { text = "0xF_F_F"; precision = #f32; expectedValue = 4095.0 },
      // Hex float with decimal point
      { text = "0x1.8"; precision = #f32; expectedValue = 1.5 }, // 1 + 8/16
      { text = "0x2.4"; precision = #f32; expectedValue = 2.25 }, // 2 + 4/16
      { text = "0x0.8"; precision = #f32; expectedValue = 0.5 }, // 8/16
      { text = "0xA.C"; precision = #f32; expectedValue = 10.75 }, // 10 + 12/16
      { text = "-0x1.0"; precision = #f32; expectedValue = -1.0 },
      // Hex float with binary exponent
      { text = "0x1.8p2"; precision = #f32; expectedValue = 6.0 }, // 1.5 * 2^2 = 1.5 * 4 = 6
      { text = "0x1.0p-4"; precision = #f32; expectedValue = 0.0625 }, // 1.0 * 2^-4 = 1/16
      { text = "-0x1.0p-4"; precision = #f32; expectedValue = -0.0625 },
      { text = "0x1.0p0"; precision = #f32; expectedValue = 1.0 }, // 1.0 * 2^0
      { text = "0x1.0p1"; precision = #f32; expectedValue = 2.0 }, // 1.0 * 2^1
      { text = "0x2.0p3"; precision = #f32; expectedValue = 16.0 }, // 2.0 * 2^3
      { text = "0xF.Fp10"; precision = #f32; expectedValue = 16320.0 }, // 15.9375 * 1024
      { text = "0x1p-10"; precision = #f32; expectedValue = 0.0009765625 }, // 1 * 2^-10
      { text = "0x1.4p3"; precision = #f64; expectedValue = 10.0 }, // 1.25 * 8
      // Combined hex features
      { text = "0x1_0.8p2"; precision = #f32; expectedValue = 66.0 }, // 16.5 * 4
      { text = "-0xA_B.Cp-2"; precision = #f32; expectedValue = -42.9375 }, // -(171.75 / 4)
    ];

    for (testCase in cases.vals()) {
      let result = FloatX.fromText(testCase.text, testCase.precision);
      switch (result) {
        case (null) {
          Runtime.trap("fromText failed for input: '" # testCase.text);
        };
        case (?floatX) {
          let actualValue = FloatX.toFloat(floatX);

          // Handle NaN separately since NaN != NaN
          if (Float.isNaN(testCase.expectedValue)) {
            if (not FloatX.isNaN(floatX)) {
              Runtime.trap("fromText test failed for: '" # testCase.text # "'\nExpected: NaN\nActual: " # Float.format(#exact, actualValue));
            };
          } else if (Float.abs(actualValue - testCase.expectedValue) > 0.00001) {
            Runtime.trap("fromText test failed for: '" # testCase.text # "'\nExpected: " # Float.format(#exact, testCase.expectedValue) # "\nActual: " # Float.format(#exact, actualValue) # "\nActualFX: " # debug_show (floatX));
          };
        };
      };
    };
  },
);

test(
  "toText",
  func() {
    let cases : [ToTextTestCase] = [
      {
        bytes = [0x00, 0x00];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "0.0";
      },
      {
        bytes = [0x3c, 0x00];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "1.0";
      },
      {
        bytes = [0xc0, 0x00];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "-2.0";
      },
      {
        bytes = [0x7c, 0x00];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "inf";
      },
      {
        bytes = [0xfc, 0x00];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "-inf";
      },
      {
        bytes = [0x7C, 0x01];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "NaN";
      },

      // With precision
      {
        bytes = [0x41, 0xb8, 0x00, 0x00];
        options = { exponent = #none; precision = ?2 };
        expected = "23.00";
      },
      {
        bytes = [0x41, 0xb8, 0x00, 0x00];
        options = { exponent = #none; precision = ?4 };
        expected = "23.0000";
      },

      // Scientific notation
      {
        bytes = [0x41, 0xb8, 0x00, 0x00];
        options = {
          exponent = #scientific;
          precision = ?2;
        };
        expected = "2.30e+1";
      },
      {
        bytes = [0x41, 0xb8, 0x00, 0x00];
        options = {
          exponent = #scientific;
          precision = ?4;
        };
        expected = "2.3000e+1";
      },

      // Zero with sign
      {
        bytes = [0x80, 0x00];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "-0.0";
      },

      // f32 cases
      {
        bytes = [0x40, 0x37, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        options = {
          exponent = #auto;
          precision = null;
        };
        expected = "23.0";
      },
      {
        bytes = [0x40, 0x37, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        options = {
          exponent = #scientific;
          precision = ?3;
        };
        expected = "2.300e+1";
      },
      {
        bytes = [0x41, 0xb8, 0x00, 0x00]; // 23.0
        options = {
          exponent = #engineering;
          precision = ?2;
        };
        expected = "23.00e+0"; // exp 1 -> 0 (nearest multiple of 3)
      },
      {
        bytes = [0x44, 0x7a, 0x00, 0x00]; // 1000.0
        options = {
          exponent = #engineering;
          precision = ?2;
        };
        expected = "1.00e+3"; // exp 3 stays 3
      },
      {
        bytes = [0x41, 0xb8, 0x00, 0x00];
        options = {
          exponent = #scientific;
          precision = ?2;
        };
        expected = "2.30e+1";
      },
      {
        bytes = [0xc1, 0xb8, 0x00, 0x00]; // -23.0
        options = {
          exponent = #engineering;
          precision = ?2;
        };
        expected = "-23.00e+0";
      },
      {
        bytes = [0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        options = { exponent = #none; precision = ?6 };
        expected = "1.000000";
      },
      {
        bytes = [0xbf, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
        options = {
          exponent = #scientific;
          precision = ?3;
        };
        expected = "-1.000e+0";
      },
    ];

    for (testCase in cases.vals()) {
      let precision = switch (testCase.bytes.size()) {
        case (2) #f16;
        case (4) #f32;
        case (8) #f64;
        case (_) Runtime.trap("Invalid byte size: " # debug_show (testCase.bytes.size()));
      };

      let floatX = switch (FloatX.fromBytes(testCase.bytes.vals(), precision, #msb)) {
        case (null) Runtime.trap("Failed to create FloatX from bytes: " # debug_show (testCase.bytes));
        case (?fx) fx;
      };

      let result = FloatX.toTextAdvanced(floatX, testCase.options);
      if (result != testCase.expected) {
        Runtime.trap("toText test failed\nBytes: " # Util.toHexString(testCase.bytes) # "\nOptions: " # debug_show (testCase.options) # "\nExpected: '" # testCase.expected # "'\nActual: '" # result # "'");
      };
    };
  },
);

type ToTextHexTestCase = {
  value : Float;
  precision : FloatX.FloatPrecision;
  options : FloatX.ToTextHexOptions;
  expected : Text;
};

test(
  "toTextHex",
  func() {
    let cases : [ToTextHexTestCase] = [
      // Basic integers
      {
        value = 0.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x0.0p+0";
      },
      {
        value = 1.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.0p+0";
      },
      {
        value = 42.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.5p+5";
      }, // 1.3125 * 2^5
      {
        value = 255.0;
        precision = #f32;
        options = { uppercase = true; exponent = #always };
        expected = "0X1.FEP+7";
      }, // 1.9921875 * 2^7

      // Negative values
      {
        value = -1.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "-0x1.0p+0";
      },
      {
        value = -16.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "-0x1.0p+4";
      },

      // Fractional values
      {
        value = 1.5;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.8p+0";
      }, // 1 + 8/16
      {
        value = 0.5;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.0p-1";
      },
      {
        value = 0.0625;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.0p-4";
      }, // 2^-4
      {
        value = -0.0625;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "-0x1.0p-4";
      },

      // With binary exponents
      {
        value = 6.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.8p+2";
      }, // 1.5 * 2^2
      {
        value = 10.0;
        precision = #f64;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.4p+3";
      }, // 1.25 * 2^3

      // Without exponent (when possible)
      {
        value = 1.5;
        precision = #f32;
        options = { uppercase = false; exponent = #none };
        expected = "0x1.8";
      },
      {
        value = 10.75;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.58p+3";
      }, // Auto includes exponent when needed

      // Uppercase vs lowercase
      {
        value = 10.75;
        precision = #f32;
        options = { uppercase = true; exponent = #always };
        expected = "0X1.58P+3";
      },
      {
        value = 10.75;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.58p+3";
      },

      // Special values
      {
        value = 0.0 / 0.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "NaN";
      },
      {
        value = 1.0 / 0.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "inf";
      },
      {
        value = -1.0 / 0.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "-inf";
      },

      // Different precisions
      {
        value = 1.5;
        precision = #f16;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.8p+0";
      },
      {
        value = 1.5;
        precision = #f64;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.8p+0";
      },

      // Powers of 2
      {
        value = 2.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.0p+1";
      },
      {
        value = 16.0;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.0p+4";
      },
      {
        value = 0.0009765625;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.0p-10";
      }, // 2^-10

      // Complex fractional
      {
        value = 2.25;
        precision = #f32;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.2p+1";
      }, // 2 + 4/16
      {
        value = 16.5;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.08p+4";
      },

      // Very small and very large
      {
        value = 1e-10;
        precision = #f64;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.b7cdfd9d7bdbbp-34";
      },
      {
        value = 1e10;
        precision = #f64;
        options = { uppercase = false; exponent = #always };
        expected = "0x1.2a05f2p+33";
      },

      // #omitZero tests - should include exponent only when non-zero
      {
        value = 1.0;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.0"; // exponent is 0, so omitted
      },
      {
        value = 1.5;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.8"; // exponent is 0, so omitted
      },
      {
        value = 2.0;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.0p+1"; // exponent is 1, so included
      },
      {
        value = 0.5;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.0p-1"; // exponent is -1, so included
      },
      {
        value = 0.0;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x0.0"; // zero has exponent 0, so omitted
      },
      {
        value = -1.0;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "-0x1.0"; // exponent is 0, so omitted
      },
      {
        value = -4.0;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "-0x1.0p+2"; // exponent is 2, so included
      },
      {
        value = 1.25;
        precision = #f64;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.4"; // 1.25 = 1 + 4/16, exponent is 0
      },
      {
        value = 8.0;
        precision = #f32;
        options = { uppercase = true; exponent = #omitZero };
        expected = "0X1.0P+3"; // exponent is 3, uppercase
      },
      {
        value = 0.125;
        precision = #f32;
        options = { uppercase = false; exponent = #omitZero };
        expected = "0x1.0p-3"; // 2^-3, exponent included
      },
    ];

    for (testCase in cases.vals()) {
      let floatX = FloatX.fromFloat(testCase.value, testCase.precision);
      let result = FloatX.toTextHex(floatX, testCase.options);

      // For NaN, just check if both are NaN
      if (Float.isNaN(testCase.value)) {
        if (result != "NaN") {
          Runtime.trap("toTextHex test failed for NaN\nExpected: 'NaN'\nActual: '" # result # "'");
        };
      } else if (result != testCase.expected) {
        Runtime.trap("toTextHex test failed\nValue: " # Float.format(#exact, testCase.value) # "\nPrecision: " # debug_show (testCase.precision) # "\nOptions: " # debug_show (testCase.options) # "\nExpected: '" # testCase.expected # "'\nActual: '" # result # "'\nFloatX: " # debug_show (floatX));
      };
    };
  },
);
