NODE_TOOLCHAIN_BUILD_FILE = """
package(default_visibility = [ "//visibility:public" ])
exports_files([
  "bin/node",
  "bin/npm",
])
filegroup(
  name = "node_tool",
  srcs = [ "bin/node" ],
)
filegroup(
  name = "npm_tool",
  srcs = [ "bin/npm" ],
)
"""

def _mirror_path(ctx, workspace_root, path):
  src = '/'.join([workspace_root, path])
  dst = '/'.join([ctx.path('.'), path])
  ctx.symlink(src, dst)


def _node_toolchain_impl(ctx):
  os = ctx.os.name
  if os == 'linux':
    noderoot = ctx.path(ctx.attr._linux).dirname
  elif os == 'mac os x':
    noderoot = ctx.path(ctx.attr._darwin).dirname
  else:
    fail("Unsupported operating system: " + os)

  _mirror_path(ctx, noderoot, "bin")
  _mirror_path(ctx, noderoot, "include")
  _mirror_path(ctx, noderoot, "lib")
  _mirror_path(ctx, noderoot, "share")

  ctx.file("WORKSPACE", "workspace(name = '%s')" % ctx.name)
  ctx.file("BUILD", NODE_TOOLCHAIN_BUILD_FILE)
  ctx.file("BUILD.bazel", NODE_TOOLCHAIN_BUILD_FILE)


_node_toolchain = repository_rule(
    _node_toolchain_impl,
    attrs = {
        "_linux": attr.label(
            default = Label("@nodejs_linux_amd64//:WORKSPACE"),
            allow_files = True,
            single_file = True,
        ),
        "_darwin": attr.label(
            default = Label("@nodejs_darwin_amd64//:WORKSPACE"),
            allow_files = True,
            single_file = True,
        ),
    },
)

def node_repositories(version="8.5.0",
                      linux_sha256="0000710235e04553147b9c18deadc7cefa4297d4dce190de94cc625d2cf6b9ba",
                      darwin_sha256="0c8d4c4d90f858a19a29fe1ae7f42b2b7f1a4d3caaa25bea2e08479c00ebbd5f"):
    native.new_http_archive(
        name = "nodejs_linux_amd64",
        url = "https://nodejs.org/dist/v{version}/node-v{version}-linux-x64.tar.gz".format(version=version),
        type = "tar.gz",
        strip_prefix = "node-v{version}-linux-x64".format(version=version),
        sha256 = linux_sha256,
        build_file_content = "",
    )

    native.new_http_archive(
        name = "nodejs_darwin_amd64",
        url = "https://nodejs.org/dist/v{version}/node-v{version}-darwin-x64.tar.gz".format(version=version),
        type = "tar.gz",
        strip_prefix = "node-v{version}-darwin-x64".format(version=version),
        sha256 = darwin_sha256,
        build_file_content = "",
    )

    _node_toolchain(
        name = "org_pubref_rules_node_toolchain",
    )
