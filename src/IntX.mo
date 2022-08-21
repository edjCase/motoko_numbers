import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Result "mo:base/Result";
import List "mo:base/List";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int32 "mo:base/Int32";
import Int64 "mo:base/Int64";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Float "mo:base/Float";

module {
  public func from64To8(value: Int64) : Int8 {
      Int8.fromInt(Int64.toInt(value));
  };

  public func from64To16(value: Int64) : Int16 {
      Int16.fromInt(Int64.toInt(value));
  };

  public func from64To32(value: Int64) : Int32 {
      Int32.fromInt(Int64.toInt(value));
  };

  public func from64ToInt(value: Int64) : Int {
      Int64.toInt(value);
  };

  
  public func from32To8(value: Int32) : Int8 {
      Int8.fromInt(Int32.toInt(value));
  };

  public func from32To16(value: Int32) : Int16 {
      Int16.fromInt(Int32.toInt(value));
  };

  public func from32To64(value: Int32) : Int64 {
      Int64.fromInt(Int32.toInt(value));
  };

  public func from32ToInt(value: Int32) : Int {
      Int32.toInt(value);
  };


  public func from16To8(value: Int16) : Int8 {
      Int8.fromInt(Int16.toInt(value));
  };

  public func from16To32(value: Int16) : Int32 {
      Int32.fromInt(Int16.toInt(value));
  };

  public func from16To64(value: Int16) : Int64 {
      Int64.fromInt(Int16.toInt(value));
  };

  public func from16ToInt(value: Int16) : Int {
      Int16.toInt(value);
  };


  public func from8To16(value: Int8) : Int16 {
      Int16.fromInt(Int8.toInt(value));
  };

  public func from8To32(value: Int8) : Int32 {
      Int32.fromInt(Int8.toInt(value));
  };

  public func from8To64(value: Int8) : Int64 {
      Int64.fromInt(Int8.toInt(value));
  };

  public func from8ToInt(value: Int8) : Int {
      Int8.toInt(value);
  };



  public func encodeInt(buffer: Buffer.Buffer<Nat8>, value: Int, encoding: {#signedLEB128}) : Nat {
    // TODO
    0;
  };

  public func encodeInt8(buffer: Buffer.Buffer<Nat8>, value: Int8, encoding: {#lsb; #msb}) {
    buffer.add(Int8.toNat8(value));
  };

  public func encodeInt16(buffer: Buffer.Buffer<Nat8>, value: Int16, encoding: {#lsb; #msb}) {
    encodeIntX(buffer, Int64.fromInt(Int16.toInt(value)), encoding, #b16);
  };

  public func encodeInt32(buffer: Buffer.Buffer<Nat8>, value: Int32, encoding: {#lsb; #msb}) {
    encodeIntX(buffer, Int64.fromInt(Int32.toInt(value)), encoding, #b32);
  };

  public func encodeInt64(buffer: Buffer.Buffer<Nat8>, value: Int64, encoding: {#lsb; #msb}) {
    encodeIntX(buffer, Int64.fromInt(Int64.toInt(value)), encoding, #b64);
  };

  private func getByteLength(size: {#b16; #b32; #b64}) : Nat64 {
    switch(size) {
      case (#b16) 2;
      case (#b32) 4;
      case (#b64) 8;
    }
  };


  private func encodeIntX(buffer: Buffer.Buffer<Nat8>, value: Int64, encoding: {#lsb; #msb}, size: {#b16; #b32; #b64}) {
    let byteLength: Nat64 = getByteLength(size);
    for (i in Iter.range(0, Nat64.toNat(byteLength) - 1)) {
      let byteOffset: Nat64 = switch (encoding) {
        case (#lsb) Nat64.fromNat(i);
        case (#msb) Nat64.fromNat(Nat64.toNat(byteLength) - i);
      };
      let byte: Nat8 = Nat8.fromNat(Nat64.toNat(Int64.toNat64(value >> Int64.fromNat64(byteOffset))));
      buffer.add(byte);
    };
  };

}