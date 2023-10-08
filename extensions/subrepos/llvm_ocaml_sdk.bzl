################################################################
#### OCAML SDK repo rule ####
def _ocaml_sdk_impl(rctx):
    print("OCAML_SDK REPO RULE")

    rctx.file(
        "MODULE.bazel",
        content = """
module(
    name = "ocaml_llvm",
    version = "15.0.0",
    compatibility_level = 15,
)
"""
    )

    rctx.file(
        "BUILD.bazel",
        content = """
load("@cc_config//:MACROS.bzl", "repo_paths")

load("@bazel_skylib//rules:common_settings.bzl", "string_setting")

PROD_REPOS = [
    "@llvm_c_sdk//version",
    "@ocaml//version"
]

repo_paths(
    name = "repo_paths",
    repos = PROD_REPOS
)

repo_paths(
    name = "test_repo_paths",
    repos = PROD_REPOS + [
    ]
)
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

    ## ocaml_sdk contains:
    ##  llvm-project/llvm/bindings/ocaml
    ##  llvm-project/llvm/test/Bindings/OCaml

    ## we can only symlink one file at a time,
    ## so we need a complete enumeration

    ## first the src BUILD.bazel & .bzl files
    pfx = "{}/utils/bazel/bindings/ocaml/src".format(wsroot)
    llvm_build_files = rctx.execute([
        "find", pfx, "-type", "f",
        "-name", "BUILD.bazel",
        "-o", "-name", "*.bzl"
    ])
    for f in llvm_build_files.stdout.splitlines():
        tail = f.removeprefix(pfx)
        rctx.symlink(f, "src/{}".format(tail))

    ## then the sdk sources
    # pfx = "/Users/gar/tmp/llvm-dune-full-minified-15.0.7+nnp-2/llvm-project/llvm/bindings/ocaml"

    if rctx.attr.ocaml_srcs:
        test = rctx.read(rctx.attr.ocaml_srcs + "/llvm/llvm_ocaml.c")
        pfx = rctx.attr.ocaml_srcs
    else:
        ## in-tree
        pfx = "{}/llvm/bindings/ocaml".format(wsroot)

    llvm_srcs = rctx.execute([
        "find",
        pfx,
        "-type", "f",
        "-name", "*.[c|h]",
        "-o", "-name", "*.mli",
        "-o", "-name", "*.ml",
    ])
    for f in llvm_srcs.stdout.splitlines():
        tail = f.removeprefix(pfx)
        rctx.symlink(f, "src/{}".format(tail))

    ## now the test srcs
    pfx = "{}/llvm/test/Bindings/OCaml".format(wsroot)
    llvm_srcs = rctx.execute([
        "find",
        pfx,
        "-type", "f",
        "-name", "*.mli",
        "-o", "-name", "*.ml",
    ])
    for f in llvm_srcs.stdout.splitlines():
        tail = f.removeprefix(pfx)
        rctx.symlink(f, "test/{}".format(tail))

    ## and test BUILD.bazel files
    pfx = "{}/utils/bazel/bindings/ocaml/test".format(wsroot)
    llvm_build_files = rctx.execute([
        "find", pfx, "-type", "f", "-name", "BUILD.bazel"
    ])
    for f in llvm_build_files.stdout.splitlines():
        tail = f.removeprefix(pfx)
        rctx.symlink(f, "test/{}".format(tail))

    ## end of _ocaml_sdk repo rule ##

############
repo_llvm_ocaml_sdk = repository_rule(
    implementation = _ocaml_sdk_impl,
    local = True,
    attrs = {
        "version_file": attr.string(),
        "llvm": attr.label(),
        "c_sdk": attr.label(),
        "llvm_root": attr.string(mandatory = True),
        "ocaml_srcs": attr.string(mandatory = False),
        # "_ml_template": attr.label(
        #     default = "//src/backends/llvm_backend.ml.in"
        # ),
        # "_mli_template": attr.label(
        #     default = "//src/backends/llvm_backend.mli.in"
        # ),
        "targets": attr.string_list(
            doc = """Supported targets:
            AArch64, AMDGPU, ARM, AVR, BPF, Hexagon, Lanai, Mips,
            MSP430, NVPTX, PowerPC, RISCV, Sparc, SystemZ,
            WebAssembly, X86, XCore.
            Special targets: ALL, host
            """
        ),
    },
)
