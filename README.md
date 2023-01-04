# PkgDevTools.jl

Some utility functions for helping with customized Pkg.jl operations

## Usage

PkgDevTools is a _development_ tool, to be added to a user's default julia environment, and is not intended to be a dependency of any packages. PkgDevTools provides functions for batching environment changes across several environments.

There are two exported functions, which can be used as follows:

```julia
using PkgDevTools
add_to_deps("SomePackage"; #=branch=,version=,compat= =#)
```

```julia
using PkgDevTools
update_deps()
```

Follow the prompts through.
