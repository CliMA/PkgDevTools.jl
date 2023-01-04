# function project_direct_dependencies(project)
#     buffer = IOBuffer()
#     run(pipeline(
#         `$(Base.julia_cmd()) --project=$($project) -e 'using Pkg; print(Pkg.dependencies())'`;
#         stdout=buffer
#     ))
#     deps = eval(Meta.parse(String(take!(buffer))))
#     filter!(x->x.second.is_direct_dep, deps)
#     return deps
# end

#=
Packages are often organized into sub-packages
because they can be easily synchronized if they
exist in the same repository. It's often the case
that we want to use `Pkg.develop` for these dependencies
which is only known at the Manifest.toml level.
=#
# function find_subpackages(root)
#     envs = select_environments(root)
#     main_pkg_name = 

#     for env in envs
#         fp = joinpath(env, "Project.toml")
#         jfp = joinpath(env, "JuliaProject")
#         if isfile(fp)
#         elseif isfile(jfp)

#         else
#             @warn "Skipping environment $env"
#         end
#     project_contents = readlines(project)
#     deps = String[]
#     collect_deps = false
#     end_collection = false
#     for line in project_contents
#         end_collection && break
#         if is_deps(line)
#             collect_deps = true
#         end
#         if collect_deps
#             if line == ""
#                 end_collection = true
#             end
#         end
#         if collect_deps && !is_deps(line) && line ≠ ""
#             push!(deps, first(split(line, " = ")))
#         end
#     end

# end

# function subpackage_envs(pdirs)

# end
