import Nat8 "mo:core@1/Nat8";
import Nat "mo:core@1/Nat";

module {
  public func bytesAreEqual(b1 : [Nat8], b2 : [Nat8]) : Bool {

    if (b1.size() != b2.size()) {
      return false;
    };
    for (i in Nat.range(0, b1.size())) {
      if (b1[i] != b2[i]) {
        return false;
      };
    };
    true;
  };

};
