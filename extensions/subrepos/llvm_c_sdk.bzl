archmap = {
    "aarch64": "AArch64",
    "amdgpu": "AMDGPU",
    "arm": "ARM",
    "avr": "AVR",
    "bpf": "BPF",
    "hexagon": "Hexagon",
    "lanai": "Lanai",
    "mips": "Mips",
    "msp430": "MSP430",
    "nvptx": "NVPTX",
    "powerpc": "PowerPC",
    "riscv": "RISCV",
    "sparc": "Sparc",
    "systemz": "SystemZ",
    "webassembly": "WebAssembly",
    "x86": "X86",
    "xcore": "XCore"
}

# supported = [
#     "AArch64", "AMDGPU", "ARM", "AVR", "BPF",
#     "Hexagon", "Lanai", "Mips", "MSP430", "NVPTX",
#     "PowerPC", "RISCV", "Sparc", "SystemZ",
#     "WebAssembly", "X86", "XCore",
# ]

#####################
def genlibsmap(rctx, components, libs):

    libsmap = {}

    stanzas = ""

    for component,clibs in components.items():

        stanza = """
cc_library(name = "{c}-libs",
           srcs = [{libs}])
""".format(c=component,
           libs= ", ".join(clibs))

        stanzas = stanzas + stanza

    libsmap["{{COMPONENTS}}"] = stanzas

    stanzas = ""

    for libname,filename in libs.items():

        stanza = """
cc_import(name = "{libname}",
          static_library = "{fname}")
""".format(libname=libname, fname = filename)
        stanzas = stanzas + stanza

    libsmap["{{EVERY_LIB}}"] = stanzas

    return libsmap

###########################
def _llvm_c_sdk_impl(rctx):
    # print("LLVM_SDK REPO RULE")

    # print("LLVM_ROOT %s" % rctx.attr.llvm_root)

    rctx.file(
        "MODULE.bazel",
        content = """
module(
    name = "llvm_c_sdk",
    version = "17.0.1",
    compatibility_level = 17,
)
"""
    )

    rctx.file(
        "BUILD.bazel",
        content = "#"
    )

    rctx.file(
        "CONFIG.bzl",
        content = """
COPTS = [
    "-g",
    "-O0",
    "-UDEBUG" # macos fastbuild
]

LLVM_DEFINES = [
    "__STDC_CONSTANT_MACROS",
    "__STDC_FORMAT_MACROS",
    "__STDC_LIMIT_MACROS"
]

LLVM_LINKOPTS = [
    # llvm linker flags (llvm-config --ldflags):
    "-Wl,-search_paths_first",
    "-Wl,-headerpad_max_install_names"
]
"""
    )

    rctx.symlink(rctx.attr.version_file,
                 "version/BUILD.bazel")
#     rctx.file(
#         "version/BUILD.bazel",
#         content = """
# load("@bazel_skylib//rules:common_settings.bzl",
#       "string_setting")

# string_setting(
#     name = "version", build_setting_default = "15.0.0",
#     visibility = ["//visibility:public"],
#     )
# """
#     )

    # rctx.workspace_root is the ws from which
    # the extension (& the repo rule) was called.
    # we symlink directories, which means
    # the build files we write will be written
    # to the original dirs. the will not be
    # removed by bazel clean.
    wsroot = rctx.workspace_root

    wsroot = rctx.attr.llvm_root

    ## bin dir same for all sdks
    # rctx.symlink("{root}/{bld}/bin".format(
    rctx.symlink("{root}/bin".format(root=wsroot),
                 # bld=rctx.attr.llvm_root
                 "bin")

#     rctx.file(
#         "bin/BUILD.bazel",
#         content = """
# exports_files(glob(["**"]))
# """
#     )

    # rctx.symlink("{root}/{bld}/include/llvm".format(
    #     root=wsroot,
    rctx.symlink("{root}/include/llvm".format(
        root=rctx.attr.llvm_root),
                 "include/llvm")

    if rctx.attr.is_distro:
        rctx.symlink("{root}/include/llvm-c".format(
            root=rctx.attr.llvm_root), # wsroot),
                     "include/llvm-c")
        ## to use clang tc:
        rctx.symlink("{root}/lib/clang/17/include".format(
            root=rctx.attr.llvm_root), # wsroot),
                     "include/clang")
        # rctx.symlink("{root}/lib/clang/17/include/llvm_libc_wrappers".format(
        #     root=rctx.attr.llvm_root), # wsroot),
        #              "include/libc")

    else:
        rctx.symlink("{root}/../llvm/include/llvm-c".format(
            root=rctx.attr.llvm_root), # wsroot),
                     "include/llvm-c")

    rctx.file(
        "include/BUILD.bazel",
        content = """
cc_library(
    name = "include",
    hdrs = glob(["llvm-c/**"]) + glob([
        "llvm/Config/llvm-config.h", # C hdr among c++ hdrs
        "llvm/Config/*.def"
    ], exclude = ["llvm/Config/abi-breaking.h"]),
    visibility = ["//visibility:public"]
)
"""
        )

    wsroot = rctx.attr.llvm_root
    ## c++ sdk
    # rctx.symlink("{root}/libcxx/include".format(root=wsroot),
    #              "sdk/c++/include")

    rctx.symlink("{root}/lib".format(
        root=wsroot,
        bld=rctx.attr.llvm_root),
                 "lib")
    rctx.symlink("{root}/libexec".format(
        root=wsroot,
        bld=rctx.attr.llvm_root),
                 "libexec")

    # print("CC: %s" % rctx.attr.components)
    # fail("STOP")

    libsmap = genlibsmap(rctx,
                         rctx.attr.components,
                         rctx.attr.libs)
    rctx.template(
        "lib/BUILD.bazel",
        # "BUILD.lib",
        Label("//extensions/templates:BUILD.lib_pkg"),
        substitutions = libsmap,
        executable = False,
    )

    xarch = rctx.os.arch.lower()
    arch = archmap[xarch]
    # print("ARCH: %s" % arch)

    rctx.file(
        "makevars/RULES.bzl",
        content = """
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _makevars_impl(ctx):
    t = ctx.attr._target[BuildSettingInfo].value
    if t == "host":
        arch = "{host_arch}"
    else:
        arch = t
    items = {{"LLVM_TARGET_ARCH": arch}}

    return [platform_common.TemplateVariableInfo(items)]
makevars = rule(
    implementation = _makevars_impl,
    attrs = {{ "_target": attr.label(
        default = "//target"
        ) }}
)
""".format(host_arch = arch)
    )

    rctx.file(
        "makevars/BUILD.bazel",
        content = """
load(":RULES.bzl", "makevars")
makevars(name = "makevars",
         visibility = ["//visibility:public"])
"""
    )

    rctx.file(
        "host/BUILD.bazel",
        content = """
package(default_visibility = ["//visibility:public"])
config_setting(name = "aarch64",
               flag_values = {"//target": "host"},
               constraint_values = ["@platforms//cpu:aarch64"])
config_setting(name = "x86",
               flag_values = {"//target": "host"},
               constraint_values = ["@platforms//cpu:x86_64"])
"""
        )
    rctx.file(
        "target/BUILD.bazel",
        content = """
load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
string_flag(
    name = "target", build_setting_default = "host",
    visibility = ["//visibility:public"],
    values = [
        "AArch64", "AMDGPU", "ARM", "AVR", "BPF",
        "Hexagon", "Lanai", "Mips", "MSP430",
        "NVPTX", "PowerPC", "RISCV", "Sparc",
        "SystemZ", "WebAssembly", "X86", "XCore",
        "host"
    ]
)
config_setting(name = "host",
               flag_values = {":target": "host"})

config_setting(name = "aarch64",
               flag_values = {":target": "aarch64"})

config_setting(name = "x86",
               flag_values = {":target": "x86"})
"""
    )

    ## end of _llvm_c_sdk repo rule

############
repo_llvm_c_sdk = repository_rule(
    implementation = _llvm_c_sdk_impl,
    local = True,
    attrs = {
        "version": attr.string(),
        "compatibility_level": attr.string(),
        "version_file": attr.string(),
        "llvm": attr.label(),
        "llvm_root": attr.string(mandatory = True),
        "options_path": attr.string(
            doc = "path to CONFIG.bzl in @modextwd"
        ),
        "components": attr.string_list_dict(
            doc = "Key: component name; val: list of libs"
        ),
        "libs": attr.string_dict(),
        "is_distro": attr.bool(),
        "targets": attr.string_list(
            doc = "llvm-config --targets-built"
        ),
    },
)
