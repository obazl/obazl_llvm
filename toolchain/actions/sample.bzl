# https://bazel.build/docs/cc-toolchain-config-reference#example-usage

##load("@rules_cc//cc:defs.bzl", "ACTION_NAMES")

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")

action_configs = [
    action_config (
        action_name = ACTION_NAMES.cpp_link_executable,
        tools = [
            tool(
                with_features = [
                    with_feature(features=["generate-debug-symbols"]),
                ],
                path = "toolchain/mac/ld-with-dsym-packaging",
            ),
            tool (path = "toolchain/mac/ld"),
        ],
    ),
]

features = [
    feature(
        name = "generate-debug-symbols",
        flag_sets = [
            flag_set (
                actions = [
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-g"],
                    ),
                ],
            )
        ],
        implies = ["unbundle-debuginfo"],
   ),
]
