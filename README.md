## Funding

This library was originally incentivized by [ICDevs](https://ICDevs.org). You
can view more about the bounty on the
[forum](https://forum.dfinity.org/t/icdevs-org-bounty-18-cbor-and-candid-motoko-parser-3-000/11398)
or [website](https://icdevs.org/bounties/2022/02/22/CBOR-and-Candid-Motoko-Parser.html). The
bounty was funded by The ICDevs.org commuity and the award paid to
@Gekctek. If you use this library and gain value from it, please consider
a [donation](https://icdevs.org/donations.html) to ICDevs.

# Overview

This is a library that extends on the Motoko base library for numbers. Maily focuses on encoding of numbers and 16/32 bit precision floats

# Package

### MOPS

```
mops install xtended-numbers
```

To setup MOPS package manage, follow the instructions from the [MOPS Site](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/)

# API

## FloatX

`nearlyEqual(a: Float, b: Float, relativeTolerance: Float, absoluteTolerance: Float): Bool`

Takes in 2 floats and compares them loosely according to the tolerances. Absolute tolerance is a max flat difference between the values. Relative tolerance is the max difference between the values based on the percentage of the max value. For example, given the values `nealyEqual(1, 5, .0001, .001)` the relative diff is `max(1, 5) * .0001` or `.0005` while the absolute diff is `.001`

`fromFloat(float: Float, precision: FloatPrecision) : FloatX`

Converts a `Float` to a `FloatX` with the specified precision

`toFloat(fX: FloatX) : Float`

Converts a `FloatX` to a `Float`

`encode(buffer: Buffer.Buffer<Nat8>, value: FloatX, encoding: {#lsb; #msb})`

Encodes a `FloatX` to bytes buffer

`decode(bytes: Iter.Iter<Nat8>, precision: {#f16; #f32; #f64}, encoding: {#lsb; #msb}) : ?FloatX`

Decodes a `FloatX` from an iteration of bytes. If null is returned, then there was an error decoding or an unexpected end of bytes

`isNaN(fX: FloatX) : Bool`

Returns `true` if the `FloatX` value represents NaN (Not a Number), `false` otherwise

`isPosInf(fX: FloatX) : Bool`

Returns `true` if the `FloatX` value represents positive infinity, `false` otherwise

`isNegInf(fX: FloatX) : Bool`

Returns `true` if the `FloatX` value represents negative infinity, `false` otherwise

## IntX

`toText(value : Int) : Text`

Converts an Int into a text representation. Outputs a decimal value (-?[0-9]+).

`toTextAdvanced(value : Int, format : Format) : Text`

Converts an Int into a text representation. Allows for the specification of the output format.

`fromText(value : Text) : ?Int`

Converts text representation of a decimal integer (-?[0-9]+). If the text cannot
be parsed as an integer, the value returned will be null. Same as calling the `fromTextAdvanced`
with the `#decimal` format and no seperator

`fromTextAdvanced(value : Text, format : Format, seperator : ?Char) : ?Int`

Converts text representation of an integer in a specified format. Optioanlly can specify the
seperator that should be ignored (',' for 1,000,000 or '\_' for 1_000_000). If the text cannot
be parsed as an integer, the value returned will be null

`from64To8(value: Int64) : Int8`

Conversion. Traps on overflow/underflow.

`from64To16(value: Int64) : Int16`

Conversion. Traps on overflow/underflow.

`from64To32(value: Int64) : Int32`

Conversion. Traps on overflow/underflow.

`from64ToInt(value: Int64) : Int`

Conversion. Traps on overflow/underflow.

`from32To8(value: Int32) : Int8`

Conversion. Traps on overflow/underflow.

`from32To16(value: Int32) : Int16`

Conversion. Traps on overflow/underflow.

`from32To64(value: Int32) : Int64`

Conversion. Traps on overflow/underflow.

`from32ToInt(value: Int32) : Int`

Conversion. Traps on overflow/underflow.

`from16To8(value: Int16) : Int8`

Conversion. Traps on overflow/underflow.

`from16To32(value: Int16) : Int32`

Conversion. Traps on overflow/underflow.

`from16To64(value: Int16) : Int64`

Conversion. Traps on overflow/underflow.

`from16ToInt(value: Int16) : Int`

Conversion. Traps on overflow/underflow.

`from8To16(value: Int8) : Int16`

Conversion. Traps on overflow/underflow.

`from8To32(value: Int8) : Int32`

Conversion. Traps on overflow/underflow.

`from8To64(value: Int8) : Int64`

Conversion. Traps on overflow/underflow.

`from8ToInt(value: Int8) : Int`

Conversion. Traps on overflow/underflow.

`encodeInt(buffer: Buffer.Buffer<Nat8>, value: Int, encoding: {#signedLEB128})`

Encodes the specified value into the byte buffer

`encodeInt8(buffer: Buffer.Buffer<Nat8>, value: Int8)`

Encodes the specified value into the byte buffer

`encodeInt16(buffer: Buffer.Buffer<Nat8>, value: Int16, encoding: {#lsb; #msb})`

Encodes the specified value into the byte buffer

`encodeInt32(buffer: Buffer.Buffer<Nat8>, value: Int32, encoding: {#lsb; #msb})`

Encodes the specified value into the byte buffer

`encodeInt64(buffer: Buffer.Buffer<Nat8>, value: Int64, encoding: {#lsb; #msb})`

Encodes the specified value into the byte buffer

`decodeInt(bytes: Iter.Iter<Nat8>, encoding: {#signedLEB128}) : ?Int`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeInt8(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int8`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeInt16(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int16`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeInt32(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int32`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeInt64(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Int64`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

## NatX

`toText(value : Nat) : Text`

Converts an Nat into a text representation. Outputs a decimal value (-?[0-9]+).

`toTextAdvanced(value : Nat, format : Format) : Text`

Converts an Nat into a text representation. Allows for the specification of the output format.

`fromText(value : Text) : ?Nat`

Converts text representation of a decimal positive integer (-?[0-9]+). If the text cannot
be parsed as an positive integer, the value returned will be null. Same as calling the `fromTextAdvanced`
with the `#decimal` format and no seperator

`fromTextAdvanced(value : Text, format : Format, seperator : ?Char) : ?Nat`

Converts text representation of an positive integer in a specified format. Optioanlly can specify the
seperator that should be ignored (',' for 1,000,000 or '\_' for 1_000_000). If the text cannot
be parsed as an positive integer, the value returned will be null

`from64To8(value: Nat64) : Nat8`

Conversion. Traps on overflow/underflow.

`from64To16(value: Nat64) : Nat16`

Conversion. Traps on overflow/underflow.

`from64To32(value: Nat64) : Nat32`

Conversion. Traps on overflow/underflow.

`from64ToNat(value: Nat64) : Nat`

Conversion. Traps on overflow/underflow.

`from32To8(value: Nat32) : Nat8`

Conversion. Traps on overflow/underflow.

`from32To16(value: Nat32) : Nat16`

Conversion. Traps on overflow/underflow.

`from32To64(value: Nat32) : Nat64`

Conversion. Traps on overflow/underflow.

`from32ToNat(value: Nat32) : Nat`

Conversion. Traps on overflow/underflow.

`from16To8(value: Nat16) : Nat8`

Conversion. Traps on overflow/underflow.

`from16To32(value: Nat16) : Nat32`

Conversion. Traps on overflow/underflow.

`from16To64(value: Nat16) : Nat64`

Conversion. Traps on overflow/underflow.

`from16ToNat(value: Nat16) : Nat`

Conversion. Traps on overflow/underflow.

`from8To16(value: Nat8) : Nat16`

Conversion. Traps on overflow/underflow.

`from8To32(value: Nat8) : Nat32`

Conversion. Traps on overflow/underflow.

`from8To64(value: Nat8) : Nat64`

Conversion. Traps on overflow/underflow.

`from8ToNat(value: Nat8) : Nat`

Conversion. Traps on overflow/underflow.

`encodeNat(buffer: Buffer.Buffer<Nat8>, value: Nat, encoding: {#signedLEB128})`

Encodes the specified value into the byte buffer

`encodeNat8(buffer: Buffer.Buffer<Nat8>, value: Nat8)`

Encodes the specified value into the byte buffer

`encodeNat16(buffer: Buffer.Buffer<Nat8>, value: Nat16, encoding: {#lsb; #msb})`

Encodes the specified value into the byte buffer

`encodeNat32(buffer: Buffer.Buffer<Nat8>, value: Nat32, encoding: {#lsb; #msb})`

Encodes the specified value into the byte buffer

`encodeNat64(buffer: Buffer.Buffer<Nat8>, value: Nat64, encoding: {#lsb; #msb})`

Encodes the specified value into the byte buffer

`decodeNat(bytes: Iter.Iter<Nat8>, encoding: {#signedLEB128}) : ?Nat`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeNat8(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat8`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeNat16(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat16`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeNat32(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat32`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

`decodeNat64(bytes: Iter.Iter<Nat8>, encoding: {#lsb; #msb}) : ?Nat64`

Decodes the iteration of bytes into a value. If invalid bytes, null will be returned

# Testing

```
mops test
```
