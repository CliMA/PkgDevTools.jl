"""
    with_precompile_set(fn; precompile=false)

Call `fn()` while temporarily setting
`ENV["JULIA_PKG_PRECOMPILE_AUTO"] = 0`.
"""
function with_precompile_set(fn; precompile=false)
    # ENV does not always have JULIA_PKG_PRECOMPILE_AUTO
    # precompile_value = ENV["JULIA_PKG_PRECOMPILE_AUTO"]
    x = "JULIA_PKG_PRECOMPILE_AUTO"
    precompile₀ = haskey(ENV, x) ? ENV[x] : nothing
    if !precompile
        @info "Temporarily setting ENV[$x] = 0"
        ENV[x] = 0
    end
    fn()
    if !precompile
        if isnothing(precompile₀); pop!(ENV, x)
        else; ENV[x] = precompile₀
        end
    end
    return precompile₀
end

is_project_file(f) = startswith(f, "Project.toml") || startswith(f, "JuliaProject.toml")

function get_project_file(dir)
    return if isfile(joinpath(dir, "Project.toml"))
        joinpath(dir, "Project.toml")
    elseif isfile(joinpath(dir, "JuliaProject.toml"))
        joinpath(dir, "JuliaProject.toml")
    else
        error("Could not find Project.toml in $dir to automatically determine the package name.")
    end
end

function get_pkg_name_from_pwd(dir=pwd())
    project_file = get_project_file(dir)
    pkgname_line = readlines(project_file)[1]
    return split(pkgname_line, "\"")[2]
end

function project_dirs(dir = pwd())
    paths = String[]
    for (root, dirs, files) in Base.Filesystem.walkdir(dir)
        for f in files
            if is_project_file(f)
                push!(paths, dirname(joinpath(root, f)))
                continue
            end
        end
    end
    return paths
end

function select_environments(root = pwd())
    options = project_dirs(root)
    menu = MultiSelectMenu(options; charset=:ascii) # charset=:unicode is not supported in earlier Julia versions
    choices = request("Select environments to work on:", menu)
    return map(c->options[c], collect(choices))
end

function select_main_pkg_user_defined(envs)
    options = envs
    menu = RadioMenu(options, pagesize=4)
    local choices
    while true
        choices = request("Select main package to be developed:", menu)
        if !(choices in ntuple(i->i, length(envs)))
            @info "Invalid option. Valid options: $options"
        else
            break
        end
    end
    return envs[choices]
end

function select_main_pkg(root, envs)
    options = ["Yes", "no"]
    menu = RadioMenu(options, pagesize=4)
    local choices
    while true
        choices = request("Okay to develop $root from all other environments that have it as a dependency?", menu)
        if !(choices in ntuple(i->i, length(options)))
            @info "Invalid option. Valid options: $options"
        else
            break
        end
    end
    if choices == 1
        return root
    else
        return select_main_pkg_user_defined(envs)
    end
end

function depends_on_main_pkg(env, main_pkg)
    project_file = get_project_file(env)
    project = Pkg.Types.read_project(project_file).deps
    return main_pkg in keys(project)
end

function has_tracked_manifest(dir)
    manifest = joinpath(dir, "Manifest.toml")
    if isfile(manifest)
        try
            # will error if not tracked
            run(`git ls-files --error-unmatch $manifest`)
            return true
        catch
        end
    end
    return false
end

function select_update_form(root, envs)
    main_pkg = select_main_pkg(root, envs)
    update_form = Dict()
    for (i, env) in enumerate(envs)
        # has_tracked_manifest(env) # this will also skip test/
        if env==main_pkg
            update_form[env] = :main
        elseif depends_on_main_pkg(env, main_pkg)
            update_form[env] = :develop
        else
            update_form[env] = :no_develop
        end
    end
    return update_form
end
