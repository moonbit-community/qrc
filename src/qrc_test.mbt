///|
test "qr_encode_numeric" {
  let qr = encode("12345")
  if qr.data != "12345" {
    fail("QR data should be '12345'")
  }
  match qr.mode {
    Mode::Numeric => ()
    _ => fail("QR mode should be Numeric")
  }
}

///|
test "qr_encode_alphanumeric" {
  let qr = encode("HELLO WORLD")
  if qr.data != "HELLO WORLD" {
    fail("QR data should be 'HELLO WORLD'")
  }
  match qr.mode {
    Mode::Alphanumeric => ()
    _ => fail("QR mode should be Alphanumeric")
  }
}

///|
test "qr_encode_byte" {
  let qr = encode("Hello, World!")
  if qr.data != "Hello, World!" {
    fail("QR data should be 'Hello, World!'")
  }
  match qr.mode {
    Mode::Byte => ()
    _ => fail("QR mode should be Byte")
  }
}

///|
test "qr_matrix_size" {
  let qr = encode("TEST")
  let expected_size = version_to_size(1) // Version 1 = 21x21
  if qr.matrix.size != expected_size {
    fail("QR matrix size should be " + expected_size.to_string())
  }
}

///|
test "detect_mode_numeric" {
  let mode = detect_mode("123456789")
  match mode {
    Mode::Numeric => ()
    _ => fail("Should detect numeric mode")
  }
}

///|
test "detect_mode_alphanumeric" {
  let mode = detect_mode("ABC123 $%*+-./:")
  match mode {
    Mode::Alphanumeric => ()
    _ => fail("Should detect alphanumeric mode")
  }
}

///|
test "detect_mode_byte" {
  let mode = detect_mode("Hello, World!")
  match mode {
    Mode::Byte => ()
    _ => fail("Should detect byte mode")
  }
}

///|
test "reed_solomon_basic" {
  let data = [1, 2, 3, 4]
  let corrected = apply_error_correction(
    data,
    make_byte_mode(),
    1,
    make_ec_level_m(),
  )
  if corrected.length() <= data.length() {
    fail("Error correction should add redundancy")
  }
}

///|
test "error_correction_levels" {
  let ec_l = get_error_correction_codewords(1, make_ec_level_l())
  let ec_m = get_error_correction_codewords(1, make_ec_level_m())
  let ec_q = get_error_correction_codewords(1, make_ec_level_q())
  let ec_h = get_error_correction_codewords(1, make_ec_level_h())
  if not(ec_l < ec_m && ec_m < ec_q && ec_q < ec_h) {
    fail("Error correction levels should be in ascending order")
  }
}

///|
test "galois_field_arithmetic" {
  // Test basic GF operations
  let a = gf_mul(2, 3)
  let b = gf_mul(a, gf_div(1, 2))
  if b != 3 {
    fail("Galois field arithmetic failed")
  }
}

///|
test "kanji_mode_support" {
  // Test that Kanji mode can be created and used (treated as byte mode)
  let kanji_mode = make_kanji_mode()
  let qr = encode_with_mode_and_ec("漢字", kanji_mode, 1, make_ec_level_m())
  match qr.mode {
    Mode::Kanji => ()
    _ => fail("Should support Kanji mode")
  }
}

///|
test "mask_pattern_generation" {
  // Test that mask patterns can be created and applied
  let qr = generate_qr_with_mask("TEST", make_ec_level_m())
  if qr.matrix.size != 21 {
    fail("QR matrix size should be 21x21 for version 1")
  }
  if qr.data != "TEST" {
    fail("QR data should be preserved")
  }
}

///|
test "mask_penalty_evaluation" {
  // Test mask penalty scoring
  let matrix = new_matrix(21)
  let penalty = evaluate_mask_penalty(matrix)
  if penalty < 0 {
    fail("Penalty should be non-negative")
  }
}
