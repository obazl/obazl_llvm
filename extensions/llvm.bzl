load("//extensions/subrepos:llvm.bzl", "repo_llvm")
load("//extensions/subrepos:llvm_c_sdk.bzl", "repo_llvm_c_sdk")
load("//extensions/subrepos:llvm_ocaml_sdk.bzl", "repo_llvm_ocaml_sdk")
# load("//extensions/subrepos:llvm_tools.bzl", "repo_llvm_tools")

load("//extensions/subrepos:clang_c_sdk.bzl", "repo_clang_c_sdk")

# info on llvm targets: llvm-project/docs/GettingStarted.rst

################
def _builtin_include_dirs(mctx, sysroot, llvm_root, version):
    # print("LLVM_ROOT: %s" % llvm_root)

    ## NOTE the trailing '/' !!!

    dirs = []
    dirs.extend([
        llvm_root + "/include/",
        llvm_root + "/include/c++/v1/",
        llvm_root + "/lib/clang/{}/include/".format("17"),
        # llvm_root + "lib/clang/{}/share".format(llvm_version),
        # llvm_root + "lib/clang/{}/include".format(major_llvm_version),
        # llvm_root + "lib/clang/{}/share".format(major_llvm_version),

        # no lib64 as far back as 7.1.0 (binary distros)
        # 5.0.0 (2017) distro is source only, contains lib64 subdirs
        # llvm_root + "lib64/clang/{}/include".format(llvm_version),
        # llvm_root + "lib64/clang/{}/include".format(major_llvm_version),
    ])

    # if macos
    dirs.extend([
        sysroot + "/usr/include/",
        sysroot + "/System/Library/Frameworks/",
    ])

    return dirs

################
def make_tool_paths(bindir):
    return {
        "ar": bindir + "/llvm-ar",
        "cpp": bindir + "/clang-cpp",
        "dwp": bindir + "/llvm-dwp",
        "gcc": bindir + "/clang",
        # "gcc": wrapper_bin_prefix + "/cc_wrapper.sh",
        "gcov": bindir + "/llvm-profdata",
        "ld": bindir + "/ld.lld",
        # if use_lld else _host_tools.get_and_assert(host_tools_info, "ld"),
        "llvm-cov": bindir + "/llvm-cov",
        "llvm-profdata": bindir + "/llvm-profdata",
        "nm": bindir + "/llvm-nm",
        "objcopy": bindir + "/llvm-objcopy",
        "objdump": bindir + "/llvm-objdump",
        "strip": bindir + "/llvm-strip",
    }

################
def _is_distro(mctx, path):
    # print("IS DISTRO %s" % path)
    # distros contain dirs: bin, include, lib, libexec, share
    # src builds contain CMakeCache.txt, etc.

    path = mctx.path(path + "/CMakeCache.txt")
    if path.exists:
        return True
    else:
        return False
    #### end of _is_distro ####

################
def _libdeps(mctx, llvm_config_tool):

    ## every component
    components = {}
    xcomponents = mctx.execute([llvm_config_tool,
                               "--link-static",
                               "--components"])
    for component in xcomponents.stdout.strip().split(" "):
        # print("COMPONENT: %s" % component)
        libs = mctx.execute([llvm_config_tool,
                             "--link-static",
                             "--libs",
                             component])
        # print("  LIBS: %s" % libs.stdout)
        ls = []
        for lib in libs.stdout.strip().split(" "):
            ls.append("\"lib" + lib[2:] + ".a\"")
        components[component] = ls

    ## now each lib
    xlibs = mctx.execute([llvm_config_tool,
                         "--link-static",
                         "--libs"])
    if xlibs.return_code != 0:
        print("ERROR llvm-config --link-static --libs: %s" % libs.stderr)

    libs_list = xlibs.stdout.strip().split(" ")
    # print("LIBS ct: %s" % len(libs_list))

    libs = {}
    for lib in libs_list:
        lb = lib[2:]
        libs[lb] = "lib" + lb + ".a"
    # print("LIBS: %s" % libs)

    return components, libs
    #### end of _libdeps ####

################
def _emit_config_file(mctx, sysroot, llvm_root, llvm_version, llvm_config_tool, bindir):

    cppflags = []
    cppdefines = []
    flags = mctx.execute([llvm_config_tool,
                             "--cppflags"]).stdout.strip()
    # print("cppflags: %s" % flags)
    for flag in flags.split(" "):
        if flag.startswith("-I"): continue
        if flag.startswith("-D"):
            cppdefines.append(flag[2:])
        else:
            cppflags.append(flag)


    cflags = []
    cdefines = []
    flags = mctx.execute([llvm_config_tool,
                           "--cflags"]).stdout.strip()
    # print("cflags: %s" % flags)
    for flag in flags.split(" "):
        if flag.startswith("-I"): continue
        # elif flag.startswith("-D"):
        #     cdefines.append(flag) # flag[2:])
        elif flag == "": continue
        else: cflags.append(flag)
    print("CFLAGS: %s" % cflags)

    cxxflags = []
    cxxdefines = []
    flags = mctx.execute([llvm_config_tool,
                             "--cxxflags"]).stdout.strip()
    # print("cxxflags: %s" % flags)
    for flag in flags.split(" "):
        if flag.startswith("-I"): continue
        elif flag.startswith("-D"):
            cxxdefines.append(flag[2:])
        elif flag == "": continue
        else: cxxflags.append(flag)

    ldflags = []
    flags = mctx.execute([llvm_config_tool,
                            "--ldflags"]).stdout.strip()
    # print("ldflags: %s" % flags)
    for flag in flags.split(" "):
        if flag.startswith("-L"): continue
        elif flag == "": continue
        else: ldflags.append(flag)

    xsyslibs = mctx.execute([llvm_config_tool,
                             "--system-libs"])
    if xsyslibs.return_code == 0:
        syslibs = xsyslibs.stdout.strip().split(" ")
    else:
        fail("FAIL: llvm-config --system-libs")

    xtargets = mctx.execute([llvm_config_tool,
                            "--targets-built"])
    if xtargets.return_code == 0:
        targets = xtargets.stdout.strip().split(" ")
    else:
        fail("FAIL: llvm-config --targets-built")

    builtin_include_dirs = _builtin_include_dirs(mctx, sysroot, llvm_root, llvm_version)
    # print("BUILTIN INC: %s" % builtin_include_dirs)

    # make_variables = [
    #     make_variable(
    #         name = "LLVM_CFLAGS",
    #         value = "-DFOO")
    # ]

    mctx.file(
        "CONFIG.bzl",
        content = """
load("@rules_cc//cc:cc_toolchain_config_lib.bzl", "make_variable")

CPPFLAGS = {cppflags}
CPPDEFINES = {cppdefines}

CFLAGS = {cflags}
CDEFINES = {cdefines}

CXXFLAGS = {cxxflags}
CXXDEFINES = {cxxdefines}

LDFLAGS = {ldflags}

SYSLIBS = {syslibs}

TARGETS = {targets}

TOOL_PATHS = {tool_paths}

BUILTIN_INCLUDE_DIRS = {builtin_include_dirs}

LLVM_MAKE_VARIABLES = [
    make_variable(
        name = "LLVM_CFLAGS",
        value = "{llvm_cflags}"
    )
]

""".format(
    cppflags = cppflags,
    cppdefines = cppdefines,
    cflags   = cflags,
    cdefines = cdefines,
    cxxflags = cxxflags,
    cxxdefines = cxxdefines,
    ldflags  = ldflags,
    syslibs  = syslibs,
    targets  = targets,
    tool_paths = make_tool_paths(bindir),
    builtin_include_dirs = builtin_include_dirs,
    llvm_cflags = " ".join(cflags)
)
        )

    return mctx.path("CONFIG.bzl")

    #### end of _emit_config_file ####

##############
_sdk_attrs = {
    # "targets": attr.string_list(
    #     doc = """Supported targets:
    #         AArch64, AMDGPU, ARM, AVR, BPF, Hexagon, Lanai, Mips,
    #         MSP430, NVPTX, PowerPC, RISCV, Sparc, SystemZ,
    #         WebAssembly, X86, XCore.
    #         Special targets: ALL, host
    #         """
    # )
}

######## TAG CLASSES ########
####
_llvm_config_attrs = dict(_sdk_attrs)
_llvm_config_attrs.update({
    "llvm_root": attr.string(),
    "version": attr.string(),
})
_llvm_config_tag = tag_class(attrs = _llvm_config_attrs)

####
_llvm_c_sdk_tag = tag_class(attrs = _sdk_attrs)

####
_llvm_ocaml_attrs = dict(_sdk_attrs)
_llvm_ocaml_attrs.update({
    "ocaml_srcs": attr.string()
})
_llvm_ocaml_sdk_tag = tag_class(attrs = _llvm_ocaml_attrs )

####
_clang_c_sdk_tag = tag_class(attrs = _sdk_attrs)


#### EXTENSION IMPL ####
# shared resources:
#   BUILD.bazel -> //version
#   lib/BUILD.bazel -> lib import targets

# each sdk will symlink to llvmroot/lib
# and will share the same  llvmroot/lib/BUILD.bazel
# which is written here, then symlinked into the sdk repos

# here we find and run llvmroot/bin/llvm-config
# so first step is to obtain llvm_root from
# llvm_config.llvm(llvm_root = ...)

def _llvm_ext_impl(mctx):
    # print("LLVM EXTENSION")

    # result = mctx.execute(["pwd"])
    # print("PWD: %s" % result.stdout)

    # result = mctx.execute(["env"])
    # print("PATH: %s" % result.stdout)

    # result = mctx.which("llvm-config")
    # print("which llvm-config: %s" % result)

    home = mctx.execute(["printenv", "HOME"])
    # print("home RC: %s" % home.return_code)
    # print("home stdout: %s" % home.stdout)
    # print("home stderr: %s" % home.stderr)
    home = home.stdout.strip()

    # wsroot = mctx.execute(["printenv", "BUILD_WORKSPACE_DIRECTORY"])
    # print("wsroot RC: %s" % wsroot.return_code)
    # print("wsroot stdout: %s" % wsroot.stdout)
    # print("wsroot stderr: %s" % wsroot.stderr)
    # wsroot = wsroot.stdout.strip()

    # pwd is modextwd/_main~llvm
    pwd = mctx.execute(["pwd"])
    # print("pwd RC: %s" % pwd.return_code)
    # print("pwd stdout: %s" % pwd.stdout)
    # print("pwd stderr: %s" % pwd.stderr)

    pwd = pwd.stdout.strip()

    llvm_root = None

    llvm_config = False
    llvm_config_version = None

    llvm_c_sdk = False
    llvm_c_sdk_version = None

    llvm_ocaml_sdk = False
    llvm_ocaml_sdk_version = None

    clang_c_sdk = False
    clang_c_sdk_version = None

    ## what happens if @llvm, @llvm_c_sdk etc.
    ## occur at multiple places in the graph?
    ## bzlmod would choose one (based on compatibility)
    ## but we would have multiple calls to this extension,
    ## from different module contexts.
    ## they could specify different llvm versions, then what?
    ## no reason that should not work?

    ## assumption for now: only once in build graph

    targets = []
    for mod in mctx.modules:
        # print("XMOD name: %s" % mod.name)
        # print("XMOD version: %s" % mod.version)
        # print("XMOD is_root: %s" % mod.is_root)
        # print("XMOD tags: %s" % mod.tags)
        # for d in dir(mod.tags):
        #     print("XMOD tag: %s" % d)
        #     a = getattr(mod.tags, d)
        #     for k in a:
        #         print("  attr: {}".format(k))

        if not mod.is_root: continue

        for cfg in mod.tags.config:
            # print("LLVM cfg: %s" % cfg)
            # print("llvm version: %s" % cfg.version)
            llvm_config = True

            ## llvm_root = path to file containing path to sdk
            if cfg.llvm_root:
                # print("LLVM_ROOT: %s" % cfg.llvm_root)

                lbl = Label(cfg.llvm_root)

                # print("lbl: %s" % lbl)
                wsname = lbl.workspace_name
                # print("lbl.workspace_name: %s" % wsname)
                # print("lbl.workspace_root: %s" % lbl.workspace_root)
                if wsname == "": ## root module
                    wsroot_path = mctx.path(Label("@@//:MODULE.bazel")).dirname
                    # print("wsroot_path %s" % wsroot_path)
                else:
                    l = Label("@@" + wsname + "//:MODULE.bazel")
                    wsroot_path = mctx.path(Label("@@" + wsname + "//:MODULE.bazel")).dirname
                    # print("wsroot_path %s" % wsroot_path)

                llvm_root_p = mctx.path(wsroot_path)
                # print("mctx.path(wsroot_path): %s" % llvm_root_p)

                basename = lbl.name
                # print("lbl.package: %s" % lbl.package)
                pkg_path = str(wsroot_path) + "/" + lbl.package
                pkg_path = mctx.path(pkg_path)
                # print("mctx.path(pkg_path): %s" % pkg_path)
                llvm_root = str(pkg_path) + "/" + basename
                # print("reconstructed llvm_root: %s" % llvm_root)
                llvm_root_p = mctx.path(llvm_root)
                # print("llvm_root exists? %s" % llvm_root_p.exists)
                if llvm_root_p.exists:
                    llvm_root = mctx.read(llvm_root).splitlines()[0]
                    # print("llvm_root: %s" % llvm_root)
                else:
                    print("NOT FOUND: llvm_root == {}".format(llvm_root))
                    fail("Not yet implemented: default kit")

                # llvm_root may point to a distro,
                # or a local src build, or it may be
                # None, in which case we download a distro.
                # repo setup depends on is_distro.
                # e.g. distros do not contain some tools,
                # like FileCheck and llvm-lit.
                # also includes are set up differently

                # if llvm_root.startswith("/"):
                #     # local
                # elif llvm_root == "llvm-project":
                #     # git clone?
                # else: # version string

                # distros contain dirs: bin, include, lib,
                # libexec, share
                # src builds contain CMakeCache.txt, etc.
                ptest = mctx.path(llvm_root + "/CMakeCache.txt")
                if ptest.exists:
                    # print("NOT DISTRO")
                    is_distro = False
                else:
                    # print("IS DISTRO")
                    is_distro = True

            else:
                ## if llvm_root is not passed,
                ## then we download and build llvm-project
                print("NO LLVM_ROOT")

            llvm_config_tool = llvm_root + "/bin/llvm-config"
            xllvm_version = mctx.execute([llvm_config_tool,
                                         "--version"])
            if xllvm_version.return_code == 0:
                llvm_version = xllvm_version.stdout.strip()
            else:
                fail("Cannot find bin/llvm-config in %s" % llvm_root)

            vsegs = llvm_version.split(".")
            compatibility_level = vsegs[0]

            xbindir = mctx.execute([llvm_config_tool,
                                    "--bindir"])
            if xbindir.return_code == 0:
                llvm_bindir = xbindir.stdout.strip()
            else:
                fail("FAILED: llvm-config --bindir")

            x = mctx.execute([llvm_config_tool,
                                    "--host-target"])
            if x.return_code == 0:
                host_triple = x.stdout.strip()
            else:
                fail("FAILED: llvm-config --host-target")

            x = mctx.execute(["xcrun", "--show-sdk-path"]) # MacOSX.sdk
            ## adding "--sdk", "macosx" results in MacOSX14.0.sdk, symlink to MacOSX.sdk
            if x.return_code == 0:
                sysroot = x.stdout.strip()
            else:
                fail("FAILED: xcrun --show-sdk-path --sdk macosx")

        for config in mod.tags.llvm_c_sdk:
            # print("LLVM C SDK config")
            llvm_c_sdk = True

        for config in mod.tags.llvm_ocaml_sdk:
            # print("OCAML SDK config")
            llvm_ocaml_sdk = True
            ocaml_srcs = config.ocaml_srcs

        for config in mod.tags.clang_c_sdk:
            # print("CLANG C SDK config")
            clang_c_sdk = True

    if not llvm_config:
        fail("llvm_config.llvm() is mandatory")

    # if c_sdk_version != ocaml_sdk_version:
    #     fail("Must use same version for all sdks")

    # mctx.file("WORKSPACE.bazel", content = "#test")
    # mctx.file("XXXXXXXXXXXXXXXXTEST", content = "#test")

    # share one version/BUILD.bazel across all sdks
    mctx.file(
        "VERSION.build",
        content = """
load("@bazel_skylib//rules:common_settings.bzl",
      "string_setting")

string_setting(
    name = "version", build_setting_default = "{}",
    visibility = ["//visibility:public"],
    )
""".format(llvm_version)
    )
    vfile = mctx.path("VERSION.build")
    # print("VFILE: %s" % vfile)

    ## all sdks share same `llvm-config` info
    ## (do we really need @llvm?)
    ## llvm-config --libs -> lib/BUILD.bazel
    ## llvm-config --cflags, etc -> CONFIG.bzl

    config_path = _emit_config_file(mctx, sysroot, llvm_root, llvm_version, llvm_config_tool, llvm_bindir)
    # print("CONFIG: %s" % config_path)

    components, libs = _libdeps(mctx, llvm_config_tool)
    # print("components: %s" % components)
    # print("LIBS: %s" % libs)

    ## finally create the extension repos
    repo_llvm(
        name = "llvm",
        home = home,
        version = llvm_version,
        compatibility_level = compatibility_level,
        version_file = str(vfile),
        llvm_root = llvm_root,
        llvm = "@llvm",
        config_path = str(config_path),
        bindir = llvm_bindir,
        host_triple = host_triple,
        sysroot = sysroot,
        targets = targets,
        components = components,
        libs = libs
    )

    # repo_llvm_tools(
    #     name = "llvm_tools",
    #     version = llvm_version,
    #     compatibility_level = compatibility_level,
    #     version_file = str(vfile),
    #     llvm_root = llvm_root,
    #     llvm_bindir = llvm_bindir,
    #     llvm = "@llvm",
    #     config_path = str(config_path),
    #     targets = targets,
    #     components = components,
    #     libs = libs
    # )

    if llvm_c_sdk:
        repo_llvm_c_sdk(name = "llvm_c_sdk",
                        version = llvm_version,
                        compatibility_level = compatibility_level,
                        version_file = str(vfile),
                        llvm_root = llvm_root,
                        llvm = "@llvm",
                        targets = targets,
                        components = components,
                        libs = libs,
                        is_distro = is_distro
                        )

    # if llvm_ocaml_sdk:
    #     repo_llvm_ocaml_sdk(
    #         name = "llvm_ocaml_sdk",
    #         version = llvm_version,
    #         compatibility_level = compatibility_level,
    #         version_file = str(vfile),
    #         llvm_root = llvm_root,
    #         ocaml_srcs = ocaml_srcs,
    #         llvm = "@llvm",
    #         llvm_c_sdk = "@llvm_c_sdk",
    #         targets = targets
    #     )

    if clang_c_sdk:
        repo_clang_c_sdk(
            name = "clang_c_sdk",
            version = llvm_version,
            compatibility_level = compatibility_level,
            version_file = str(vfile),
            llvm_root = llvm_root,
            llvm = "@llvm",
            targets = targets,
            components = components,
            libs = libs,
            is_distro = is_distro
        )

##############################
llvm = module_extension(
  implementation = _llvm_ext_impl,
  tag_classes = {
      "config": _llvm_config_tag,
      "llvm_c_sdk": _llvm_c_sdk_tag,
      "llvm_ocaml_sdk": _llvm_ocaml_sdk_tag,
      "clang_c_sdk": _clang_c_sdk_tag,
  }
)
