<p align="center">
  <img src="docs/logo.png" width="128" alt="AJ139 Driver icon">
</p>

<h1 align="center">AJ139 Driver</h1>

<p align="center">
  A small native macOS app for the AJAZZ AJ139 V2 MC mouse.<br>
  The official software is Windows only, so I wrote this one.
</p>

<p align="center">
  <img src="docs/demo.gif" width="460" alt="Demo">
</p>

## Features

- Battery level and charging state
- Six DPI stages, 50 to 26000 DPI
- Pick the active DPI stage
- Settings are saved on the mouse, so they also work on other computers
- English and Turkish interface
- No drivers or kernel extensions, it talks to the mouse over standard HID

## Install

1. Download `AJ139-Driver.zip` from the [latest release](https://github.com/werquess/ajazz-aj139-macos/releases/latest).
2. Unzip it and move **AJ139 Driver.app** to your Applications folder.
3. The app is not notarized. The first time, right click it and choose **Open**, or run:

   ```bash
   xattr -dr com.apple.quarantine "/Applications/AJ139 Driver.app"
   ```

Requires macOS 14 or later. Tested on Apple silicon with the mouse connected over USB.

## Build from source

```bash
git clone https://github.com/werquess/ajazz-aj139-macos.git
cd ajazz-aj139-macos
./build.sh
```

The app ends up in `build/`. Only the Xcode command line tools are needed.

## Notes

- The protocol is documented in [PROTOCOL.md](PROTOCOL.md).
- The mouse accepts DPI indicator colors but does not store them, so there is no color setting.
- Bluetooth mode has not been tested.

## Support

If this saved you from booting Windows, you can [buy me a coffee](https://buymeacoffee.com/werquess).

## License

[MIT](LICENSE)
