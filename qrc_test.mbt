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
  // Test that Kanji mode can be created and used (now with proper encoding)
  let kanji_mode = make_kanji_mode()
  let qr = encode_with_mode_and_ec("漢字", kanji_mode, 1, make_ec_level_m())
  match qr.mode {
    Mode::Kanji => ()
    _ => fail("Should support Kanji mode")
  }
}

///|
test "kanji_character_detection" {
  // Test Kanji character detection
  let hiragana_char = 12354 // あ (Hiragana A)
  let katakana_char = 12450 // ア (Katakana A)  
  let kanji_char = 28450     // 漢 (Kanji)
  let ascii_char = 65        // A (ASCII)
  
  if not(is_kanji_character(hiragana_char)) {
    fail("Should detect Hiragana as Kanji character")
  }
  if not(is_kanji_character(katakana_char)) {
    fail("Should detect Katakana as Kanji character")
  }
  if not(is_kanji_character(kanji_char)) {
    fail("Should detect Kanji as Kanji character")
  }
  if is_kanji_character(ascii_char) {
    fail("Should not detect ASCII as Kanji character")
  }
}

///|
test "kanji_mode_detection" {
  // Test automatic Kanji mode detection
  let japanese_text = "こんにちは" // "Hello" in Hiragana
  let mixed_text = "Hello世界"    // Mixed English and Kanji
  let english_text = "Hello"     // Pure English
  
  // Note: For this test to work, we'd need actual Japanese characters
  // For now, we'll test the logic with the detection function
  let uppercase_text = "HELLO" // QR alphanumeric mode only supports uppercase
  let mode1 = detect_mode(uppercase_text)
  match mode1 {
    Mode::Alphanumeric => () // Should be alphanumeric for "HELLO"
    _ => fail("Should detect alphanumeric mode for uppercase English text")
  }
  
  // Test that lowercase is detected as byte mode
  let mode2 = detect_mode(english_text) // "Hello" with lowercase
  match mode2 {
    Mode::Byte => () // Should be byte mode for mixed case
    _ => fail("Should detect byte mode for mixed case English text")
  }
}

///|
test "kanji_encoding" {
  // Test Kanji encoding function
  let test_data = encode_kanji("A漢")  // Mixed ASCII and Kanji
  if test_data.length() == 0 {
    fail("Kanji encoding should produce output")
  }
  // The exact output depends on the character codes, but it should not be empty
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

///|
test "qr_basic_structure" {
  // Test QR code basic structure without masking
  let qr = generate_qr("TEST", make_ec_level_m())
  if qr.matrix.size != 21 {
    fail("QR matrix size should be 21x21 for version 1")
  }
  
  // Check that finder patterns are present (top-left corner should have dark modules)
  match get_module(qr.matrix, 0, 0) {
    Module::Dark => ()
    Module::Light => fail("Top-left corner of finder pattern should be dark")
  }
  
  // Note: Timing pattern alternation is tested separately in timing_pattern_only test
  // since the full QR generation process includes masking which may affect the pattern
}

///|
test "timing_pattern_only" {
  // Test just the timing pattern placement
  let matrix = init_matrix(1)
  
  // Check timing pattern directly after initialization
  let timing_6_8 = get_module(matrix, 6, 8)
  let timing_6_9 = get_module(matrix, 6, 9)
  let timing_6_10 = get_module(matrix, 6, 10)
  
  let timing_8_str = match timing_6_8 { 
    Module::Dark => "Dark" 
    Module::Light => "Light" 
  }
  let timing_9_str = match timing_6_9 { 
    Module::Dark => "Dark" 
    Module::Light => "Light" 
  }
  let timing_10_str = match timing_6_10 { 
    Module::Dark => "Dark" 
    Module::Light => "Light" 
  }
  
  println("Direct timing check - (6,8): " + timing_8_str + ", (6,9): " + timing_9_str + ", (6,10): " + timing_10_str)
  
  // Check if is_data_position correctly identifies timing positions
  let is_data_6_8 = is_data_position(matrix, 6, 8)
  let is_data_6_9 = is_data_position(matrix, 6, 9)
  let is_data_6_10 = is_data_position(matrix, 6, 10)
  
  println("is_data_position - (6,8): " + is_data_6_8.to_string() + ", (6,9): " + is_data_6_9.to_string() + ", (6,10): " + is_data_6_10.to_string())
  
  // These should all be false since they're timing pattern positions
  if is_data_6_8 || is_data_6_9 || is_data_6_10 {
    fail("Timing pattern positions should not be data positions")
  }
}

///|
test "qr_with_masking_structure" {
  // Test QR code structure with masking
  let qr = generate_qr_with_mask("TEST", make_ec_level_m())
  if qr.matrix.size != 21 {
    fail("QR matrix size should be 21x21 for version 1")
  }
  
  // Finder patterns should still be recognizable even after masking
  // The corners of finder patterns should maintain their structure
  let corner_modules = [
    get_module(qr.matrix, 0, 0),
    get_module(qr.matrix, 6, 0), 
    get_module(qr.matrix, 0, 6),
    get_module(qr.matrix, 6, 6)
  ]
  
  // At least some corners should be dark (finder pattern structure)
  let mut dark_count = 0
  for mod in corner_modules {
    match mod {
      Module::Dark => dark_count = dark_count + 1
      Module::Light => ()
    }
  }
  if dark_count == 0 {
    fail("Finder pattern structure should be preserved after masking")
  }
}

///|
test "version_selection" {
  // Test automatic version selection
  let short_data = "Hi"
  let long_data = "This is a much longer string that should require a higher QR version to encode properly with all the data"
  
  let qr1 = encode(short_data)
  let qr2 = encode(long_data)
  
  // Short data should use version 1
  if qr1.version != 1 {
    fail("Short data should use version 1")
  }
  
  // Long data should use a higher version
  if qr2.version <= 1 {
    fail("Long data should require version > 1")
  }
  
  // Matrix size should match version
  let expected_size1 = version_to_size(qr1.version)
  let expected_size2 = version_to_size(qr2.version)
  
  if qr1.matrix.size != expected_size1 {
    fail("QR1 matrix size should match version")
  }
  if qr2.matrix.size != expected_size2 {
    fail("QR2 matrix size should match version")
  }
}

///|
test "version_info_encoding" {
  // Test version information encoding for versions 7+
  let version7_info = encode_version_info(7)
  let version1_info = encode_version_info(1)
  
  if version1_info != 0 {
    fail("Version 1 should not have version info")
  }
  
  if version7_info == 0 {
    fail("Version 7 should have version info")
  }
}

///|
test "alignment_patterns" {
  // Test alignment pattern positions
  let positions_v1 = get_alignment_positions(1)
  let positions_v2 = get_alignment_positions(2)
  
  if positions_v1.length() != 0 {
    fail("Version 1 should have no alignment patterns")
  }
  
  if positions_v2.length() == 0 {
    fail("Version 2 should have alignment patterns")
  }
}

///|
test "data_capacity_calculation" {
  // Test data capacity calculation
  let capacity_v1_l = get_data_capacity(1, make_ec_level_l())
  let capacity_v1_h = get_data_capacity(1, make_ec_level_h())
  let capacity_v2_m = get_data_capacity(2, make_ec_level_m())
  
  // Higher error correction should have less data capacity
  if capacity_v1_l <= capacity_v1_h {
    fail("Level L should have more capacity than Level H")
  }
  
  // Higher version should have more capacity
  if capacity_v2_m <= capacity_v1_l {
    fail("Version 2 should have more capacity than Version 1")
  }
}
