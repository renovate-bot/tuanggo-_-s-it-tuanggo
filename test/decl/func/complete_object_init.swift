// RUN: %swift -parse %s -verify

// ---------------------------------------------------------------------------
// Declaration of complete object initializers and basic semantic checking
// ---------------------------------------------------------------------------
class A {
  convenience init(int i: Int) { // expected-note{{convenience initializer is declared here}}
    self.init(double: Double(i))
  }

  convenience init(float f: Float) {
    self.init(double: Double(f))
  }

  init(double d: Double) { 
  }
  
  convenience init(crazy : A) {
    self.init(int: 42)
  }
}

class OtherA {
  init(double d: Double, negated: Bool) { // expected-error{{designated initializer for 'OtherA' cannot delegate (with 'self.init'); did you mean this to be a convenience initializer?}}{{3-3=convenience }}
    self.init(double: negated ? -d : d) // expected-note{{delegation occurs here}}
  }

  init(double d: Double) { 
  }
}

class DerivesA : A {
  init(int i: Int) {
    super.init(int: i) // expected-error{{must call a designated initializer of the superclass 'A'}}
  }

  convenience init(string: String) {
    super.init(double: 3.14159) // expected-error{{convenience initializer for 'DerivesA' must delegate (with 'self.init') rather than chaining to a superclass initializer (with 'super.init')}}
  }
}

struct S {
  convenience init(int i: Int) { // expected-error{{convenience initializer not allowed in non-class type 'S'}}
    self.init(double: Double(i))
  }  

  init(double d: Double) { 
  }
}

class DefaultInitComplete {
  convenience init() {
    self.init(string: "foo")
  }

  init(string: String) { }
}

class SubclassDefaultInitComplete : DefaultInitComplete {
  init() { }
}

// ---------------------------------------------------------------------------
// Inheritance of initializers
// ---------------------------------------------------------------------------

// inherits convenience initializers
class B1 : A {
  override init(double d: Double) {
    super.init(double: d)
  }
}

func testConstructB1(i: Int, f: Float, d: Double) {
  var b1a = B1(int: i)
  var b1b = B1(float: f)
  var b1c = B1(double: d)

  var b: B1 = b1a
  b = b1b
  b = b1c
}

// does not inherit convenience initializers
class B2 : A {
  var s: String

  init() { 
    s = "hello"
    super.init(double: 1.5) 
  }
}

func testConstructB2(i: Int) {
  var b2a = B2()
  var b2b = B2(int: i) // expected-error{{extra argument 'int' in call}}

  var b2: B2 = b2a
}

// Initializer inheritance can satisfy the requirement for an
// @required initializer within a subclass.
class Ab1 {
  required init() { }
}

class Ab2 : Ab1 {
  var s: String

  // Subclasses can use this to satisfy the required initializer
  // requirement.
  required convenience init() { // expected-note{{'required' initializer 'init()' not overridden}}
    self.init(string: "default")
  }

  init(string s: String) {
    self.s = s
    super.init()
  }
}

class Ab3 : Ab2 {
  override init(string s: String) {
    super.init(string: s)
  }
}

class Ab4 : Ab3 { // expected-error{{class 'Ab4' does not implement its superclass's required members}}

  init(int: Int) { 
    super.init(string:"four")
  }
}

// Only complete object initializers are allowed in extensions
class Extensible { }

extension Extensible {
  init(int i: Int) { // expected-error{{designated initializer cannot be declared in an extension of 'Extensible'; did you mean this to be a convenience initializer?}}{{3-3=convenience }}
    self.init()
  }
}
