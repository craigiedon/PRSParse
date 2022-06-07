using CombinedParsers
import CombinedParsers: word, words

function evaluate_arithmetic( (start, operation_values))
    aggregated_value::Number = start 
    for (op, val) in operation_values
        aggregated_value = eval(Expr(:call, Symbol(op), aggregated_value, val))
    end
    return aggregated_value
end

@syntax arith_subterm = Either{Number}([NumericParser(Float64)]; convert=true)

@syntax for parentheses in arith_subterm
    mult = evaluate_arithmetic |> join(arith_subterm, trim(CharIn("*/")), infix=:prefix)
    @syntax arith_term = evaluate_arithmetic |> join(mult, trim(CharIn("+-")), infix=:prefix)
    Sequence(2, trim('('), arith_term, trim(')'))
end

@syntax distribution = Either(
    Sequence(:dt => "Uniform", "(", :start => trim(arith_term), :end => trim(arith_term), ")"),
    Sequence(:dt => "Normal", "(", :mean => trim(arith_term), :end => trim(arith_term), ")")
)


@syntax var_assign = Sequence(
    :label => word, trim("="),
    :value => trim(
        Either(
            arith_term,
            distribution
        ),
        whitespace=horizontal_space_maybe)
    )


@syntax prs = Repeat(trim(var_assign, whitespace=vertical_space_maybe))

d = prs("x = (10 + 5) /  30
y = Uniform(1, 7)
z = Normal(0, 1.0)
w = 4")

for s in d
    println("label: ", s.label, " value: ", s.value)
end