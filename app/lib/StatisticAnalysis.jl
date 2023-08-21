module StatisticAnalysis

export gen_numbers, calc_mean

function gen_numbers(N::Int)
    return rand(N)
end

function calc_mean(x::Vector{Float64})
    return sum(x) / length(x)
end
end
