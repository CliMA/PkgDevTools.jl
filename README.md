# PkgDevTools.jl

Some utility functions for helping with customized Pkg.jl operations

## Usage

PkgDevTools is a _development_ tool, to be added to a user's default julia environment, and is not intended to be a dependency of any packages. PkgDevTools provides functions for batching environment changes across several environments.

Here are some of the API functions (most use REPL tools, so you can follow prompts):

```julia
using PkgDevTools
update_deps([dir]) # update dependencies across environments
add_to_deps("SomePackage"; #=rev=,version=,compat=,url= =#) # add dependency across many environments
synchronize_compats([dir]) # synchronize compat entries across multiple environments
compat_kick_start([dir]) # suggest new compat entries in a folder with a Project.toml and Manifest.toml.
```

Note that we temporarily set `ENV["JULIA_PKG_PRECOMPILE_AUTO"] = 0` to speed up these operations. This means that nothing will actually be precompiled.
