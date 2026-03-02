# AMD IOMMU Debugfs Support

## Overview

AMD IOMMU debugfs support provides interfaces to dump various IOMMU internal data
structures and registers for debugging and analysis purposes. This allows developers
and system administrators to inspect IOMMU hardware state, configuration, and data
structures without requiring specialized debugging tools.

## Significance

### Without Debugfs Support

Debugging AMD IOMMU-related issues was challenging due to:

- **Limited Visibility**: No direct way to inspect IOMMU internal state at runtime
- **Complex Debugging**: Required instrumenting kernel, hardware debuggers, or crash dump analysis
- **Device-Specific Issues**: Difficult to track problems with specific devices

### With Debugfs Support

The debugfs interface provides:

- **Runtime Inspection**: Real-time access to IOMMU registers and data structures
- **Per-Device Analysis**: Examine IOMMU configuration for specific devices using PCI identifiers
- **Interrupt Remapping Debug**: Access to Interrupt Remapping Table (IRT) entries
- **Hardware State**: Direct access to MMIO registers, capability registers, and command buffer

## Supported Data Structures

| Data Structure             | Description                                                           |
|----------------------------|-----------------------------------------------------------------------|
| MMIO Registers             | IOMMU Memory-Mapped I/O registers for hardware configuration and state|
| Capability Registers       | IOMMU capability registers (PCI config space, range 0x00-0x14)        |
| Command Buffer             | Circular buffer for driver-to-IOMMU commands with head/tail pointers  |
| Device Table               | Per-device IOMMU configuration entries (DTE), 256 bits per device     |
| Interrupt Remapping Table  | IRTE entries for devices (32-bit legacy or 128-bit VAPIC/GA mode)     |

## Design Description

### Debugfs Directory Structure

```
/sys/kernel/debug/iommu/amd/
|-- iommu00/                    # Per-IOMMU directory
|    |-- mmio                   # MMIO register dump (read/write)
|    |-- capability             # Capability register dump (read/write)
|    |-- cmdbuf                 # Command buffer dump (read-only)
|-- iommu01/
|    |-- ...
|-- devid                       # Device ID input (read/write)
|-- devtbl                      # Device table dump (read-only)
|-- irqtbl                      # IRT table dump (read-only)
```

### Debugfs Files

#### Per-IOMMU Files

| File         | Access     | Description                                         |
|--------------|------------|-----------------------------------------------------|
| `mmio`       | Read/Write | Write offset, read MMIO register value              |
| `capability` | Read/Write | Write offset (0x00-0x14), read capability register  |
| `cmdbuf`     | Read-only  | Dump command buffer with head/tail pointers         |

#### Global Files

| File     | Access     | Description                                             |
|----------|------------|---------------------------------------------------------|
| `devid`  | Read/Write | Set device ID (format: `SSSS:BB:DD.F` or `BB:DD.F`)     |
| `devtbl` | Read-only  | Dump Device Table Entry for selected device             |
| `irqtbl` | Read-only  | Dump valid IRT entries for selected device              |


## Support

### Kernel Version

```
Upstream Linux v6.19 and onwards
```

## Enablement

### Kernel Configuration

```
CONFIG_IOMMU_DEBUGFS=y
CONFIG_AMD_IOMMU_DEBUGFS=y
```

### Upstream Commits

| Commit           | Title                                                             |
|------------------|-------------------------------------------------------------------|
| `ad48b1dd14fb`   | iommu/amd: Refactor AMD IOMMU debugfs initial setup               |
| `7a4ee419e8c1`   | iommu/amd: Add debugfs support to dump IOMMU MMIO registers       |
| `4d9c5d5a1dc9`   | iommu/amd: Add debugfs support to dump IOMMU Capability registers |
| `fb3af1f4fefb`   | iommu/amd: Add debugfs support to dump IOMMU command buffer       |
| `2e98940f123d`   | iommu/amd: Add support for device id user input                   |
| `b48457782445`   | iommu/amd: Add debugfs support to dump device table               |
| `349ad6d5263a`   | iommu/amd: Add debugfs support to dump IRT Table                  |
| `39215bb3b0d9`   | iommu/amd: Add documentation for AMD IOMMU debugfs support        |

### Usage Examples

For detailed usage examples and expected output format, refer to kernel ABI documentation:

- linux/Documentation/ABI/testing/debugfs-amd-iommu [AMD IOMMU debugfs ABI documentation](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/ABI/testing/debugfs-amd-iommu?h=v6.19)

## Reference

- [AMD IOMMU Specification](https://docs.amd.com/v/u/en-US/48882_3.10_PUB)
- [AMD IOMMU debugfs ABI documentation](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/ABI/testing/debugfs-amd-iommu?h=v6.19)
