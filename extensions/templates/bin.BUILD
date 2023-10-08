exports_files(glob(["**"]))

package(default_visibility=["//visibility:public"])

# bin/lld --help:
# lld is a generic driver.
# Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
filegroup(
    name = "linker_files",
    srcs = [ ## select({ })
        ":ld.lld",  # Unix
        # ":ld64.lld", # macOS
        # ":wasm-ld"  # WebAssembly
    ]
)
