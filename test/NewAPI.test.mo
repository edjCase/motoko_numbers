import FloatX "../src/FloatX";
import IntX "../src/IntX";
import NatX "../src/NatX";
import Buffer "mo:buffer@0";
import List "mo:core@1/List";
import { test } "mo:test";
import Runtime "mo:core@1/Runtime";

test(
  "toBytes API",
  func() {
    // Test FloatX toBytes
    let float32Value = FloatX.fromFloat(3.14159, #f32);
    let floatBytes = FloatX.toBytes(float32Value, #lsb);
    if (floatBytes.size() != 4) {
      Runtime.trap("Expected 4 bytes for f32, got " # debug_show (floatBytes.size()));
    };

    // Test IntX toBytes
    let int32Bytes = IntX.toInt32Bytes(42, #msb);
    if (int32Bytes.size() != 4) {
      Runtime.trap("Expected 4 bytes for Int32, got " # debug_show (int32Bytes.size()));
    };

    // Test NatX toBytes
    let nat32Bytes = NatX.toNat32Bytes(42, #msb);
    if (nat32Bytes.size() != 4) {
      Runtime.trap("Expected 4 bytes for Nat32, got " # debug_show (nat32Bytes.size()));
    };
  },
);

test(
  "toBytesBuffer API",
  func() {
    let list = List.empty<Nat8>();
    let buffer = Buffer.fromList(list);

    // Test FloatX toBytesBuffer
    let float32Value = FloatX.fromFloat(3.14159, #f32);
    FloatX.toBytesBuffer(buffer, float32Value, #lsb);

    // Test IntX toBytesBuffer
    IntX.toInt32BytesBuffer(buffer, 42, #msb);

    // Test NatX toBytesBuffer
    NatX.toNat32BytesBuffer(buffer, 42, #msb);

    let resultBytes = List.toArray(list);
    if (resultBytes.size() != 12) {
      // 4 + 4 + 4 bytes
      Runtime.trap("Expected 12 bytes total, got " # debug_show (resultBytes.size()));
    };
  },
);
