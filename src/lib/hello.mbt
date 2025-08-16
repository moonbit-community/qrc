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

// Alphanumeric character values for encoding
let alphanumeric_values = [
  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, // A-P
  26, 27, 28, 29, 30, 31, 32, 33, 34, 35, // Q-Z
  36, 37, 38, 39, 40, 41, 42, 43, 44 // space, $, %, *, +, -, ., /, :
]

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
  
  // For now, place data directly without error correction
  place_data(matrix, encoded_data)
  
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
