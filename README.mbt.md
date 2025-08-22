# qrc — QR code encoder for MoonBit

Qrc encodes your data into QR codes. It has built-in QR matrix renderers for SVG, ANSI terminal and text.

This is a MoonBit port of the original [OCaml qrc library](https://github.com/dbuenzli/qrc) by Daniel Bünzli.

## Features

- ✅ QR code encoding with multiple data modes (numeric, alphanumeric, byte)
- ✅ Automatic mode detection
- ✅ Multiple output formats: SVG, ANSI terminal, plain text, compact text
- ✅ Reed-Solomon error correction with Galois Field arithmetic
- ✅ No external dependencies
- ✅ WebAssembly compatible
- ⚠️ Kanji mode (treated as byte mode)

## Installation

```bash
moon install bobzhang/qrc
```

## Usage

### Basic Usage

```moonbit
test {
  // Generate a QR code with default settings
  let qr = @bobzhang/qrc.encode("Hello, MoonBit!")

  // Print QR code information
  println(@bobzhang/qrc/render.info(qr))

  // Render as text
  println(@bobzhang/qrc/render.to_text(qr))

  // Render as compact text (using Unicode block characters)
  println(@bobzhang/qrc/render.to_compact_text(qr))

  // Render as SVG
  let svg = @bobzhang/qrc/render.to_svg(qr)
  println(svg)

  // Render as ANSI terminal output (with colors)
  println(@bobzhang/qrc/render.to_ansi(qr))
}
```

### Advanced Usage

```moonbit
test {
  // Generate QR code with specific error correction level
  let qr = @qrc.encode_with_ec("Important data", H)

  // Manual mode detection
  let mode = @qrc.detect_mode("12345") // Returns Mode::Numeric
  let mode2 = @qrc.detect_mode("HELLO WORLD") // Returns Mode::Alphanumeric
  let mode3 = @qrc.detect_mode("Hello, World!")
   // Returns Mode::Byte
}
```

### Data Modes

The library automatically detects the best encoding mode:

- **Numeric**: Only digits 0-9 (most efficient for numbers)
- **Alphanumeric**: Digits, uppercase letters A-Z, and symbols ` $%*+-./:` 
- **Byte**: Any data (UTF-8 encoded)
- **Kanji**: Japanese characters (currently treated as byte mode)

### Error Correction Levels

- **L**: ~7% correction capability
- **M**: ~15% correction capability (default)
- **Q**: ~25% correction capability  
- **H**: ~30% correction capability

## Example Output

```
QR Code Information:
Version: 1
Size: 21x21
Mode: Byte
Error Correction: M (~15%)
Data: "Hello, MoonBit!"

Text representation:
██████████████  ████  ██████████████
██          ██  ████  ██          ██
██  ██████  ██  ████  ██  ██████  ██
██  ██████  ██  ████  ██  ██████  ██
██  ██████  ██  ████  ██  ██████  ██
██          ██  ████  ██          ██
██████████████  ████  ██████████████
                ████                
████████████████████████████████████
...
```

## API Reference

### Core Functions

- `encode(data: String) -> QRCode` - Generate QR code with default error correction
- `encode_with_ec(data: String, ec: ErrorCorrectionLevel) -> QRCode` - Generate QR code with specific error correction
- `detect_mode(data: String) -> Mode` - Detect the best encoding mode for data

### Rendering Functions

- `@render.to_text(qr: QRCode) -> String` - Plain text representation
- `@render.to_compact_text(qr: QRCode) -> String` - Compact Unicode representation
- `@render.to_svg(qr: QRCode) -> String` - SVG format
- `@render.to_ansi(qr: QRCode) -> String` - ANSI terminal with colors
- `@render.info(qr: QRCode) -> String` - QR code information

## Running the Example

```bash
# Clone the repository
git clone <repository-url>
cd qrc

# Run tests
moon test

# Run the example
moon run src
```

## Limitations

This is a functional implementation demonstrating MoonBit capabilities:

- ✅ Full Reed-Solomon error correction with proper Galois Field arithmetic
- ✅ Supports all error correction levels (L, M, Q, H)
- ✅ Proper data formatting with mode indicators and padding
- ✅ QR version 1 (21x21 modules) with finder patterns and timing patterns
- ⚠️ Kanji mode is treated as byte mode
- ⚠️ No format information or version information encoding
- ⚠️ No masking patterns applied

The Reed-Solomon implementation includes:
- Complete GF(256) Galois Field arithmetic
- Generator polynomial computation
- Proper error correction codeword generation
- Data capacity management for different error correction levels

For production use with higher versions and advanced features, consider extending this implementation.

## Contributing

This project demonstrates porting OCaml code to MoonBit. Contributions to improve the implementation are welcome!

## License

ISC License - same as the original OCaml library.

## Acknowledgments

- Original [OCaml qrc library](https://github.com/dbuenzli/qrc) by Daniel Bünzli
- MoonBit language team for the excellent tooling and documentation