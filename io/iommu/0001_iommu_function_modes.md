# IOMMU Kernel Configuration Modes

## Introduction
This document provides a high-level overview of AMD IOMMU DMA and interrupt remapping features,
the kernel's default configuration for these features, and methods to enable or disable them via
kernel command-line options.

## Terminology

* **DMA** - Direct Memory Access. Allows devices to access system memory without CPU intervention.
* **IOMMU** - Input/Output Memory Management Unit. For more details
  [IOMMU specification](https://docs.amd.com/v/u/en-US/48882_3.10_PUB)
* **IOVA** - I/O Virtual Address. The address seen by a device, translated by the IOMMU.
* **SPA** - System Physical Address.
* **IRQ** - Device generated interrupt to be serviced by CPU.
* **IRT** - Interrupt remapping table, managed by IOMMU for Interrupt Remapping feature.

## DMA Remapping
AMD IOMMU provides DMA remapping, which translates device-generated addresses (I/O Virtual Address
or IOVA) to system physical addresses (SPA), isolating devices and protecting memory from
unauthorized access. With DMA remapping enabled, IOMMU ensures that all DMA transactions from
peripheral devices pass through the IOMMU page tables for IOVA to SPA translation, enabling fine-grained
access control, memory protection, and support for virtualization.

The IOMMU operates in two modes for the DMA Remapping feature: Passthrough and Translation modes. In
Passthrough Mode (DMA remapping is disabled), the IOMMU does not translate device-generated addresses
IOVA for DMA, but DMA requests are still intercepted for permission checks before accessing system
memory using SPA, as shown in below diagram (b). In Translation Mode (DMA remapping is enabled), the
IOMMU translates IOVA to SPA using IOMMU page tables, as shown in below diagram (c).

<pre>
    +-----------------+           +-----------------+            +-----------------+
    |     Device      |           |     Device      |            |     Device      |
    +--------+--------+           +--------+--------+            +--------+--------+
             |                             |                              |
 DMA Request | (SPA)           DMA Request | (SPA)            DMA Request | (IOVA)
             |                             |                              |
             v                             v                              v
       +-----------+            +-------------------+           +-------------------+
       |  Memory   |            |        IOMMU      |           |        IOMMU      |
       +-----------+            |  (Memory access   |           | (IOVA -> SPA) and |
                                | Permission checks)|           |   (Memory access  |
    (a) Without IOMMU           +-------------------+           | Permission checks)|
                                           |                    +-------------------+
                                           |                              |
                                           | SPA                          | SPA
                                           |                              |
                                           v                              V
                                     +-----------+                  +-----------+
                                     |  Memory   |                  |  Memory   |
                                     +-----------+                  +-----------+
                     (b) IOMMU DMA remapping disabled. (c) IOMMU DMA remapping enabled.
</pre>

DMA remapping can be configured using kernel command-line options (iommu=off, iommu=pt, iommu=nopt).
For descriptions of these options and guidance on validation, see the "IOMMU kernel command line
options" section below.

## Interrupt Remapping
AMD IOMMU provides interrupt remapping, which intercepts, validates, and translates device-generated
interrupts to the appropriate system interrupt vectors, isolating devices and protecting CPUs from
unauthorized or rogue interrupt delivery. This ensures that all interrupts from peripheral devices
pass through the IOMMU IRT (Interrupt Remapping Table), enabling fine-grained control over interrupt
routing, system stability, security, and support for virtualization.
<br>

<pre>
           +-----------------+                        +-----------------+
           |     Device      |                        |     Device      |
           +--------+--------+                        +--------+--------+
                    |                                          |
                    | Device IRQ Request                       | Device IRQ Request
                    |_________                                 |
                              |                                v
              +------------+  |                         +------------+
              |    IOMMU   |  |                         |    IOMMU   |
              +------------+  |                         +------------+
                     _________|                                |
                    |                                          |
                    | IRQ Delivery                             | IRQ Delivery
                    v                                          V
              +-----------+                             +-----------+
              |    CPU    |                             |    CPU    |
              +-----------+                             +-----------+

      (a) Interrupt remapping disabled.          (b) Interrupt remapping enabled.
</pre>

Interrupt remapping can be configured through kernel command-line options (intremap=on or intremap=off).
For descriptions of these options and details on configuration and validation, refer to the section
"IOMMU kernel command line options" below.

Please refer[IOMMU specification](https://docs.amd.com/v/u/en-US/48882_3.10_PUB)  for more details on
DMA and interrupt remapping.

## IOMMU kernel command line options

**Note** By default, the kernel automatically selects the appropriate IOMMU configuration during
boot based on the platform capabilities and system requirements.

1.  iommu=off

    * Description: IOMMU is disabled. Interrupts and DMA requests from the device is not translated
      by IOMMU and goes directly to the CPU or system memory respectively.

    * Validation: If IOMMU is disabled then dmesg does not contains "AMD-Vi".

        ```
        $ dmesg | grep -i "AMD-Vi"
        ```

2.  iommu=nopt

    * Description: System boots with IOMMU DMA remapping feature enabled. The IOMMU driver manages
    page tables for IOVA to SPA translation and performs mapping and unmapping of entries for DMA
    transactions from peripheral devices.

    * Validation: If IOMMU is in DMA remapping mode then dmesg contains "iommu: Default domain
      type: Translated".
    
        ```
        $ dmesg | grep -i -e "iommu: Default domain type: Translated"
        ```


3.  iommu=pt

    * Description: IOMMU DMA remapping feature is disabled. In this mode, all DMA transfers
    from peripheral devices will be intercepted by IOMMU for permission check without being
    remapped (IOVA = SPA).

    * Validation: If IOMMU is in pass-through mode then dmesg contains "iommu: Default domain
      type: Passthrough".

        ```
        $ dmesg | grep -i -e "iommu: Default domain type: Passthrough"
        ```


6.  intremap=on

    * Description: IOMMU driver sets up IRT (Interrupt Remapping Table) and intercept, filter and
      remap all the interrupts from peripheral devices.

    * Validation: If IOMMU interrupt remapping feature is enabled then dmesg contains
      "AMD-Vi: Interrupt remapping enabled".

        ```
        $ dmesg | grep -i "AMD-Vi: Interrupt remapping enabled"
        ```

7.  intremap=off

    * Description: IOMMU interrupt remapping feature is disabled. Interrupts from peripheral devices
      are delivered directly to CPU without being intercepted by the IOMMU.

      **Note:** With interrupt remapping feature disabled, system will boot with up to 255 CPUs only.

      **Note:** With interrupt remapping feature disabled, VFIO does not allow passthrough devices
      unless allow_unsafe_interrupts is set.

    * Validation: If IOMMU interrupt remapping feature is disabled then dmesg does not contains
                  "AMD-Vi: Interrupt remapping enabled".

        ```
        $ dmesg | grep -i "AMD-Vi: Interrupt remapping enabled"
        ```

