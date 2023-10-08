################################################################
#### LLVM TOOL repo rule ####
def _llvm_tools_impl(rctx):
    print("LLVM_TOOLS REPO RULE")

    rctx.file(
        "MODULE.bazel",
        content = """
module(
    name = "llvm_tools",
    version = "{version}",
    compatibility_level = {compat},
)
""".format(version = rctx.attr.version,
           compat = rctx.attr.compatibility_level)
    )

    rctx.file(
        "BUILD.bazel",
        content = "#"
    )

    # rctx.workspace_root is the ws from which
    # the extension (& the repo rule) was called.
    # we symlink directories, which means
    # the build files we write will be written
    # to the original dirs. the will not be
    # removed by bazel clean.
    # wsroot = rctx.workspace_root
    wsroot = rctx.attr.llvm_root

    # rctx.symlink(
    #     "{}/utils/bazel/TOOLS.bzl".format(wsroot),
    #     "TOOLS.bzl")

    rctx.symlink(rctx.attr.version_file,
                 "version/BUILD.bazel")

    rctx.symlink(rctx.attr.options_path,
                 "CONFIG.bzl")

    ## bin dir same for all sdks
    rctx.symlink("{}".format(rctx.attr.llvm_bindir), "bin")

    rctx.file("bin/BUILD.bazel",
              content = """
exports_files( glob(["**"]) )
"""
              )

#     rctx.file(
#         "sdk/bin/BUILD.bazel",
#         content = """
# exports_files(glob(["**"]))
# """
#     )

#     rctx.symlink("{root}/{bld}/lib".format(
#         root=wsroot,
#         bld=rctx.attr.llvm_root),
#                  "sdk/c/lib")
#     rctx.symlink("{root}/{bld}/libexec".format(
#         root=wsroot,
#         bld=rctx.attr.llvm_root),
#                  "sdk/c/libexec")

    # libsmap = genlibsmap(rctx)
    # rctx.template(
    #     "sdk/c/lib/BUILD.bazel",
    #     Label(":BUILD.lib_pkg"),
    #     substitutions = libsmap,
    #     executable = False,
    # )

    # xarch = rctx.os.arch.lower()
    # arch = archmap[xarch]
    # print("ARCH: %s" % arch)

#     rctx.file(
#         "makevars/RULES.bzl",
#         content = """
# load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

# def _makevars_impl(ctx):
#     t = ctx.attr._target[BuildSettingInfo].value
#     if t == "host":
#         arch = "{host_arch}"
#     else:
#         arch = t
#     items = {{"LLVM_TARGET_ARCH": arch}}

#     return [platform_common.TemplateVariableInfo(items)]
# makevars = rule(
#     implementation = _makevars_impl,
#     attrs = {{ "_target": attr.label(
#         default = "//target"
#         ) }}
# )
# """.format(host_arch = arch)
#     )

#     rctx.file(
#         "makevars/BUILD.bazel",
#         content = """
# load(":RULES.bzl", "makevars")
# makevars(name = "makevars",
#          visibility = ["//visibility:public"])
# """
#     )

#     rctx.file(
#         "host/BUILD.bazel",
#         content = """
# package(default_visibility = ["//visibility:public"])
# config_setting(name = "aarch64",
#                flag_values = {"//target": "host"},
#                constraint_values = ["@platforms//cpu:aarch64"])
# config_setting(name = "x86",
#                flag_values = {"//target": "host"},
#                constraint_values = ["@platforms//cpu:x86_64"])
# """
#         )

#     rctx.file(
#         "target/BUILD.bazel",
#         content = """
# load("@bazel_skylib//rules:common_settings.bzl", "string_flag")
# string_flag(
#     name = "target", build_setting_default = "host",
#     visibility = ["//visibility:public"],
#     values = [
#         "AArch64", "AMDGPU", "ARM", "AVR", "BPF",
#         "Hexagon", "Lanai", "Mips", "MSP430",
#         "NVPTX", "PowerPC", "RISCV", "Sparc",
#         "SystemZ", "WebAssembly", "X86", "XCore",
#         "host"
#     ]
# )
# config_setting(name = "host",
#                flag_values = {":target": "host"})

# config_setting(name = "aarch64",
#                flag_values = {":target": "aarch64"})

# config_setting(name = "x86",
#                flag_values = {":target": "x86"})
# """
#     )

    ## end of _llvm_tools repo rule

############
repo_llvm_tools = repository_rule(
    implementation = _llvm_tools_impl,
    local = True,
    attrs = {
        "version": attr.string(),
        "compatibility_level": attr.string(),
        "version_file": attr.string(),
        "llvm": attr.label(),
        "llvm_root": attr.string(mandatory = True),
        "llvm_bindir": attr.string(mandatory = True),
        "options_path": attr.string(
            doc = "path to CONFIG.bzl in @modextwd"
        ),
        "targets": attr.string_list(
            doc = "llvm-config --targets-built"
        ),
        "components": attr.string_list_dict(
            doc = "Key: component name; val: list of libs"
        ),
        "libs": attr.string_list()
    },
)

