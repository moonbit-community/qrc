// QR Code Error Correction Levels
pub enum ErrorCorrectionLevel {
  L  // ~7% correction
  M  // ~15% correction
  Q  // ~25% correction
  H  // ~30% correction
} derive(Eq)

// QR Code Data Modes
pub enum Mode {
  Numeric
  Alphanumeric
  Byte
  Kanji
} derive(Eq)

// QR Code Version (1-40)
pub typealias Int as Version

// QR Code Module (pixel) state
pub enum Module {
  Light
  Dark
} derive(Eq)

// QR Code Matrix
pub struct Matrix {
  size : Int
  modules : Array[Array[Module]]
}

// QR Code Data
pub struct QRCode {
  version : Version
  error_correction : ErrorCorrectionLevel
  mode : Mode
  data : String
  matrix : Matrix
}

// Create a new QR code matrix
pub fn new_matrix(size : Int) -> Matrix {
  let modules = Array::make(size, Array::make(size, Module::Light))
  { size, modules }
}

// Get module at position
pub fn get_module(matrix : Matrix, x : Int, y : Int) -> Module {
  if x >= 0 && x < matrix.size && y >= 0 && y < matrix.size {
    matrix.modules[y][x]
  } else {
    Module::Light
  }
}

// Set module at position
pub fn set_module(matrix : Matrix, x : Int, y : Int, mod : Module) -> Unit {
  if x >= 0 && x < matrix.size && y >= 0 && y < matrix.size {
    matrix.modules[y][x] = mod
  }
}

// Get QR code size for version
pub fn version_to_size(version : Version) -> Int {
  21 + (version - 1) * 4
}

// Determine the best mode for input data
pub fn detect_mode(data : String) -> Mode {
  let is_numeric = fn(c : Int) -> Bool {
    c >= 48 && c <= 57  // '0' to '9'
  }
  
  let is_alphanumeric = fn(c : Int) -> Bool {
    (c >= 48 && c <= 57) ||   // '0' to '9'
    (c >= 65 && c <= 90) ||   // 'A' to 'Z'
    c == 32 || c == 36 || c == 37 || c == 42 ||  // ' ', '$', '%', '*'
    c == 43 || c == 45 || c == 46 || c == 47 || c == 58  // '+', '-', '.', '/', ':'
  }
  
  // Check each character in the string
  let mut all_numeric = true
  let mut all_alphanumeric = true
  
  for i = 0; i < data.length(); i = i + 1 {
    match data.get(i) {
      Some(c) => {
        if not(is_numeric(c)) {
          all_numeric = false
        }
        if not(is_alphanumeric(c)) {
          all_alphanumeric = false
        }
      }
      None => {
        all_numeric = false
        all_alphanumeric = false
      }
    }
  }
  
  if all_numeric {
    Mode::Numeric
  } else if all_alphanumeric {
    Mode::Alphanumeric
  } else {
    Mode::Byte
  }
}

// Note: Alphanumeric values are computed directly in get_alphanumeric_value function

// Get alphanumeric value for character
fn get_alphanumeric_value(c : Int) -> Int {
  if c >= 48 && c <= 57 {  // '0' to '9'
    c - 48
  } else if c >= 65 && c <= 90 {  // 'A' to 'Z'
    c - 65 + 10
  } else {
    match c {
      32 => 36  // space
      36 => 37  // $
      37 => 38  // %
      42 => 39  // *
      43 => 40  // +
      45 => 41  // -
      46 => 42  // .
      47 => 43  // /
      58 => 44  // :
      _ => 0
    }
  }
}

// Encode data in numeric mode
pub fn encode_numeric(data : String) -> Array[Int] {
  let mut result = []
  let mut i = 0
  
  while i < data.length() {
    let mut group = 0
    let mut count = 0
    
    // Process up to 3 digits at a time
    while count < 3 && i < data.length() {
      match data.get(i) {
        Some(c) => {
          if c >= 48 && c <= 57 {  // '0' to '9'
            group = group * 10 + (c - 48)
            count = count + 1
            i = i + 1
          } else {
            break
          }
        }
        None => break
      }
    }
    
    // Add the encoded group
    if count == 3 {
      result = result + [group]  // 10 bits for 3 digits
    } else if count == 2 {
      result = result + [group]  // 7 bits for 2 digits
    } else if count == 1 {
      result = result + [group]  // 4 bits for 1 digit
    }
  }
  
  result
}

// Encode data in alphanumeric mode
pub fn encode_alphanumeric(data : String) -> Array[Int] {
  let mut result = []
  let mut i = 0
  
  while i < data.length() {
    let mut group = 0
    let mut count = 0
    
    // Process up to 2 characters at a time
    while count < 2 && i < data.length() {
      match data.get(i) {
        Some(c) => {
          let value = get_alphanumeric_value(c)
          if count == 0 {
            group = value * 45
          } else {
            group = group + value
          }
          count = count + 1
          i = i + 1
        }
        None => break
      }
    }
    
    // Add the encoded group
    if count == 2 {
      result = result + [group]  // 11 bits for 2 characters
    } else if count == 1 {
      result = result + [group / 45]  // 6 bits for 1 character
    }
  }
  
  result
}

// Encode data in byte mode
pub fn encode_byte(data : String) -> Array[Int] {
  let mut result = []
  
  for i = 0; i < data.length(); i = i + 1 {
    match data.get(i) {
      Some(c) => result = result + [c]  // 8 bits per byte
      None => ()
    }
  }
  
  result
}

// Main encoding function
pub fn encode_data(data : String, mode : Mode) -> Array[Int] {
  match mode {
    Mode::Numeric => encode_numeric(data)
    Mode::Alphanumeric => encode_alphanumeric(data)
    Mode::Byte => encode_byte(data)
    Mode::Kanji => encode_byte(data)  // Simplified: treat as byte mode for now
  }
}

// QR Code Pattern Functions

// Place finder pattern (7x7 square with specific pattern)
fn place_finder_pattern(matrix : Matrix, x : Int, y : Int) -> Unit {
  let pattern = [
    [true, true, true, true, true, true, true],
    [true, false, false, false, false, false, true],
    [true, false, true, true, true, false, true],
    [true, false, true, true, true, false, true],
    [true, false, true, true, true, false, true],
    [true, false, false, false, false, false, true],
    [true, true, true, true, true, true, true]
  ]
  
  for i = 0; i < 7; i = i + 1 {
    for j = 0; j < 7; j = j + 1 {
      let mod = if pattern[i][j] { Module::Dark } else { Module::Light }
      set_module(matrix, x + j, y + i, mod)
    }
  }
}

// Place separator (white border around finder patterns)
fn place_separator(matrix : Matrix, x : Int, y : Int) -> Unit {
  for i = 0; i < 8; i = i + 1 {
    for j = 0; j < 8; j = j + 1 {
      if (i == 0 || i == 7 || j == 0 || j == 7) &&
         x + j >= 0 && x + j < matrix.size && y + i >= 0 && y + i < matrix.size {
        set_module(matrix, x + j, y + i, Module::Light)
      }
    }
  }
}

// Place timing patterns (alternating dark/light modules)
fn place_timing_patterns(matrix : Matrix) -> Unit {
  for i = 8; i < matrix.size - 8; i = i + 1 {
    let mod = if i % 2 == 0 { Module::Dark } else { Module::Light }
    set_module(matrix, i, 6, mod)  // Horizontal timing
    set_module(matrix, 6, i, mod)  // Vertical timing
  }
}

// Place dark module (always at specific position)
fn place_dark_module(matrix : Matrix, version : Version) -> Unit {
  set_module(matrix, 8, 4 * version + 9, Module::Dark)
}

// Initialize QR matrix with patterns
pub fn init_matrix(version : Version) -> Matrix {
  let size = version_to_size(version)
  let matrix = new_matrix(size)
  
  // Place finder patterns
  place_finder_pattern(matrix, 0, 0)                    // Top-left
  place_finder_pattern(matrix, size - 7, 0)             // Top-right
  place_finder_pattern(matrix, 0, size - 7)             // Bottom-left
  
  // Place separators
  place_separator(matrix, -1, -1)                       // Top-left
  place_separator(matrix, size - 8, -1)                 // Top-right
  place_separator(matrix, -1, size - 8)                 // Bottom-left
  
  // Place timing patterns
  place_timing_patterns(matrix)
  
  // Place dark module
  place_dark_module(matrix, version)
  
  matrix
}

// Simple data placement (zigzag pattern)
fn place_data(matrix : Matrix, data : Array[Int]) -> Unit {
  let mut data_index = 0
  let mut up = true
  let mut col = matrix.size - 1
  
  while col > 0 {
    if col == 6 { col = col - 1 }  // Skip timing column
    
    for i = 0; i < matrix.size; i = i + 1 {
      let row = if up { matrix.size - 1 - i } else { i }
      
      for c = 0; c < 2; c = c + 1 {
        let x = col - c
        
        // Check if position is available (not a function pattern)
        if is_data_position(matrix, x, row) && data_index < data.length() {
          let bit = if data_index < data.length() { data[data_index] } else { 0 }
          let mod = if bit != 0 { Module::Dark } else { Module::Light }
          set_module(matrix, x, row, mod)
          data_index = data_index + 1
        }
      }
    }
    
    up = not(up)
    col = col - 2
  }
}

// Check if position is available for data (not occupied by function patterns)
fn is_data_position(matrix : Matrix, x : Int, y : Int) -> Bool {
  let size = matrix.size
  
  // Check finder patterns and separators
  if (x < 9 && y < 9) ||                           // Top-left
     (x >= size - 8 && y < 9) ||                   // Top-right  
     (x < 9 && y >= size - 8) {                    // Bottom-left
    false
  } else if x == 6 || y == 6 {                     // Timing patterns
    false
  } else if x == 8 && y >= size - 7 {              // Dark module area
    false
  } else {
    true
  }
}

// Main QR code generation function
pub fn generate_qr(data : String, error_correction : ErrorCorrectionLevel) -> QRCode {
  let mode = detect_mode(data)
  let version = 1  // Start with version 1 for simplicity
  let matrix = init_matrix(version)
  let encoded_data = encode_data(data, mode)
  
  // Apply Reed-Solomon error correction
  let corrected_data = apply_error_correction(encoded_data, mode, version, error_correction)
  
  // Convert corrected data to bits for placement
  let mut bit_data = []
  for codeword in corrected_data {
    for bit = 7; bit >= 0; bit = bit - 1 {
      bit_data = bit_data + [(codeword >> bit) & 1]
    }
  }
  
  // Place corrected data in matrix
  place_data(matrix, bit_data)
  
  { version, error_correction, mode, data, matrix }
}

// Simple API functions

// Generate QR code with default error correction level (M)
pub fn encode(data : String) -> QRCode {
  generate_qr(data, ErrorCorrectionLevel::M)
}

// Generate QR code with specific error correction level
pub fn encode_with_ec(data : String, ec : ErrorCorrectionLevel) -> QRCode {
  generate_qr(data, ec)
}

// Generate QR code with specific mode and error correction level
pub fn encode_with_mode_and_ec(data : String, mode : Mode, version : Version, ec : ErrorCorrectionLevel) -> QRCode {
  let matrix = init_matrix(version)
  let encoded_data = encode_data(data, mode)
  
  // Apply Reed-Solomon error correction
  let corrected_data = apply_error_correction(encoded_data, mode, version, ec)
  
  // Convert corrected data to bits for placement
  let mut bit_data = []
  for codeword in corrected_data {
    for bit = 7; bit >= 0; bit = bit - 1 {
      bit_data = bit_data + [(codeword >> bit) & 1]
    }
  }
  
  // Place corrected data in matrix
  place_data(matrix, bit_data)
  
  { version, error_correction: ec, mode, data, matrix }
}

// Reed-Solomon Error Correction Implementation

// Galois Field arithmetic for GF(256)
let gf_exp = [
  1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38,
  76, 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192,
  157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119, 238, 193, 159, 35,
  70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, 222, 161,
  95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240,
  253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226,
  217, 175, 67, 134, 17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206,
  129, 31, 62, 124, 248, 237, 199, 147, 59, 118, 236, 197, 151, 51, 102, 204,
  133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66, 132, 21, 42, 84,
  168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115,
  230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255,
  227, 219, 171, 75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65,
  130, 25, 50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166,
  81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9,
  18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22,
  44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142, 1
]

let gf_log = [
  0, 0, 1, 25, 2, 50, 26, 198, 3, 223, 51, 238, 27, 104, 199, 75,
  4, 100, 224, 14, 52, 141, 239, 129, 28, 193, 105, 248, 200, 8, 76, 113,
  5, 138, 101, 47, 225, 36, 15, 33, 53, 147, 142, 218, 240, 18, 130, 69,
  29, 181, 194, 125, 106, 39, 249, 185, 201, 154, 9, 120, 77, 228, 114, 166,
  6, 191, 139, 98, 102, 221, 48, 253, 226, 152, 37, 179, 16, 145, 34, 136,
  54, 208, 148, 206, 143, 150, 219, 189, 241, 210, 19, 92, 131, 56, 70, 64,
  30, 66, 182, 163, 195, 72, 126, 110, 107, 58, 40, 84, 250, 133, 186, 61,
  202, 94, 155, 159, 10, 21, 121, 43, 78, 212, 229, 172, 115, 243, 167, 87,
  7, 112, 192, 247, 140, 128, 99, 13, 103, 74, 222, 237, 49, 197, 254, 24,
  227, 165, 153, 119, 38, 184, 180, 124, 17, 68, 146, 217, 35, 32, 137, 46,
  55, 63, 209, 91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190, 97,
  242, 86, 211, 171, 20, 42, 93, 158, 132, 60, 57, 83, 71, 109, 65, 162,
  31, 45, 67, 216, 183, 123, 164, 118, 196, 23, 73, 236, 127, 12, 111, 246,
  108, 161, 59, 82, 41, 157, 85, 170, 251, 96, 134, 177, 187, 204, 62, 90,
  203, 89, 95, 176, 156, 169, 160, 81, 11, 245, 22, 235, 122, 117, 44, 215,
  79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168, 80, 88, 175
]

// Galois field multiplication
pub fn gf_mul(a : Int, b : Int) -> Int {
  if a == 0 || b == 0 || a >= 256 || b >= 256 || a < 0 || b < 0 {
    0
  } else {
    let log_sum = (gf_log[a] + gf_log[b]) % 255
    gf_exp[log_sum]
  }
}

// Galois field division
pub fn gf_div(a : Int, b : Int) -> Int {
  if a == 0 || a >= 256 || a < 0 {
    0
  } else if b == 0 || b >= 256 || b < 0 {
    abort("Division by zero or invalid value in GF")
  } else {
    let log_diff = (gf_log[a] - gf_log[b] + 255) % 255
    gf_exp[log_diff]
  }
}

// Generate Reed-Solomon generator polynomial
fn rs_generator_poly(nsym : Int) -> Array[Int] {
  let mut g = [1]
  for i = 0; i < nsym; i = i + 1 {
    let new_g = Array::make(g.length() + 1, 0)
    for j = 0; j < g.length(); j = j + 1 {
      let exp_val = if i < gf_exp.length() { gf_exp[i] } else { 1 }
      new_g[j] = new_g[j] ^ gf_mul(g[j], exp_val)
      if j + 1 < new_g.length() {
        new_g[j + 1] = new_g[j + 1] ^ g[j]
      }
    }
    g = new_g
  }
  g
}

// Reed-Solomon encoding
fn rs_encode(data : Array[Int], nsym : Int) -> Array[Int] {
  let gen = rs_generator_poly(nsym)
  let result = Array::make(data.length() + nsym, 0)
  
  // Copy data to result
  for i = 0; i < data.length(); i = i + 1 {
    result[i] = data[i]
  }
  
  // Perform polynomial division
  for i = 0; i < data.length(); i = i + 1 {
    let coef = result[i]
    if coef != 0 {
      for j = 1; j < gen.length(); j = j + 1 {
        if i + j < result.length() {
          result[i + j] = result[i + j] ^ gf_mul(gen[j], coef)
        }
      }
    }
  }
  
  result
}

// Get error correction codewords count for each level and version
pub fn get_error_correction_codewords(version : Version, ec_level : ErrorCorrectionLevel) -> Int {
  // Simplified table for version 1 only
  let _ = version  // Suppress unused warning
  match ec_level {
    ErrorCorrectionLevel::L => 7   // 7 error correction codewords
    ErrorCorrectionLevel::M => 10  // 10 error correction codewords  
    ErrorCorrectionLevel::Q => 13  // 13 error correction codewords
    ErrorCorrectionLevel::H => 17  // 17 error correction codewords
  }
}

// Get total data capacity for version and error correction level
fn get_data_capacity(version : Version, ec_level : ErrorCorrectionLevel) -> Int {
  // Total capacity for version 1 is 26 bytes
  let total_capacity = 26
  let ec_codewords = get_error_correction_codewords(version, ec_level)
  total_capacity - ec_codewords
}

// Convert data to codewords with proper formatting
fn format_data_codewords(data : Array[Int], mode : Mode, data_length : Int, capacity : Int) -> Array[Int] {
  let mut codewords = []
  
  // Add mode indicator (4 bits)
  let mode_indicator = match mode {
    Mode::Numeric => 1
    Mode::Alphanumeric => 2  
    Mode::Byte => 4
    Mode::Kanji => 8
  }
  codewords = codewords + [mode_indicator << 4]
  
  // Add character count indicator (simplified for version 1)
  let _count_bits = match mode {
    Mode::Numeric => 10
    Mode::Alphanumeric => 9
    Mode::Byte => 8
    Mode::Kanji => 8
  }
  
  // For simplicity, pack data length into next codeword
  if codewords.length() > 0 {
    codewords[0] = codewords[0] | ((data_length >> 4) & 0x0F)
  }
  codewords = codewords + [(data_length << 4) & 0xF0]
  
  // Add data codewords
  codewords = codewords + data
  
  // Add terminator (0000) if space allows
  if codewords.length() < capacity {
    codewords = codewords + [0]
  }
  
  // Pad to required capacity with alternating pad bytes
  let mut pad_byte = 0xEC
  while codewords.length() < capacity {
    codewords = codewords + [pad_byte]
    pad_byte = if pad_byte == 0xEC { 0x11 } else { 0xEC }
  }
  
  codewords
}

// Apply Reed-Solomon error correction to data
pub fn apply_error_correction(data : Array[Int], mode : Mode, version : Version, ec_level : ErrorCorrectionLevel) -> Array[Int] {
  let capacity = get_data_capacity(version, ec_level)
  let ec_codewords = get_error_correction_codewords(version, ec_level)
  
  // Format data into proper codewords
  let formatted_data = format_data_codewords(data, mode, data.length(), capacity)
  
  // Apply Reed-Solomon encoding
  let encoded = rs_encode(formatted_data, ec_codewords)
  
  encoded
}

// Helper functions for tests to create enum values
pub fn make_byte_mode() -> Mode { Mode::Byte }
pub fn make_kanji_mode() -> Mode { Mode::Kanji }
pub fn make_ec_level_l() -> ErrorCorrectionLevel { ErrorCorrectionLevel::L }
pub fn make_ec_level_m() -> ErrorCorrectionLevel { ErrorCorrectionLevel::M }
pub fn make_ec_level_q() -> ErrorCorrectionLevel { ErrorCorrectionLevel::Q }
pub fn make_ec_level_h() -> ErrorCorrectionLevel { ErrorCorrectionLevel::H }
