exports_files(glob(["**"]))

package(default_visibility=["//visibility:public"])

filegroup(
    name = "all_files",
    srcs = [
        #":all-components-aarch64-darwin",
        ## "@@toolchains_llvm~override~llvm~llvm_toolchain_llvm//:bin",
        ## grailbio globs everything in bin, not needed?

        #":compiler-components-aarch64-darwin",
        ":compiler_files",

        # ":linker-components-aarch64-darwin",
        ":linker_files",

        # ":internal-use-files"
        # ":internal-use-symlinked-tools",
        ":core_tools",
        # ":internal-use-wrapped-tools",
        # "bin/cc_wrapper.sh",
    ]
)

filegroup(
    name = "ar_files",
    srcs = [":llvm-ar"]
)

filegroup(
    name = "as_files",
    srcs = [
        ":clang",
        ":llvm-as",
    ],
)

filegroup(
    name = "core_tools",
    srcs = [
        ":clang-cpp",
        ":ld.lld",
        ":llvm-ar",
        ":llvm-dwp",
        ":llvm-profdata",
        ":llvm-cov",
        ":llvm-nm",
        ":llvm-objcopy",
        ":llvm-objdump",
        ":llvm-strip",
    ]
)

filegroup(
    name = "compiler_files",
    srcs = [
        # ":compiler-components-aarch64-darwin",
        ":clang",
        ##"@@toolchains_llvm~override~llvm~llvm_toolchain_llvm//:include",
        "@llvm//include",

        # ":sysroot-components-aarch64-darwin",
        # srcs = [],

        # ":internal-use-files"
        ":core_tools"
    ]
)

filegroup(
    name = "dwp_files",
    srcs = [":llvm-dwp"],
)


# bin/lld --help:
# lld is a generic driver.
# Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
filegroup(
    name = "linker_files",
    srcs = [ ## select({ })
        # ":linker-components-aarch64-darwin",
        ":clang",
        ":llvm-ar",
        # ":lib",
        "@llvm//lib:link_libs",

        ":lld", # llvm linker

        # ld.lld -> lld
        # ld64.lld -> lld
        # lld-link -> lld

        # ":sysroot-components-aarch64-darwin",
        # srcs = [],

        #":internal-use-files"
        ":core_tools",

        ":ld.lld",  # Unix
        # ":ld64.lld", # macOS
        # ":wasm-ld"  # WebAssembly
    ]
)

filegroup(
    name = "objcopy_files",
    srcs = [":llvm-objcopy"],
)

filegroup(
    name = "strip_files",
    srcs = [":llvm-strip"],
)


