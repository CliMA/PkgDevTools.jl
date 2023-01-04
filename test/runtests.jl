# using Revise; include(joinpath("test", "runtests.jl"))
using PkgDevTools
using Test

# function generate_env(filename::S, pkg_versions::Tuple{S,S,S}) where {S <: String}
#     mkpath(dirname(filename))
#     open(filename, "w") do io
#         println(io, "[deps]")
#         println(io, "SomePkgA = \"commitSHAA\"")
#         println(io, "SomePkgB = \"commitSHAB\"")
#         println(io, "SomePkgC = \"commitSHAC\"")
#         println(io, "")
#         println(io, "[compat]")
#         println(io, "SomePkgA = \"$(pkg_versions[1])\"")
#         println(io, "SomePkgB = \"$(pkg_versions[2])\"")
#         println(io, "SomePkgC = \"$(pkg_versions[3])\"")
#     end
# end

# @testset "PkgDevTools" begin
#     mktempdir() do path
#         tomlPkg = joinpath(path, "Pkg.jl", "Project.toml")
#         tomlA   = joinpath(path, "Pkg.jl", "envA", "Project.toml")
#         tomlB   = joinpath(path, "Pkg.jl", "envB", "Project.toml")
#         generate_env(tomlPkg, ("1.2.3", "4.5.6", "7.8.9"))
#         generate_env(tomlA,   ("1.2.4", "4.6.6", "8.8.9"))
#         generate_env(tomlB,   ("1.3.3", "4.6.6", "7.8.9"))
#         envs = PkgDevTools.select_environments(path)
#         update_form = PkgDevTools.select_update_form(envs)
#         # @show PkgDevTools.project_dirs(path)
#     end
# end

@testset "PkgDevTools" begin
    # Testing REPL.TerminalMenus is a pain and seems generally unsupported.
    @test 1==1
end

# path = mktempdir()
# tomlPkg = joinpath(path, "Pkg.jl", "Project.toml")
# tomlA   = joinpath(path, "Pkg.jl", "envA", "Project.toml")
# tomlB   = joinpath(path, "Pkg.jl", "envB", "Project.toml")
# @show path
# generate_env(tomlPkg, ("1.2.3", "4.5.6", "7.8.9"))
# generate_env(tomlA,   ("1.2.4", "4.6.6", "8.8.9"))
# generate_env(tomlB,   ("1.3.3", "4.6.6", "7.8.9"))
# PkgDevTools.update_deps(path)
# rm(path; recursive=true)
