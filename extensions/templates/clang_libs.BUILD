package(default_visibility=["//visibility:public"])

{{COMPONENTS}}

{{EVERY_LIB}}

cc_import(
    name = "clang",
    shared_library = select({
        "@platforms//os:macos": "libclang.dylib",
        "@platforms//os:linux": "libclang.os",
        "//conditions:default": "libclang.os",
    })
)
