# Emulated AMD IOMMU (SW-vIOMMU)

## Introduction
Document describes emulated AMD IOMMU features that includes support for x2apic mode through 128-bit
Interrupt Remapping (GASup) and XT feature (XTSup), and outlines the corresponding upstream support.

## Description
The emulated AMD IOMMU, also known as SW-vIOMMU, provides a virtualized IOMMU to the guest, emulated
by QEMU. This virtual model closely replicates real IOMMU hardware behavior, including page table
translation, interrupt remapping, TLB flush and invalidation, and passthrough support to VMs etc.

In order to support guest boot with more than 255 vCPUs in x2apic mode, the emulated AMD IOMMU
provides 128-bit Interrupt Remapping (GASup) and XT feature (XTSup) support.

<pre>


+------------------------------------------------------------------------------------+
|  +--------------------------+       Host System                                    |
|  |           QEMU           |                                                      |
|  |                          |                                                      |
|  | +----------------------+ |                                                      |
|  | | Emulated AMD IOMMU   | |                                                      |
|  | |    (SW-vIOMMU)       | |                                                      |
|  | |                      | |                                                      |
|  | |+-------------------+ | |                     +-----------------------------+  |
|  | || IRQ Remapping Unit| | |                     |        Guest VM             |  |
|  | ||  (GASup / XTSup)  | | | (virtio stub, etc.) | +-------------------------+ |  |
|  | |+-------------------+ | |-------------------->| | Guest OS / Driver       | |  |
|  | +---------^------------+ |                     | |  - Sees AMD IOMMU (IVRS)| |  |
|  |           |              |                     | |  - Programs IRT Table   | |  |
|  |           |              |                     | +-------------------------+ |  |
|  |           |              |                     +-----------------------------+  |
|  | +---------v-----------+  |                                                      |
|  | |Virtual PCI Device(s)|  |                                                      |
|  | +---------------------+  |                                                      |
|  +--------------------------+                                                      |
+------------------------------------------------------------------------------------+


</pre>

1. 128-bit Interrupt Remapping Support (GASup)
    * Enables 128-bit Interrupt Remapping Table Entries (IRTEs) with extended 32-bit destination
    field, required to support apic ids greater than 255 in x2apic mode.

2. XT Feature Support (XTSup)
    * Provides extended interrupt translation capabilities for x2apic mode, ensuring correct routing
    and delivery of interrupts to vCPUs with apic ids greater than 255, supporting guest boot with
    more than 255 vCPUs

## Patches

### QEMU - XTSup emulation

Patched to support x2apic, which is a prerequisite to support emulated IOMMU, has been available in
QEMU since vv9.0.0. The following patches will add support for the AMD IOMMU "XTSup" which allows
guest to launch with more than 255 vCPU.

QEMU Commits:

* b2101358e591 i386/tcg: implement x2APIC registers MSR access
* b5ee0468e9d2 apic: add support for x2APIC mode
* 774204cf9874 apic, i386/tcg: add x2apic transitions
* 2cf16205290b intel_iommu: allow Extended Interrupt Mode when using userspace APIC
* 595cd6fd9dff test: bios-tables-test: prepare IVRS change in ACPI table
* 328a11a08a70 amd_iommu: report x2APIC support to the operating system
* 7618fffdf16e test: bios-tables-test: add IVRS changed binary

