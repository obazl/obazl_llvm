load(":adapter.bzl",
     "llvm_toolchain_adapter",
     "llvm_toolchain_configurator")

load("@llvm//:CONFIG.bzl",
     "BUILTIN_INCLUDE_DIRS",
     "LLVM_MAKE_VARIABLES",
     "TOOL_PATHS")

########################
llvm_toolchain_adapter(
    name = "{{tc_id}}",
    all_files = "@llvm//bin:all_files",
    ar_files = "@llvm//bin:ar_files",
    as_files = "@llvm//bin:as_files",
    compiler_files = "@llvm//bin:compiler_files",
    dwp_files = "@llvm//bin:dwp_files",
    linker_files = "@llvm//bin:linker_files",
    objcopy_files = "@llvm//bin:objcopy_files",
    strip_files = "@llvm//bin:strip_files",
    toolchain_config = ":{{tc_id}}-config"
)

########################
llvm_toolchain_configurator(
    name = "{{tc_id}}-config",
    abi_libc_version = "{{abi_libc_version}}",
    abi_version = "{{abi_version}}",
    # compile_flags: {{compile_flags}},
    compiler = "{{compiler}}",
    # "coverage_compile_flags": attr.string_list(),
    # "coverage_link_flags": attr.string_list(),
    cpu = "{{cpu}}",
    cxx_builtin_include_directories = BUILTIN_INCLUDE_DIRS,
    # "cxx_flags": attr.string_list(),
    # "dbg_compile_flags": attr.string_list(),
    host_system_name = "{{host_system_name}}",
    # we need a c++ stdlib, since llvm is implemented in c++
    # but we can choose between -lc++ (llvm) and -lstdc++ (gcc)
    # TODO: make that a feature?
    link_flags = ["-lc++", "-mmacos-version-min=13.6"],
    # link_libs =  ["@llvm//lib:libc++"],
    # opt_compile_flags = [], # "-DNDEBUG"],
    # "opt_link_flags": attr.string_list(),
    # "supports_start_end_lib": attr.bool(),
    target_libc = "{{target_libc}}",
    target_system_name = "{{target_system_name}}",
    tool_paths = TOOL_PATHS,
    toolchain_identifier = "{{tc_id}}",
    # "unfiltered_compile_flags": attr.string_list(),
    sysroot = "{{sysroot}}",
    # make_variables = LLVM_MAKE_VARIABLES
)

