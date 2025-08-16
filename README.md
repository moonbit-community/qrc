# qrc — QR code encoder for MoonBit

Qrc encodes your data into QR codes. It has built-in QR matrix renderers for SVG, ANSI terminal and text.

This is a MoonBit port of the original [OCaml qrc library](https://github.com/dbuenzli/qrc) by Daniel Bünzli.

## Features

- ✅ QR code encoding with multiple data modes (numeric, alphanumeric, byte)
- ✅ Automatic mode detection
- ✅ Multiple output formats: SVG, ANSI terminal, plain text, compact text
- ✅ No external dependencies
- ✅ WebAssembly compatible
- ⚠️ Reed-Solomon error correction (simplified implementation)
- ⚠️ Kanji mode (treated as byte mode)

## Installation

```bash
moon install username/qrc
```

## Usage

### Basic Usage

```moonbit
// Generate a QR code with default settings
let qr = @lib.encode("Hello, MoonBit!")

// Print QR code information
println(@render.info(qr))

// Render as text
println(@render.to_text(qr))

// Render as compact text (using Unicode block characters)
println(@render.to_compact_text(qr))

// Render as SVG
let svg = @render.to_svg(qr)
println(svg)

// Render as ANSI terminal output (with colors)
println(@render.to_ansi(qr))
```

### Advanced Usage

```moonbit
// Generate QR code with specific error correction level
let qr = @lib.encode_with_ec("Important data", @lib.ErrorCorrectionLevel::H)

// Manual mode detection
let mode = @lib.detect_mode("12345")  // Returns Mode::Numeric
let mode2 = @lib.detect_mode("HELLO WORLD")  // Returns Mode::Alphanumeric
let mode3 = @lib.detect_mode("Hello, World!")  // Returns Mode::Byte
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

This is a basic implementation focused on demonstrating MoonBit capabilities:

- Only supports QR version 1 (21x21 modules)
- Simplified error correction (data is placed without Reed-Solomon codes)
- Kanji mode is treated as byte mode
- No format information or version information encoding
- No masking patterns applied

For production use, consider using a more complete QR code library.

## Contributing

This project demonstrates porting OCaml code to MoonBit. Contributions to improve the implementation are welcome!

## License

ISC License - same as the original OCaml library.

## Acknowledgments

- Original [OCaml qrc library](https://github.com/dbuenzli/qrc) by Daniel Bünzli
- MoonBit language team for the excellent tooling and documentation