// QR Code Renderers for different output formats

// Render QR code as plain text (ASCII)
pub fn to_text(qr : @lib.QRCode) -> String {
  let mut result = ""
  let matrix = qr.matrix
  
  for y = 0; y < matrix.size; y = y + 1 {
    for x = 0; x < matrix.size; x = x + 1 {
      match @lib.get_module(matrix, x, y) {
        @lib.Module::Dark => result = result + "██"
        @lib.Module::Light => result = result + "  "
      }
    }
    result = result + "\n"
  }
  
  result
}

// Render QR code as ANSI terminal output (with colors)
pub fn to_ansi(qr : @lib.QRCode) -> String {
  let mut result = ""
  let matrix = qr.matrix
  
  for y = 0; y < matrix.size; y = y + 1 {
    for x = 0; x < matrix.size; x = x + 1 {
      match @lib.get_module(matrix, x, y) {
        @lib.Module::Dark => result = result + "\u001b[40m  \u001b[0m"  // Black background
        @lib.Module::Light => result = result + "\u001b[47m  \u001b[0m" // White background
      }
    }
    result = result + "\n"
  }
  
  result
}

// Render QR code as SVG
pub fn to_svg(qr : @lib.QRCode) -> String {
  let matrix = qr.matrix
  let size = matrix.size
  let scale = 10  // Each module is 10x10 pixels
  let svg_size = size * scale
  
  let mut result = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
  result = result + "<svg xmlns=\"http://www.w3.org/2000/svg\" "
  result = result + "width=\"" + svg_size.to_string() + "\" "
  result = result + "height=\"" + svg_size.to_string() + "\" "
  result = result + "viewBox=\"0 0 " + svg_size.to_string() + " " + svg_size.to_string() + "\">\n"
  
  // White background
  result = result + "<rect width=\"" + svg_size.to_string() + "\" "
  result = result + "height=\"" + svg_size.to_string() + "\" fill=\"white\"/>\n"
  
  // Draw dark modules
  for y = 0; y < size; y = y + 1 {
    for x = 0; x < size; x = x + 1 {
      match @lib.get_module(matrix, x, y) {
        @lib.Module::Dark => {
          let px = x * scale
          let py = y * scale
          result = result + "<rect x=\"" + px.to_string() + "\" "
          result = result + "y=\"" + py.to_string() + "\" "
          result = result + "width=\"" + scale.to_string() + "\" "
          result = result + "height=\"" + scale.to_string() + "\" fill=\"black\"/>\n"
        }
        @lib.Module::Light => ()
      }
    }
  }
  
  result = result + "</svg>\n"
  result
}

// Render QR code as compact text (using Unicode block characters)
pub fn to_compact_text(qr : @lib.QRCode) -> String {
  let mut result = ""
  let matrix = qr.matrix
  
  // Process two rows at a time to use half-block characters
  for y = 0; y < matrix.size; y = y + 2 {
    for x = 0; x < matrix.size; x = x + 1 {
      let top = match @lib.get_module(matrix, x, y) {
        @lib.Module::Dark => true
        @lib.Module::Light => false
      }
      
      let bottom = if y + 1 < matrix.size {
        match @lib.get_module(matrix, x, y + 1) {
          @lib.Module::Dark => true
          @lib.Module::Light => false
        }
      } else {
        false
      }
      
      // Choose appropriate Unicode block character
      let char = match (top, bottom) {
        (false, false) => " "   // Both light
        (true, false) => "▀"    // Top dark, bottom light
        (false, true) => "▄"    // Top light, bottom dark
        (true, true) => "█"     // Both dark
      }
      
      result = result + char
    }
    result = result + "\n"
  }
  
  result
}

// Get QR code information as string
pub fn info(qr : @lib.QRCode) -> String {
  let mode_str = match qr.mode {
    @lib.Mode::Numeric => "Numeric"
    @lib.Mode::Alphanumeric => "Alphanumeric"
    @lib.Mode::Byte => "Byte"
    @lib.Mode::Kanji => "Kanji"
  }
  
  let ec_str = match qr.error_correction {
    @lib.ErrorCorrectionLevel::L => "L (~7%)"
    @lib.ErrorCorrectionLevel::M => "M (~15%)"
    @lib.ErrorCorrectionLevel::Q => "Q (~25%)"
    @lib.ErrorCorrectionLevel::H => "H (~30%)"
  }
  
  "QR Code Information:\n" +
  "Version: " + qr.version.to_string() + "\n" +
  "Size: " + qr.matrix.size.to_string() + "x" + qr.matrix.size.to_string() + "\n" +
  "Mode: " + mode_str + "\n" +
  "Error Correction: " + ec_str + "\n" +
  "Data: \"" + qr.data + "\"\n"
}
