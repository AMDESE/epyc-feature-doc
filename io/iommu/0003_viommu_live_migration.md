# Live Migration Support with Emulated AMD IOMMU

## Introduction

This guide covers live migration support for VMs with emulated AMD IOMMU.

For more information please refer [QEMU Live Migration](https://www.qemu.org/docs/master/devel/migration/index.html)

### Guest Live Migration

Guest live migration enables transparently moving a running VM including its complete state from a
source VM to a destination VM with minimal or no downtime.

<pre>
                    +-----------+            +----------------+
                    | Source VM |  ------->  | Destination VM |
                    |  (Host A) |            |    (Host A)    |
                    +-----------+            +----------------+
                           a. Local Migration (Intra host)


                   +-----------+   Network    +----------------+
                   | Source VM |  --------->  | Destination VM |
                   |  (Host A) |              |    (Host B)    |
                   +-----------+              +----------------+
                        b. Across-Host Migration (Inter hosts)
</pre>

<br>Note: For guest live migration, source and destination VM should have same QEMU command line options.
          This ensures that the VM's hardware configuration, device models, and memory layout remain
          consistent during migration, preventing incompatibility or migration failures.

## Enabling Live Migration support with emulated AMD IOMMU

Live migration of guests with emulated AMD IOMMU has been supported since QEMU version v10.1.0. The
support is added for saving and restoring MMIO registers, device table, command buffers, and event
buffers during migration. In addition, the ability to specify PCI topology for the AMD IOMMU device
ensures consistent device enumeration across source and destination VMs. The following commit
introduces these changes to enable live migration with emulated AMD IOMMU:

QEMU Commits:
* 28931c2e1591d ("hw/i386/amd_iommu: Allow migration when explicitly create the AMDVI-PCI device")
* f864a3235ea1d ("hw/i386/amd_iommu: Isolate AMDVI-PCI from amd-iommu device to allow full control over the PCI device creation")

