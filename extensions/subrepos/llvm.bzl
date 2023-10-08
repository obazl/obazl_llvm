# info on targets: llvm-project/docs/GettingStarted.rst

################
def _emit_bin_files(rctx, bindir):

    tools = [
        "clang-cpp",
        "ld.lld",
        "llvm-ar",
        "llvm-dwp",
        "llvm-profdata",
        "llvm-cov",
        "llvm-nm",
        "llvm-objcopy",
        "llvm-objdump",
        "llvm-strip",
    ]

#     rctx.file(
#         "CONFIG.bzl",
#         content = """
# CPPFLAGS = {cppflags}
# CPPDEFINES = {cppdefines}

# CFLAGS = {cflags}
# CDEFINES = {cdefines}

# CXXFLAGS = {cxxflags}
# CXXDEFINES = {cxxdefines}

# LDFLAGS = {ldflags}

# SYSLIBS = {syslibs}

# TARGETS = {targets}

# TOOL_PATHS = {tool_paths}

# """.format(
#     cppflags = cppflags,
#     cppdefines = cppdefines,
#     cflags   = cflags,
#     cdefines = cdefines,
#     cxxflags = cxxflags,
#     cxxdefines = cxxdefines,
#     ldflags  = ldflags,
#     syslibs  = syslibs,
#     targets  = targets,
#     tool_paths = make_tool_paths(bindir)
# )
#         )

#     return mctx.path("CONFIG.bzl")

    #### end of _emit_bin_files ####

#####################
def _llvm_impl(rctx):
    # print("LLVM REPO RULE")

    rctx.file(
        "MODULE.bazel",
        content = """
module(
    name = "llvm",
    version = "{v}",
    compatibility_level = {c},
)
bazel_dep(name = "rules_cc", version = "0.0.9")
""".format(v=rctx.attr.version,c="0")
    )

    rctx.file(
        "BUILD.bazel",
        content = "#"
    )

    rctx.symlink(rctx.attr.version_file,
                 "version/BUILD.bazel")

    rctx.symlink(rctx.attr.config_path,
                 "CONFIG.bzl")

    rctx.symlink(rctx.attr.bindir,
                 "bin")

    rctx.template(
        "bin/BUILD.bazel",
        Label("//extensions/templates:bin.BUILD"),
        executable = False,
    )

    ## toolchains ##
    tcmap = {
        "{{tc_id}}": rctx.attr.host_triple,
        "{{target_system_name}}": rctx.attr.host_triple,
        "{{sysroot}}": rctx.attr.sysroot
    }

    ## llvm cc toolchain type
    rctx.template(
        "toolchain/type/BUILD.bazel",
        Label("//extensions/templates:toolchain_type.BUILD"),
        # substitutions = {},
        executable = False,
    )

    ## toolchain_selector definition
    rctx.template(
        "toolchain/selector.bzl",
        Label("//extensions/templates:selector.bzl"),
        # substitutions = {},
        executable = False,
    )

    ## selectors go in @llvm//toolchain
    rctx.template(
        "toolchain/BUILD.bazel",
        Label("//extensions/templates:toolchain.BUILD"),
        substitutions = tcmap,
        executable = False,
    )

    ## llvm_adapter_toolchain definition
    rctx.template(
        "toolchain/adapters/adapter.bzl",
        Label("//extensions/templates:adapter.bzl"),
        executable = False,
    )
    ## adapter helpers
    rctx.template(
        "toolchain/adapters/features.bzl",
        Label("//extensions/templates:features.bzl"),
        executable = False,
    )


    ## adapters
    rctx.template(
        "toolchain/adapters/BUILD.bazel",
        Label("//extensions/templates:adapters.BUILD"),
        substitutions = tcmap,
        executable = False,
    )


    ## end of _llvm repo rule

############
repo_llvm = repository_rule(
    implementation = _llvm_impl,
    local = True,
    attrs = {
        "home": attr.string(),
        "version": attr.string(),
        "compatibility_level": attr.string(),
        "version_file": attr.string(),
        "llvm": attr.label(),
        "llvm_root": attr.string(mandatory = False),
        "sysroot": attr.string(),
        "config_path": attr.string(
            doc = "path to CONFIG.bzl in @modextwd"
        ),
        "bindir": attr.string(),
        "host_triple": attr.string(
            doc = "llvm-config --host-target"
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
