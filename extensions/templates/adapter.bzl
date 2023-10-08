# modeled after rules_cc//cc/private/toolchain/unix_cc_toolchain_config.bzl

load("@rules_cc//cc:defs.bzl", "cc_toolchain")
load("@rules_cc//cc:cc_toolchain_config_lib.bzl", "tool_path")
load("@llvm//:CONFIG.bzl", "LLVM_MAKE_VARIABLES")

load(":features.bzl", "make_features")

def make_action_configs(ctx):
    return []

######################################
def _llvm_toolchain_configurator_impl(ctx):

    (tool_paths, features) = make_features(ctx)

    action_configs = make_action_configs(ctx)

    ## https://bazel.build/rules/lib/toplevel/cc_common#create_cc_toolchain_config_info
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        # artifact_name_patterns = [ # ???
        #     artifact_name_pattern(category_name = "foo",
        #                           extension = ".foo")
        # ],
        cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = ctx.attr.host_system_name,
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.cpu,
        target_libc = ctx.attr.target_libc,
        compiler = ctx.attr.compiler,
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        tool_paths = tool_paths,
        make_variables = LLVM_MAKE_VARIABLES, # ctx.attr.make_variables,

        builtin_sysroot = ctx.attr.sysroot
        # If builtin_sysroot is not present, Bazel does not allow
        # using a different sysroot, i.e. through the --grte_top
        # option.
        # cc_target_os = None # Internal use only; do not use
    )

##############################
llvm_toolchain_configurator = rule(
    _llvm_toolchain_configurator_impl,
    doc = "Configures an llvm toolchain.",
    attrs = {
        "abi_libc_version": attr.string(mandatory = True),
        "abi_version": attr.string(mandatory = True),
        "compile_flags": attr.string_list(),
        "compiler": attr.string(mandatory = True),
        "coverage_compile_flags": attr.string_list(),
        "coverage_link_flags": attr.string_list(),
        "cpu": attr.string(mandatory = True),
        "cxx_builtin_include_directories": attr.string_list(),
        "cxx_flags": attr.string_list(),
        "dbg_compile_flags": attr.string_list(),
        "host_system_name": attr.string(mandatory = True),
        "link_flags": attr.string_list(),
        "link_libs": attr.string_list(),
        "opt_compile_flags": attr.string_list(),
        "opt_link_flags": attr.string_list(),
        "supports_start_end_lib": attr.bool(),
        "target_libc": attr.string(mandatory = True),
        "target_system_name": attr.string(mandatory = True),
        "tool_paths": attr.string_dict(),
        "toolchain_identifier": attr.string(mandatory = True),
        "unfiltered_compile_flags": attr.string_list(),
        "sysroot": attr.string(),
        # "make_variables": attr.list()
    },
    provides = [CcToolchainConfigInfo]
)

############################################################
_MIGRATION_TAG = "__CC_RULES_MIGRATION_DO_NOT_USE_WILL_BREAK__"

def _add_tags(attrs):
    if "tags" in attrs and attrs["tags"] != None:
        attrs["tags"] = attrs["tags"] + [_MIGRATION_TAG]
    else:
        attrs["tags"] = [_MIGRATION_TAG]
    return attrs

################
def llvm_toolchain_adapter(**attrs):

    native.cc_toolchain(**_add_tags(attrs))
    # cc_toolchain(
    #     name = "cc-{}".format(ctx.label.name),
    #     # all_files = "all-files-{suffix}",
    #     # ar_files = "archiver-files-{suffix}",
    #     # as_files = "assembler-files-{suffix}",
    #     # compiler_files = "compiler-files-{suffix}",
    #     # dwp_files = "dwp-files-{suffix}",
    #     # linker_files = "linker-files-{suffix}",
    #     # objcopy_files = "objcopy-files-{suffix}",
    #     # strip_files = "strip-files-{suffix}",
    #     toolchain_config = ctx.attr.toolchain_config
    # )
