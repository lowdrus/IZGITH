
# module_d_julia.jl
# Pós-processa exports do ChatGPT (JSON/HTML) -> MD + estatísticas

using JSON

function read_text(path::String)
    open(path, "r") do io
        return read(io, String)
    end
end

function to_markdown(messages)
    out = ["# Conversa (pós-processada em Julia)", ""]
    i = 0
    for m in messages
        i += 1
        label = m["role"] == "user" ? "✅iarate" : (m["role"] == "assistant" ? "✅Aelly" : m["role"])
        push!(out, "**$(i). $(label)**")
        push!(out, m["text"])
        push!(out, "")
    end
    return join(out, "\n")
end

function process_json(path::String, out::String)
    data = JSON.parse(read_text(path))
    messages = haskey(data, "fragments") ? data["fragments"] : data
    md = to_markdown(messages)
    open(out, "w") do io
        write(io, md)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) < 2
        println("Uso: julia module_d_julia.jl <in.json> <out.md>")
    else
        process_json(ARGS[1], ARGS[2])
        println("[OK] Gerado $(ARGS[2])")
    end
end
