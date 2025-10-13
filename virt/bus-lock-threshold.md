# Bus Lock Threshold

## Introduction

Virtual machines can exploit bus locks to degrade the performance of the system. Bus locks can be
caused by Non-WB(Write back) and misaligned locked RMW (Read-Modify-Write) instructions. These
operations require system-wide synchronization among all processors, which can result in
significant performance penalties that affect not only the offending VM but the entire host system
and other VMs running on the host.

To address this issue, the Bus Lock Threshold feature provides hypervisors the ability to detect
and limit such rogue guests' capability of initiating excessive bus locks, thereby preventing
system-wide performance degradation.

## Significance

The buslock feature can be used to mitigate the system slow down due to Guest VM bus lock in
multi-tenant environment.

## Support

Starting from:
- Turin (Zen5)
- Family : 1Ah
- Model  : 00h-0Fh

CPUID  : Fn8000_000A_EDX[BusLockThreshold(Bit 29)]

## Reference

AMD64 Architecture Programmer's Manual Pub. 24593, April 2024,<br>
Vol 2, 15.14.5 Bus Lock Threshold.<br>
https://bugzilla.kernel.org/attachment.cgi?id=306250

## Design Description

On processors that support Bus Lock Threshold, the Virtual Machine Control Block (VMCB) is equipped
with a Bus Lock Threshold enable bit and a 16-bit unsigned Bus Lock Threshold counter. KVM
incorporates this support through KVM_CAP_X86_BUS_LOCK_EXIT on SVM CPUs, which is close enough to
VMX's Bus Lock Detection VM-Exit to allow reusing KVM_CAP_X86_BUS_LOCK_EXIT.

The biggest difference between the two features is that Threshold is fault-like, whereas Detection
is trap-like.  To allow the guest to make forward progress, Threshold provides a per-VMCB counter
which is decremented every time a bus lock occurs, and a VM-Exit, specifically VMEXIT_BUSLOCK
(0xA5h) is triggered if and only if the counter is '0'.

In order to get Detection-like semantics, the Bus lock Threshold implementation is designed in such
way that KVM initializes the bus lock counter to '0' i.e. exit on every bus lock, and when
re-executing the guilty instruction, set the counter to '1' to effectively step past the
instruction.

In rare cases where re-executing the instruction does not trigger a bus lock exit due to guest
modifications such as changes in memory type or instruction patching, the bus lock counter remains
at '1', potentially allowing a bus lock from a different instruction. To address this, the
instruction pointer (RIP) at the time of the bus lock exit is saved. This RIP is then used to verify
if the guest has advanced beyond the guilty instruction. If the RIP has changed, the bus lock
counter is set to '0' to effectively step past the bus lock.

## Enablement

Upstream patches:

- faad6645e112 x86/cpufeatures: Add CPUID feature bit for the Bus Lock Threshold
- 827547bc3a2a KVM: SVM: Add architectural definitions/assets for Bus Lock Threshold
- 89f9edf4c69d KVM: SVM: Add support for KVM_CAP_X86_BUS_LOCK_EXIT on SVM CPUs
- 72df72e1c6dd KVM: selftests: Add test to verify KVM_CAP_X86_BUS_LOCK_EXIT

## How to test


kvm_buslock_test kselftest is written to test the Bus Lock Threshold functionaliy.

To run the test, clone and compile the linux sources and run:<br>

```bash
make -j$(nproc) -C tools/testing/selftests/kvm/
./tools/testing/selftests/kvm/x86/kvm_buslock_test
```

The ratelimit for the bus locks acquired in VM can be set in pc-q35-8.0-machine options.<br>

```bash
qemu-system-x86_64 -M q35,bus-lock-ratelimit=50 ...
```

