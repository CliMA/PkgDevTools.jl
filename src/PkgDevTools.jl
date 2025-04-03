module PkgDevTools

export add_to_deps

using Pkg
using Base:UUID
using REPL.TerminalMenus

include("compat.jl")
include("utils.jl")

"""
    update_deps(
        root = pwd();
        pkg = nothing,
        precompile = false,
        auto_all = false
    )

Select from a few menus and let `PkgDevTools` update all the
(selected) environments you requested.

Setting `auto_all = true` will automatically update all environments, and `dev`
the base directory.
"""
function update_deps(root = pwd(); pkg = nothing, precompile = false, auto_all = false)
    with_precompile_set(; precompile) do
        envs = auto_all ? project_dirs(root) : select_environments(root)
        main_pkg = auto_all ? root : select_main_pkg(root, envs)
        update_form = select_update_form(root, envs, main_pkg)
        if precompile
            @info "Updating environments. This may take some time. Feel free to take a walk 🚶..."
        else
            @info "Updating environments. Skipping precompilation."
        end
        _up_deps(root; pkg, update_form, dirs=envs)
    end
    return nothing
end
function _up_deps(root; pkg, update_form, dirs)
    cd(root) do
        for dir in dirs
            reldir = relpath(dir, root)
            @info "Updating environment `$reldir`"
            if isnothing(pkg)
                cmd = if update_form[dir]==:main
                    `$(Base.julia_cmd()) --project -e """import Pkg; Pkg.update()"""`
                elseif update_form[dir]==:no_develop
                    `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.update()"""`
                elseif update_form[dir]==:develop
                    `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.develop(;path=\".\"); Pkg.update()"""`
                end
            else
                cmd = if update_form[dir]==:main
                    `$(Base.julia_cmd()) --project -e """import Pkg; Pkg.update(\"$pkg\")"""`
                elseif update_form[dir]==:no_develop
                    `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.update(\"$pkg\")"""`
                elseif update_form[dir]==:develop
                    `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.develop(;path=\".\"); Pkg.update(\"$pkg\")"""`
                end
            end
            run(cmd)
        end
    end

    # https://github.com/JuliaLang/Pkg.jl/issues/3014
    for dir in dirs
        cd(dir) do
            rm("LocalPreferences.toml"; force = true)
        end
    end
end

"""
    add_to_deps(
        name = nothing;
        version = nothing,
        rev = nothing,
        url = nothing,
        compat=nothing,
        root = pwd()
    )

Select from a few menus and let
`add_to_deps` adds `name` to
the environments you specify.
"""
function add_to_deps(
        name = nothing;
        rev = nothing,
        version = nothing,
        url = nothing,
        compat=nothing,
        root = pwd(),
        precompile = false,
    )
    envs = select_environments(root)
    update_form = select_update_form(root, envs)
    if precompile
        @info "Updating environments. This may take some time. Feel free to take a walk 🚶..."
    else
        @info "Updating environments. Skipping precompilation."
    end
    with_precompile_set(; precompile) do
        _add_to_deps(name; version, rev, url, compat, root, update_form, dirs=envs)
    end
end
function _add_to_deps(name; version, rev, url, compat, root, update_form, dirs)
    ver = isnothing(version) ? "" : "version=\"$version\""
    _rev = isnothing(rev) ? "" : "rev=\"$rev\""
    _url = isnothing(url) ? "" : "url=\"$url\""
    _name = isnothing(name) ? "" : "name=\"$name\""
    kwargs = join(filter(x->!isempty(x), (_name, ver,_rev,_url)), ",")
    cd(root) do
        for dir in dirs
            reldir = relpath(dir, root)
            @info "Updating environment `$reldir`"
            cmd = if update_form[dir]==:main
                `$(Base.julia_cmd()) --project -e """import Pkg; Pkg.add(Pkg.PackageSpec(;$kwargs))"""`
            elseif update_form[dir]==:no_develop
                `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.add(Pkg.PackageSpec(;$kwargs))"""`
            elseif update_form[dir]==:develop
                `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.develop(;path=\".\"); Pkg.add(Pkg.PackageSpec(;$kwargs))"""`
            end
            run(cmd)

            if !isnothing(compat)
                cmd = if update_form[dir]==:main
                    `$(Base.julia_cmd()) --project -e """import Pkg; Pkg.compat(\"$pkgname\", \"$compat\")"""`
                elseif update_form[dir]==:no_develop
                    `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.compat(\"$pkgname\", \"$compat\")"""`
                elseif update_form[dir]==:develop
                    `$(Base.julia_cmd()) --project=$reldir -e """import Pkg; Pkg.compat(\"$pkgname\", \"$compat\")"""`
                end
                run(cmd)
            end
        end
    end

    # https://github.com/JuliaLang/Pkg.jl/issues/3014
    for dir in dirs
        cd(dir) do
            rm("LocalPreferences.toml"; force = true)
        end
    end
    return nothing
end

end # module PkgDevTools
