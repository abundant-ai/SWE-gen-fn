The standard library integer modules are missing common bit-counting operations, and code that needs them currently has to reimplement them. Add a consistent API for bit counting to the integer modules Int, Int32, Int64, and Nativeint.

Implement the following functions for each module (with the module’s integer type):

- popcount : t -> int
  Returns the number of 1 bits in the two’s-complement bit pattern of the value. For example, popcount 0 = 0, popcount 1 = 1, and popcount (-1) equals the bit width of the type (Sys.int_size for Int, 32 for Int32, 64 for Int64, Sys.word_size for Nativeint).

- nlz : t -> int
  Returns the number of leading zeros in the fixed-width binary representation. nlz 0 should return the full bit width. For nonzero values, nlz must be in the range [0, bitwidth-1]. Example (Int64): nlz 1L = 63, nlz (Int64.min_int) = 0.

- ntz : t -> int
  Returns the number of trailing zeros in the fixed-width binary representation. ntz 0 should return the full bit width. For nonzero values, ntz must be in the range [0, bitwidth-1]. Example (Int64): ntz 1L = 0, ntz 2L = 1.

Also provide these derived functions, with definitions consistent with two’s-complement arithmetic:

- nls : t -> int
  Returns the number of leading sign bits: the count of consecutive most-significant bits equal to the sign bit. For x = 0, nls should return the full bit width. For x = -1, nls should also return the full bit width. For other values, nls must be in [1, bitwidth-1].

- unsigned_bitsize : t -> int
  Returns the number of bits required to represent the value as an unsigned integer (using the module’s fixed width). It should be 0 when the value is 0. For nonzero values, it should be bitwidth - nlz x (and thus in [1, bitwidth]).

- signed_bitsize : t -> int
  Returns the number of bits required to represent the value in signed two’s-complement with no loss of information, using the smallest width that preserves the value. It should be 1 for 0 and -1. For other values, it should be between 2 and bitwidth inclusive.

All functions must behave correctly for random inputs and edge cases (0, 1, powers of two, max_int, min_int, -1, and other negative values), and must respect each type’s fixed bit width (Sys.int_size for Int, 32 for Int32, 64 for Int64, Sys.word_size for Nativeint).