// Example usage of the QR code library

fn main() {
  // Generate a QR code
  let qr = @bobzhang/qrc.encode("Hello, MoonBit!")
  
  // Print QR code information
  println(@bobzhang/qrc/render.info(qr))
  
  // Print QR code as text
  println("Text representation:")
  println(@bobzhang/qrc/render.to_text(qr))
  
  // Print QR code as compact text
  println("Compact representation:")
  println(@bobzhang/qrc/render.to_compact_text(qr))
}
