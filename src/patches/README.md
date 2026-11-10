# Kernel patches

Runtime kernel patches from
[KaiT2en-Fedora](https://github.com/kaiT2en/KaiT2en-Fedora) (`patches/runtime/`),
**rebased onto Linux 7.3**. `modules/kernel.nix` applies every patch listed in
each set's `series` file, in order, and defaults `boot.kernelPackages` to
`linuxPackages_7_3`. Evaluation fails with an explanation if the patches are
enabled on another kernel series.

Upstream maintains these against Fedora 44's 7.2.x kernel and applies them
with `patch --fuzz=3`. As-is, they don't apply to 7.3 with the default patch
settings nixpkgs uses. The changes in this rebase:

- **gpu-runtime-pm/0001** (reset VI ASIC on MacBookPro15,1) is dropped. It was
  merged in 7.3 and backported to 7.2.10+, and upstream's installer skips it on
  those kernels too.
- **gpu-runtime-pm/0006**: `smu_set_ac_dc()` gained a `restore_ppt_policy`
  argument in 7.3. The rewritten call passes `true`, as the in-tree caller does.
- **gpu-runtime-pm/0003, 0007, 0009**: 7.3 split `amdgpu_dm.c` into
  `amdgpu_dm_connector.c` and `amdgpu_dm_backlight.c`, and dropped the
  `dev_dbg()` that the 0009 hunk was anchored on. These hunks were moved by
  hand into the same functions at their new locations. (Applied with fuzz 3,
  several of them land inside a comment or outside any function.)
- Every other patch only needed refreshed context.

All patches apply to Linux 7.3.3 in `series` order with zero fuzz. The
patched `amdgpu`, `brcmfmac` and Bluetooth drivers build without warnings and
have been booted on a MacBookPro16,1.

## Rebasing onto a new kernel

1. Apply the upstream `patches/runtime/<set>` series to a clean tree of the new
   kernel in order. Skip patches the kernel already contains.
2. Check every hunk that needed fuzz or a large offset. Wrong placements are
   silent.
3. Regenerate each patch with `git format-patch`, keeping upstream's file
   names, and update `series`.
4. Bump `patchedKernelVersion` in `modules/kernel.nix`.
