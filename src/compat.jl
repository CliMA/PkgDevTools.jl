
export synchronize_compats
export kick_start_compat
import OrderedCollections
import REPL.TerminalMenus

if VERSION >= v"1.6.0"
    radio_menu(options; kwargs...) = TerminalMenus.RadioMenu(options; charset=:ascii, kwargs...)
else
    radio_menu(options; kwargs...) = TerminalMenus.RadioMenu(options; kwargs...)
end

is_deps(x) = startswith(x, "[[deps.") || startswith(x, "[deps]")
dep_match(x, dep) = x == "[[$dep]]" || x ==  "[[deps.$dep]]"

"""
    synchronize_compats(code_dir::AbstractString)

This function
 - Recursively finds all Project.toml files in `code_dir`
 - Collects the compat entries
 - Finds any inconsistent compat entries
 - Asks the user (via `REPL.TerminalMenus`) which
   version (if any) to update to, and modifies the
   Project.toml files accordingly.
"""
function synchronize_compats(code_dir::AbstractString = pwd())

    project_toml_files = [joinpath(root, f) for (root, dirs, files) in Base.Filesystem.walkdir(code_dir) for f in files if endswith(f, "Project.toml")]

    compat_entries = OrderedCollections.OrderedDict()
    for project_toml in project_toml_files
        contents = join(readlines(project_toml; keep=true))
        if !occursin("[compat]", contents)
            @warn "No compat entry found in $project_toml"
            continue
        end
        if !occursin("[compat]\n", contents)
            @warn "Compat header found, but no compat entry found in $project_toml"
            continue
        end
        compat_section = last(split(contents, "[compat]\n"))
        if occursin("\n\n", compat_section) # split by end of compat section
            compat_section = first(split(compat_section, "\n\n"))
        end
        compats = split(compat_section, "\n")
        filter!(x->!isempty(x), compats)
        compats = map(compats) do compat
            s = split(compat, "=")
            (strip(first(s)), replace(strip(last(s)), "\"" => ""), compat)
        end
        dir = dirname(project_toml)
        for (pkg, ver, line) in compats
            if haskey(compat_entries, pkg)
                ver in compat_entries[pkg] && continue
                push!(compat_entries[pkg], (ver, dir, line))
            else
                compat_entries[pkg] = [(ver, dir, line)]
            end
        end
    end

    inconsistent_compat_entries = OrderedCollections.OrderedDict()
    ice = inconsistent_compat_entries
    for k in keys(compat_entries)
        length(compat_entries[k]) == 1 && continue # only one env with this dep
        if length(unique(first.(compat_entries[k]))) ≠ 1
            ice[k] = compat_entries[k]
        end
    end
    @debug begin
        for k in keys(ice)
            println("$k = $(ice[k])")
        end
    end
    if length(keys(ice)) == 0
        @info "All compat entries are consistent! 🎉"
        return nothing
    end
    answers = OrderedCollections.OrderedDict()
    @info "$(length(keys(ice))) inconsistent compat entries found across $(length(project_toml_files)) toml files."
    for pkg in keys(ice)
        versions = getindex.(ice[pkg], 1)
        env_dirs = getindex.(ice[pkg], 2)
        lines = getindex.(ice[pkg], 3)
        entries = map(zip(versions, env_dirs)) do (ver, env_dir)
            "$ver ($(env_dir))"
        end
        options = [entries..., "Leave alone."]
        menu = radio_menu(options)
        msg = "Inconsistent compat entries found for $pkg. Select a compat entry (or leave alone):"
        choice = TerminalMenus.request(msg, menu)
        if !(choice == length(options))
            answers[pkg] = (env_dirs[choice], lines[choice], lines)
            @info "Changing compat entry for $pkg to $(lines[choice]) for all environments ($(env_dirs))"
        end
    end

    # Edit Project.toml files according to answers

    for project_toml in project_toml_files
        contents = join(readlines(project_toml; keep=true))
        new_contents = contents
        for pkg in keys(answers)
            all_compat_lines = last(answers[pkg])
            chosen_compat_line = getindex(answers[pkg], 2)
            for compat_line in all_compat_lines
                new_contents = replace(new_contents, compat_line => chosen_compat_line)
            end
        end
        open(project_toml, "w") do io
            print(io, new_contents)
        end
    end


end

"""
    kick_start_compat(
        code_dir::String,
        julia_version = "1.5.4";
        exact_versions = false
    )

Given a directory containing both a Project.toml and Manifest.toml,
print a string of a suggested compat entry for all Project.toml
dependencies. Set `exact_versions = true` for the printed compat
entries to exactly match the manifest file.
"""
function kick_start_compat(
        code_dir::AbstractString = pwd();
        julia_version = "1",
        exact_versions::Bool = false,
    )
    project = joinpath(code_dir, "Project.toml");
    manifest = joinpath(code_dir, "Manifest.toml");
    @assert isfile(project)
    @assert isfile(manifest)

    project_contents = readlines(project)
    deps = String[]
    collect_deps = false
    end_collection = false
    for line in project_contents
        end_collection && break
        if is_deps(line)
            collect_deps = true
        end
        if collect_deps
            if line == ""
                end_collection = true
            end
        end
        if collect_deps && !is_deps(line) && line ≠ ""
            push!(deps, first(split(line, " = ")))
        end
    end
    compat_entries = String[]
    manifest_contents = readlines(manifest)
    for dep in deps
        i = findfirst(x -> dep_match(x, dep), manifest_contents)
        i == nothing && continue
        j = findfirst(x -> x == "", manifest_contents[i:end])

        contents_block = manifest_contents[i:i+j-1]
        i_version_entry = findfirst(x->startswith(x, "version = "), contents_block)
        if i_version_entry == nothing
            continue # must be a stdlib
        end
        version_str = contents_block[i_version_entry]
        version_num = last(split(version_str, "version = "))
        if !exact_versions
            if !startswith(version_num, "\"0.")
                version_num = join(split(version_num, ".")[1:end-2], ".")*"\""
            else
                version_num = join(split(version_num, ".")[1:end-1], ".")*"\""
            end
        end

        push!(compat_entries, "$dep = $version_num")
    end
    push!(compat_entries, "julia = \"$julia_version\"")

    str = "[compat]\n"*join(compat_entries, "\n")
    print(str)
    return str
end
