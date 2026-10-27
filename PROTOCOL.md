# AJ139 V2 MC HID protocol

Notes on the vendor protocol used by the mouse. Everything here was checked against a real device.

## Device

| Mode | VID | PID |
|------|-----|-----|
| USB cable | `A8A4` | `2255` |
| 2.4 GHz receiver | `A8A5` | `2255` |

The configuration interface is the HID collection with usage page `0xFF01`, usage `0x10`.
Reports have no report ID and are 64 bytes in both directions.

## Packet format

Request:

```
55 CMD HEAD CHK LEN 00 00 00 ...
```

- `HEAD` is `A5` for reads and `AE` for configuration writes.
- `CHK` is the low byte of the sum of bytes 4 to 63.

Response:

```
AA CMD HEAD ...
```

The mouse also sends unsolicited `AA FA ...` reports. Skip anything whose second byte is not the command you sent.

## Commands

| CMD | LEN | Purpose |
|-----|-----|---------|
| `30` | `2E` | Battery. Byte 8 is the level in percent, byte 9 is non-zero while on USB power. |
| `0E` | `30` | Read the configuration block. |
| `0F` | `30` | Write the configuration block (`HEAD = AE`). Acknowledged with `AA 0F AE`. |
| `21` | `03` | Lighting mode, byte 10 = 0 to 6. Stored, but has no visible effect on this model. |

## Configuration block

Offsets are into the 64 byte `0E` response. To write, take the block, set bytes 0 to 7 to
`55 0F AE CHK 30 00 00 00` and send it back.

| Offset | Size | Field |
|--------|------|-------|
| 9 | 1 | Lighting mode |
| 10 | 1 | Polling rate code |
| 11 | 1 | Number of DPI stages (6) |
| 12 | 1 | Active DPI stage, 1 based |
| 13 | 12 | Six DPI values, `uint16` little endian, 50 to 26000 |
| 25 | 18 | Six RGB triplets for the DPI indicator. Ignored by this model, always read back as zero. |
| 48 | 1 | Scroll flag |
