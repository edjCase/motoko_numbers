# Motoko Extended Numbers

[![MOPS](https://img.shields.io/badge/MOPS-xtended--numbers-blue)](https://mops.one/xtended-numbers)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/edjCase/motoko_numbers/blob/main/LICENSE)

A comprehensive Motoko library that extends the base number functionality with advanced features including 16/32-bit precision floats, number encoding/decoding, text parsing, and type conversions. This library provides robust utilities for working with various number formats and encodings in Motoko applications.

## Package

### MOPS

```bash
mops add xtended-numbers
```

To set up MOPS package manager, follow the instructions from the [MOPS Site](https://mops.one)

## Quick Start

### Example 1: Number Text Parsing

```motoko
import IntX "mo:xtended-numbers/IntX";
import NatX "mo:xtended-numbers/NatX";

// Parse integers with different formats
let hexValue = IntX.fromTextAdvanced("0xFF", #hex, null);
let binaryValue = IntX.fromTextAdvanced("1010", #binary, null);
let decimalWithSeparator = IntX.fromTextAdvanced("1,000,000", #decimal, ?',');

// Parse natural numbers
let natValue = NatX.fromTextAdvanced("1_000_000", #decimal, ?'_');

switch (hexValue) {
  case (?value) Debug.print("Hex 0xFF = " # Int.toText(value));
  case null Debug.print("Failed to parse hex value");
};
```

### Example 2: Binary Encoding

```motoko
import IntX "mo:xtended-numbers/IntX";
import Buffer "mo:buffer";

// Encode integer to array
let int32Value : Int32 = 42;
let intBytes = IntX.toInt32Bytes(int32Value, #msb); // Big-endian encoding

Debug.print("Bytes: " # debug_show(intBytes));
```

### Example 3: Binary Encoding to Buffer

```motoko
let list = List.empty<Nat8>();
let buffer = Buffer.fromList(list);
// Encode integer to buffer
IntX.toInt32BytesBuffer(buffer, int32Value, #msb); // Big-endian encoding

Debug.print("Bytes: " # debug_show(List.toArray(list)));
```

### Example 4: Type Conversions

```motoko
import IntX "mo:xtended-numbers/IntX";
import NatX "mo:xtended-numbers/NatX";

// Safe type conversions with overflow protection
let largeInt64 : Int64 = 1000000;

// Convert between different integer sizes
let int32Value = IntX.from64To32(largeInt64); // Traps on overflow
let int16Value = IntX.from32To16(int32Value);
let int8Value = IntX.from16To8(int16Value);

// Convert between signed and unsigned
let natValue = NatX.from64ToNat(Int.abs(largeInt64));
let nat32Value = NatX.from64To32(natValue);

Debug.print("Converted chain: " # Int8.toText(int8Value));
```

### Example 5: Float Precision Conversion

```motoko
import FloatX "mo:xtended-numbers/FloatX";
import Debug "mo:core/Debug";

// Convert standard Float to 16-bit precision
let standardFloat : Float = 3.14159;
let float16 = FloatX.fromFloat(standardFloat, #f16);

// Convert back to standard Float
let backToFloat = FloatX.toFloat(float16);
Debug.print("Original: " # Float.toText(standardFloat));
Debug.print("16-bit precision: " # Float.toText(backToFloat));

// Check for special values
if (FloatX.isNaN(float16)) {
  Debug.print("Value is NaN");
} else if (FloatX.isPosInf(float16)) {
  Debug.print("Value is positive infinity");
};
```

## API Reference

### FloatX Module

```motoko
// Float precision types
public type FloatPrecision = {#f16; #f32; #f64};
public type FloatX = {precision: FloatPrecision; /* internal representation */};

// Core conversion functions
public func fromFloat(float: Float, precision: FloatPrecision) : FloatX;
public func toFloat(fX: FloatX) : Float;

// Comparison and validation
public func nearlyEqual(a: Float, b: Float, relativeTolerance: Float, absoluteTolerance: Float): Bool;
public func isNaN(fX: FloatX) : Bool;
public func isPosInf(fX: FloatX) : Bool;
public func isNegInf(fX: FloatX) : Bool;

// Binary encoding
public func toBytes(value: FloatX, encoding: {#lsb; #msb}) : [Nat8];
public func toBytesBuffer(buffer: Buffer.Buffer<Nat8>, value: FloatX, encoding: {#lsb; #msb});
public func fromBytes(bytes: Iter.Iter<Nat8>, precision: {#f16; #f32; #f64}, encoding: {#lsb; #msb}) : ?FloatX;
```

### IntX Module

```motoko
// Text formatting type
public type Format = {#decimal; #hex; #binary; #octal};

// Text conversion
public func toText(value : Int) : Text;
public func toTextAdvanced(value : Int, format : Format) : Text;
public func fromText(value : Text) : ?Int;
public func fromTextAdvanced(value : Text, format : Format, seperator : ?Char) : ?Int;

// Type conversions (examples - full set available)
public func from64To32(value: Int64) : Int32;
public func from32To16(value: Int32) : Int16;
public func from16To8(value: Int16) : Int8;

// Binary encoding
public func toIntBytes(value: Int, encoding: {#signedLEB128; #lsb; #msb}) : [Nat8];
public func toIntBytesBuffer(buffer: Buffer.Buffer<Nat8>, value: Int, encoding: {#signedLEB128; #lsb; #msb});
public func toInt32Bytes(value: Int32, encoding: {#lsb; #msb}) : [Nat8];
public func toInt32BytesBuffer(buffer: Buffer.Buffer<Nat8>, value: Int32, encoding: {#lsb; #msb});
public func fromInt32Bytes(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int32;
```

### NatX Module

```motoko
// Similar API to IntX but for natural numbers
public func toText(value : Nat) : Text;
public func fromText(value : Text) : ?Nat;
public func from64To32(value: Nat64) : Nat32;
public func toNatBytes(value: Nat, encoding: {#unsignedLEB128; #lsb; #msb}) : [Nat8];
public func toNatBytesBuffer(buffer: Buffer.Buffer<Nat8>, value: Nat, encoding: {#unsignedLEB128; #lsb; #msb});
public func toNat32Bytes(value: Nat32, encoding: {#lsb; #msb}) : [Nat8];
public func toNat32BytesBuffer(buffer: Buffer.Buffer<Nat8>, value: Nat32, encoding: {#lsb; #msb});
public func fromNat32Bytes(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat32;
// ... (full API similar to IntX)
```

## Testing

```bash
mops test
```

## Funding

This library was originally incentivized by [ICDevs](https://ICDevs.org). You can view more about the bounty on the [forum](https://forum.dfinity.org/t/icdevs-org-bounty-18-cbor-and-candid-motoko-parser-3-000/11398) or [website](https://icdevs.org/bounties/2022/02/22/CBOR-and-Candid-Motoko-Parser.html). The bounty was funded by The ICDevs.org community and the award paid to @Gekctek. If you use this library and gain value from it, please consider a [donation](https://icdevs.org/donations.html) to ICDevs.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
