# amd-pstate CPU Frequency Scaling Driver


## Enabling amd-pstate driver

1. Enable CPPC from BIOS options.
2. Enable X86_AMD_PSTATE in kernel config.
3. Add “amd_pstate=active(/passive/guided)” in kernel commandline.
4. Check the CPUFreq driver using “cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver”.
	* It should show "amd-pstate" (if "amd_pstate=passive"/guided was passed in cmdline)
	  or "amd-pstate-epp" (if "amd_pstate=active" was passed in cmdline)

## Introduction

The ACPI Collaborative Processor Performance Control (CPPC) Specification allows the platform to
expose performance capabilities to the OS on an abstract scale of 0-255. These abstract values are
mapped to the available CPU frequency range by the platform firmware. This allows more fine-grained
control over CPU frequency as opposed to a set of finite and discrete P-States (e.g.: three Pstates
P0, P1, P2) made available by the acpi-cpufreq driver.

The amd-pstate CPU frequency scaling driver implements the ACPI CPPC Specification on AMD platforms.
With amd-pstate, the OS can request for perf levels in the turbo boost range (if enabled), whereas
acpi-cpufreq only allows the OS to set frequency upto P0 (nominal frequency).

## Design Description

As per the CPPC specification, the OS is expected to describe its performance requirements by
requesting for a suitable minimum performance level (lower limit), maximum performance level (upper
limit), desired performance level (this value is zero in the autonomous mode) and Energy Performance
Preference, abbreviated as EPP – a value that indicates a bias towards performance or power savings.

Accordingly, amd-pstate has three operating modes: active, passive and guided.

1. In active mode the OS sets the minimum and maximum performance limits, and the EPP. The desired
   performance level is autonomously determined by the platform firmware based on the various
   parameters such as the CPU utilization, the available power and the thermal budgets of the system
   among others.
	*  EPP hints allow the OS to indicate whether it wants a bias towards energy efficiency
	   or performance. Four EPP hints available by the amd-pstate driver in the Linux Kernel.
	   They are performance (EPP=0), balance_performance (EPP=128), balance_power (EPP=191), and
	   power (EPP=255). Only two governors supported - performance and powersave.  With the
	   performance governor, the EPP hint is by default set to performance and cannot be changed.
	   All four EPP hints can be set only with powersave governor.
2. In passive mode, the OS is also responsible for communicating the desired
   performance level to the platform firmware (desired performance level is decided by the CPUFreq
   governor).
	*  All governors are supported. This is akin to the acpi-cpufreq driver with a greater set
	   of frequencies available to the Linux CPUFreq governors.  With the amd-pstate passive
	   mode, the platform firmware will only provide the exact frequency requested by the OS.

```
   +-------------------------------------------+-------------------------------------------+
   |		acpi-cpufreq		       |  	     amd-pstate-passive 	   |
   +-------------------------------------------+-------------------------------------------+
   |    Governor Request  Resultant Frequency  |  Governor Request   Resultant Frequency   |
   |					       |  					   |
   |     [P0 , P1)    --->	[P0, FMax]     |    [0 MHz, FMax] ---> [Lowest, Highest]   |
   |     [P1 , P2)    --->	   P1 	       |  * Resultant frequency will be close to   |
   |     [P2 , 0 ]    --->	   P2	       |    the governor request subject to power/ |
   |					       |    thermal limits			   |
   +-------------------------------------------+-------------------------------------------+
   |  Frequency space as seen by acpi-cpufreq  |  Frequency space as seen by amd-pstate    |
   |	                                       |        Continuous performance scale 	   |
   |  Discrete frequency levels (P0, P1, P2)   |      (Lowest Perf - Highest Perf (255)    |
   |	  +------------------------+           |        +--------------------------+	   |
   |	  |      FMax (Boost)      |           |        | Highest Perf (255/Turbo) |	   |
   |	  |   (not requestable)    |           |        +------------^-------------+	   |
   |	  +-----------^------------+           |                     |			   |
   |	              |                        |        +------------+-------------+	   |
   |	  +-----------+------------+           |        |       Nominal Perf       |  	   |
   |	  |    P0 (max request)    |           |        +------------^-------------+	   |
   |	  +-----------^------------+           |                     |			   |
   |	              |                        |        +------------+-------------+	   |
   |	  +-----------+------------+           |        |   Lowest Nonlinear Perf  |	   |
   |	  |          P1            |           |        +------------^-------------+	   |
   |	  +-----------^------------+           |                     |			   |
   |	              |                        |        +------------+-------------+	   |
   |	  +-----------+------------+           |        |       Lowest Perf        |	   |
   |	  |          P2            |           |        +--------------------------+	   |
   |	  +------------------------+           |                   			   |
   |	                                       |					   |
   +-------------------------------------------+-------------------------------------------+
```

   Crucial difference is that with acpi-cpufreq, if the governor selects the P0 P-State, with boost
   enabled, the platform firmware can automatically boost the frequency to a higher value, whereas with
   amd-pstate=passive, the final frequency will be as close as possible to the requested frequency.

3. In guided mode, the OS will set the minimum performance level to the value decided by the
   CPUFreq governor. This is the lower threshold for the platform firmware, which autonomously
   selects the runtime performance level.
	*  All governors are supported. It is autonomous (like the active mode) to the extent that
	   is allowed by the OS governor (like the passive mode). This mode is added to emulate the
	   behaviour of the schedutil governor with the acpi-cpufreq driver.

## Guidance on which mode to use

1. Active mode:
   * Performance governor should be considered equivalent to acpi-cpufreq with performance governor
     in terms of performance and provides better energy efficiency at lower CPU utilizations.
   * Powersave governor along with EPP hints (power [EPP=255], balance_power [EPP=192],
     balance_performance [EPP=128], performance [EPP=0]) is equivalent to acpi-cpufreq with
     schedutil in terms of performance. The EPP hints can be used to bias towards performance or
     energy efficiency.
   * Till Zen 4, setting an EPP value will only map to a fixed frequency. Zen 5 onwards, EPP value
     will define the rate of frequency ramp-up w.r.t the CPU utilization.
2. Passive mode:
   * Provides more fine-grained control over the CPU frequency range compared to acpi-cpufreq.
3. Guided mode:
   * Allows to specify a lower CPU frequency limit, providing the platform firmware the freedom
     to choose any frequency above this value.

## Summary of operating modes

```
+-----------------+-----------------------------+----------------------+----------------------+
|                 | Active mode          	| Passive mode         | Guided mode          |
+-----------------+-----------------------------+----------------------+----------------------+
| OS controls     | Min, Max limits, EPP hint 	| Min, Max limits,     | Min, Max limits      |
|		  |			 	| Desired frequency    | Desired Frequency    |
+-----------------+-----------------------------+----------------------+----------------------+
| Platform        | Decide which frequency      | Provide frequency    | Provide frequency    |
| controls        | to be set within OS limits  | closest to OS request| >= OS request        |
+-----------------+-----------------------------+----------------------+----------------------+
```

## CPPC support across AMD processor generations

Two types of communications are supported between platform firmware and the OS: shared memory and
MSR-based. Older systems used shared memory, whereas Zen4 onwards use MSRs.

```
+-------------------+--------------------------+
| Processor Family  | CPPC Support             |
+-------------------+--------------------------+
| Zen1              | Not supported            |
+-------------------+--------------------------+
| Zen2              | Shared Memory            |
+-------------------+--------------------------+
| Zen3              | Shared Memory / MSR      |
+-------------------+--------------------------+
| Zen4+             | MSR                      |
+-------------------+--------------------------+
```

## AMD Pstate in the Linux kernel

```
+---------------+     +-------------------+     +-------------+     +-------------+     +--------------+
|      5.16     |     |        6.1        |     |     6.2     |     |     6.3     |     |     6.13     |
+---------------+     +-------------------+     +-------------+     +-------------+     +--------------+
|Initial passive|     |amd_pstate=passive |     |Active mode  |     |Guided mode  |     |Driver enabled|
|mode support   | --> |cmdline option     | --> |support added| --> |support added| --> |by default    |
|added          |     |added, driver      |     |             |     |             |     |for Zen 5     |
|               |     |disabled by default|     |             |     |             |     |and above     |
+---------------+     +-------------------+     +-------------+     +-------------+     +--------------+
```

## Prerequisites

1. BIOS config options:
	* On the AMD AGESA BIOS, Enable NBIO Common Options --> SMU Common Options --> CPPC
	* BIOS version should be recent enough to support CPPC v3
	* CPPC is defined in section 8.4.6 of the ACPI spec v6.5
	  https://uefi.org/sites/default/files/resources/ACPI_Spec_6_5_Aug29.pdf
2. Kernel config:
	* Enable X86_AMD_PSTATE config
3. Kernel command line parameter:
	* Pass amd_pstate=active/passive/guided in kernel cmdline to boot with amd-pstate driver
	* If amd_pstate=disable is passed, acpi-cpufreq will be loaded, if enabled through config options

## User interface

1. Checking current CPUFreq driver:
	* /sys/devices/system/cpu/cpu<x>/cpufreq/scaling_driver “amd-pstate-epp” for the active mode, and
	  “amd-pstate” for the passive and guided modes.
2. Current amd-pstate mode:
	* /sys/devices/system/cpu/amd_pstate/status
3. Setting lower frequency limit:
	* /sys/devices/system/cpu/cpu<x>/cpufreq/scaling_min_freq
	* Note: On EPYC servers with Zen4 and older processors, this limit only takes effect at a CCD
	  level (i.e. the max value from all the CPUs in the CCD will be considered), whereas Zen5
	  onwards it takes effect at an individual CPU core level.
4. Setting upper frequency limit:
	* /sys/devices/system/cpu/cpu<x>/cpufreq/scaling_max_freq
	* Same caveat as above.
5. Setting EPP hint:
	* /sys/devices/system/cpu/cpu<x>/cpufreq/energy_performance_preference
	* energy_performance_available_preferences file in the same directory gives the supported EPP hints.
6. Toggling the boost:
	* /sys/devices/system/cpu/cpufreq/boost
	* Post linux kernel 6.11, boost can be toggled at a per-CPU level as well through
	  /sys/devices/system/cpu/cpu<x>/cpufreq/boost
7. Setting desired frequency (only available with userspace governor):
	* /sys/devices/system/cpu/cpu<x>/cpufreq/scaling_setspeed

## FAQs

1. What are the BIOS Feature pre-requisite to enable CPPC?
-> The BIOS feature titled "CPPC" needs to be enabled. On the AMD AGESA BIOS this is via
   NBIO Common Options --> SMU Common Options --> CPPC

2. Where to get latest AMD CPPC OS drivers for Zen4 CPU?
-> The latest version of the driver is available in the upstream linux kernel. The files are
   drivers/cpufreq/amd-pstate.c and drivers/cpufreq/amd-pstate.h

3. Are there other steps/commands needed in OS to enable CPPC and be able to control P-State?
-> Yes, one of the following kernel commandline options needs to be passed: "amd_pstate=active"
   or "amd_pstate=passive" or "amd_pstate=guided"
   This will boot the kernel with the amd_pstate driver which implements the ACPI CPPC Spec. The
   mode will be one of "active", "passive" or "guided" respectively. These modes are documented
   in the amd-pstate kernel documentation.
   https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/pm/amd-pstate.rst#amd-pstate-driver-operation-modes

4. How to verify P-State is indeed changed through CPPC?
-> CPUFreq driver: /sys/devices/system/cpu/cpu<x>/cpufreq/scaling_driver. This shows the current
   cpufreq driver being used, it returns “amd-pstate-epp” for the active mode, and “amd-pstate”
   for the passive and guided modes. If this driver is loaded, then the P-State change occurs
   through CPPC.

5. I want the best possible performance for my workload irrespective of the energy consumed. Which
   amd-pstate mode should I use?
-> You should use “amd_pstate=active” with performance governor with boost enabled, this will
   allow the CPU cores to run at the maximum possible frequency subject to thermal and power
   constraints.

6. I want to save maximum possible energy when the utilization of the system is low. Which
   amd-pstate mode should I use?
-> You should use “amd_pstate=active” with powersave governor and “power” EPP hint.

7. The behaviour of the powersave governor with amd-pstate driver passive mode is the same as the
   acpi-cpufreq driver. However, the behaviour of powersave governor with amd-pstate active mode
   is different. Why is that?
-> The powersave governor with amd-pstate passive mode or acpi-cpufreq always requests the lowest
   performance level which corresponds to the lowest frequency. The behaviour of the powersave
   governor with active mode is governed by the Energy Performance Preference (EPP) value. If the
   EPP value is performance then the Platform Firmware frequency-scaling strategy will be biased
   towards providing the highest performance. If the EPP value is power, then the Platform Firmware
   frequency-scaling will be biased towards providing the best power savings.

## How to test

1. Enable amd-pstate selftest as mentioned below
   * Enable config X86_AMD_PSTATE_UT to build the selftest for amd-pstate.  It will test basic
     sanity of amd-pstate driver. The results of the unit test will appear in the linux kernel
     logs (`dmesg`).
