# Idle-hlt Intercept


## Introduction

The Idle HLT Intercept feature allows for the HLT instruction execution by a vCPU to be intercepted
by the hypervisor only if there are no pending events (V_INTR and V_NMI) for the vCPU. When the vCPU
is expected to service the pending events (V_INTR and V_NMI), the Idle HLT intercept doesn't trigger.
The feature allows the hypervisor to determine if the vCPU is idle and reduces wasteful VMEXITs.

## Significance

1. Idle HLT intercept provides a mild performance boost for all VM types, by avoiding a VM-Exit in
   the scenario where hypervisor would immediately "wake" and resume the vCPU (V_NMI or V_INTR is
   pending at the time of HLT exit).
2. The Idle HLT intercept feature is also used for enlightened guests that aim to securely manage
   events without the hypervisor's awareness. If a HLT occurs while a virtual event is pending and
   the hypervisor is unaware of this pending event (as could be the case with enlightened guests),
   the absence of the Idle HLT intercept feature could result in a vCPU being suspended
   indefinitely.

## Support

Starting from:
- Turin (Zen5)
- Family : 1Ah
- Model  : 00h-0Fh

CPUID  : Fn8000_000A_EDX[IdleHltIntercept(Bit 30)]

## Reference

AMD64 Architecture Programmer's Manual Pub. 24593, April 2024, Vol 2,<br>
15.9 Instruction Intercepts (Table 15-7: IDLE_HLT).<br>
https://bugzilla.kernel.org/attachment.cgi?id=306250

## Design Description

On discovering the Idle HLT Intercept, the Hypervisor

1. Sets the Idle_HLT_Intercept bit (6) in the Virtual Machine Control Block (VMCB), offset 0x14h.
2. Clears the HLT_Intercept bit (0) in the Virtual Machine Control Block (VMCB) offset 0xFh.

When the Idle HLT intercept feature is enabled on the hypervisor and the guest executes
the HLT instruction, a VMEXIT with the exit code 0xA6 (IDLE_HLT) will be generated if
there are no pending V_INTR or V_NMI events. In this scenario, the IDLE_HLT VMEXIT will
be handled in the same manner as the HLT VMEXIT.

## Enablement

Upstream patches:
- 70792aed1455 x86/cpufeatures: Add CPUID feature bit for Idle HLT intercept
- fa662c908073 KVM: SVM: Add Idle HLT intercept support

## How to test
Run perf kvm stat live using perf tool while booting the guest to check for idle-halt exits.

Sample Output:
<br>
```bash
$ perf kvm stat record
[ perf record: Woken up 1 times to write data ]
[ perf record: Captured and wrote 39.094 MB perf.data.guest (335430 samples) ]

$ perf kvm stat report
KVM event statistics (7 entries)
+-----------+---------+---------+--------------+--------+---------------+---------------+-----------------+
|Event name | Samples | Sample% |    Time (ns) |  Time% | Max Time (ns) | Min Time (ns) | Mean Time (ns)  |
+-----------+---------+---------+--------------+--------+---------------+---------------+-----------------+
| idle-halt |  150279 |  91.00% | 159738246175 | 99.00% |      37789103 |          3435 |        1062944  |
|       msr |    7682 |   4.00% |    131930697 |  0.00% |        221743 |           441 |          17174  |
| interrupt |    3150 |   1.00% |     20785385 |  0.00% |         45438 |          2684 |           6598  |
| write_cr4 |    2516 |   1.00% |      7146034 |  0.00% |         53700 |          2524 |           2840  |
|     vintr |     114 |   0.00% |       348572 |  0.00% |          5017 |          2413 |           3057  |
| hypercall |       4 |   0.00% |       256414 |  0.00% |        109043 |         37106 |          64103  |
|       npf |       1 |   0.00% |        25729 |  0.00% |         25729 |         25729 |          25729  |
+-----------+---------+---------+--------------+--------+---------------+---------------+-----------------+
```

