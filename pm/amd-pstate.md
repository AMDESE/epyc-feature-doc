# amd-pstate driver EPYC feature documentation

## TLDR

- Enable CPPC from BIOS options.
- Enable X86_AMD_PSTATE in kernel config.
- Add “amd_pstate=active(/passive/guided)” in kernel commandline.
- Check the CPUFreq driver using “cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver”.

