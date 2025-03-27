# Introduction

AMD EPYC Linux Feature Documentation project includes information on
various EPYC IP and their enablement in Linux environment. This
documentation serves as a guidance to EPYC users to detect these
features and test their enablement in Linux environment.


# IP Feature List

The AMD EPYC Linux Feature Documentation repository is divided into
following technology domains:

1. Cores (core/)
2. IOMMU (io/)
3. Locking (locking/)
4. Memory Management (mm/)
5. Performance Monitoring (pmu/)
6. Power Management (pm/)
7. Linux RAS (ras/)
8. Scheduler (sched/)
9. Secure Virtualization (svirt/)
10. Virtualization (virt/)

These domains will include guide for feature detection, the state of
feature enablement, best practices, and optionally steps to test
the IP for functional correctness.


## Format

The IP.md files contain the following details:

1. **Introduction**: A brief introduction of the feature
2. **Significance**: Describes the need for the feature and its
significance.
3. **Support**: Processor family supporting the feature and additional
information to detect its presence (CPUID, MSR, etc.)
4. **Reference**: Additional documentation of the feature including
references to relevant specifications, and references to relevant
sections of AMD64 Architecture Programmer’s Manual,
Processor Programming Reference (PPR), etc.
5. **Design Description**: Linux specific design details of the feature.
6. **Enablement**: Upstream commit, mailing list information, and/or git
tree containing the feature implementation.
7. **Prerequisite**: Dependency information like kernel cmdline, BIOS
settings, BIOS version, CPU firmware version, kernel config, any
library, toolchain, external firmware dependency, etc.
8. **Test Environment**: Details on setting up the environment and the
relevant test cases to verify the feature implementation.
9. **Quirks**: Errata, functional and implementation oddities of note
around the feature.

This is a rough guidance for the content of feature documentation. The
actual formatting is left to the author's discretion.


# Building the Feature Documentation

Building the documentation requires the following packages

```
doxygen graphviz texlive-latex-base texlive-fonts-recommended texlive-extra-utils texlive-latex-extra
```

To build the document, please run:

```
make clean
make docs
```

This will generate "epyc_linux_feature_doc.pdf" in the root directory.

