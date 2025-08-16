// Example usage of the QR code library

fn main() -> Unit {
  // Generate a QR code
  let qr = @lib.encode("Hello, MoonBit!")
  
  // Print QR code information
  println(@render.info(qr))
  
  // Print QR code as text
  println("Text representation:")
  println(@render.to_text(qr))
  
  // Print QR code as compact text
  println("Compact representation:")
  println(@render.to_compact_text(qr))
}
