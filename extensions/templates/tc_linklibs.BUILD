filegroup(
    name = "link_libs",
    srcs = glob(
        [
            "**/lib*.a",
            "clang/*/lib/**/*.a",
            # grailbio:
            # clang_rt.*.o supply crtbegin and crtend sections.
            ## BUT: no clang_rt.*.o files in e.g. 16.0.5
            ## only for earlier versions?
            "**/clang_rt.*.o",
        ],
        exclude = [
            "libLLVM*.a",
            "libclang*.a",
            "liblld*.a",
        ],
    ),
    # grailbio:
    # Do not include the .dylib files in the linker sandbox because they will
    # not be available at runtime. Any library linked from the toolchain should
    # be linked statically.
)
