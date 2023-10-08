load(":selector.bzl", "toolchain_selector")

# TODO: one tc per built-target?
# clang -print-target-triple
# clang -print-effective-triple Print the effective target triple
# clang -print-supported-cpus
# clang -print-targets - lists "Registered targets"
# llvm-config -targets-built - does not match -print-targets?

# clang --target=<value> - Generate code for the given target

# toolchain_selector(
#     name      = "llvm_{{tc_id}}",
#     toolchain = "@llvm//toolchain/adapters:{{tc_id}}",
#     build_host_constraints  = [
#         "@platforms//cpu: {{host_arch}}",
#         "@platforms//os : {{host_os_bzl}}",
#     ],
#     target_host_constraints  = [
#         "@platforms//cpu: {{target_arch}}",
#         "@platforms//os : {{target_os_bzl}}",

#     ],
#     toolchain_constraints = {{target_settings}}
#     visibility     = ["//visibility:public"],
# )

## local tc, unconstrained
toolchain_selector(
    name      = "llvm_local_tc",
    toolchain = "@llvm//toolchain/adapters:{{tc_id}}",
    visibility     = ["//visibility:public"],
)

