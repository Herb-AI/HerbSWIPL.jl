using Julog: Const, Compound, Var, Clause, Term

"""
Julia -> SWIPL
"""

function to_swipl_ref(c::Const, previous_variables::Dict{Var,Cint}, ref::Cint)
    #println("to swipl constant $(c)")
    if isa(c.name, Symbol)
        PL_put_atom_chars(ref, String(c.name))
    elseif isa(c.name, Int64)
        PL_put_integer(ref, c.name)
    elseif isa(c.name, Float64)
        PL_put_float(ref, c.name)
    elseif isa(c.name, String)
        PL_put_string_chars(ref, c.name)
    end
   
end

function to_swipl(c::Const, previous_variables::Dict{Var,Cint})
    ref = PL_new_term_ref()
    to_swipl_ref(c, previous_variables, ref)
    ref
end


function to_swipl_ref(v::Var, previous_variables::Dict{Var,Cint}, ref::Cint)
    #println("to swipl var $(v)")
    if haskey(previous_variables, v)
        PL_put_term(ref, previous_variables[v])
    else
        PL_put_variable(ref)
        previous_variables[v] = ref
    end
end

function to_swipl(v::Var, previous_variables::Dict{Var,Cint})
    if haskey(previous_variables, v)
        previous_variables[v]
    else
        tmpv = PL_new_term_ref()
        PL_put_variable(tmpv)
        previous_variables[v] = tmpv
        tmpv
    end
end

function create_functor(name::Symbol, arity::Int64)
    #println("create functor $(name)")
    func_atm = PL_new_atom(String(name))
    func = PL_new_functor(func_atm, arity)
    func
end


function to_swipl_ref(c::Compound, previous_variables::Dict{Var,Cint}, ref::Cint)
    #println("to swipl compound $(c)")
    if c.name == :!  #negation
        negation_atom = PL_new_term_ref()
        PL_put_atom_chars(negation_atom, "\\+")
        negation_functor = PL_new_functor(negation_atom, 1)

        lit = to_swipl_(c.args[1], previous_variables)

        PL_cons_functor(ref, negation_functor, lit)
    elseif c.name == :cend   # empty-list symbol
        PL_put_nil(ref)
    elseif c.name == :cons # cons/pair list 
        head_term = PL_new_term_ref()
        to_swipl_ref(c.args[1], previous_variables, head_term)
        to_swipl_ref(c.args[2], previous_variables, ref)
        PL_cons_list(ref, head_term, ref)
    else   # generic compound
        func = create_functor(c.name, length(c.args))

        compound_arg = PL_new_term_refs(length(c.args))
        to_swipl_ref(c.args[begin], previous_variables, compound_arg)
        for ind in 1:(length(c.args)-1)
            to_swipl_ref(c.args[begin+ind], previous_variables, convert(Int32, compound_arg+ind))
        end

        PL_cons_functor(ref, func, compound_arg)
    end
end

function to_swipl(c::Compound, previous_variables::Dict{Var,Cint})
    structure = PL_new_term_ref()
    to_swipl_ref(c, previous_variables, structure)
    structure
end


function conjoin_swipl(ls::Vector{Cint})
    if length(ls) == 1
        ls[begin]
    else
        c_atom = PL_new_atom(",")
        conj_functor = PL_new_functor(c_atom, 2)

        compound_arg =PL_new_term_refs(2)
        conj = PL_new_term_ref()
        PL_put_term(compound_arg, ls[begin])
        PL_put_term(convert(Int32, compound_arg+1), conjoin_swipl(ls[begin+1:end]))
        PL_cons_functor(conj, conj_functor, compound_arg)

        conj
    end
end


function to_swipl_ref(c::Clause, previous_variables::Dict{Var,Cint}, ref::Cint)
    head_lit = to_swipl(c.head, previous_variables)
    body_lits = [to_swipl(x, previous_variables) for x in c.body]
    body_terms = conjoin_swipl(body_lits)

    clause_atom = PL_new_atom(":-")
    clause_functor = PL_new_functor(clause_atom, 2)

    compound_args = PL_new_term_refs(2)
    PL_put_term(compound_args, head_lit)
    PL_put_term(convert(Int32, compound_args+1), body_terms)
    PL_cons_functor(ref, clause_functor, compound_args)
end

function to_swipl(c::Clause, previous_variables::Dict{Var,Cint})
    entire_clause = PL_new_term_ref()
    to_swipl_ref(c, previous_variables, entire_clause)
    entire_clause
end






"""
    SWIPL -> Julia
"""

swipl_to_int(term::Cint) = Const(convert(Int64, PL_get_integer(term))) 

swipl_to_float(term::Cint) = Const(convert(Float64, PL_get_float(term)))

function swipl_to_atom(term::Cint)
    name = PL_get_atom_chars(term)
    if islowercase(name[begin])
        Const(Symbol(name))
    else
        Const("\"$(name)\"")
    end
end

swipl_to_string(term::Cint) = Const(PL_get_chars(term))

function swipl_to_var(term::Cint, term_to_var::Dict{Cint,Var})
    if haskey(term_to_var, term)
        term_to_var[term]
    else
        existing_names = Set(x.name for x in values(term_to_var))
        available_names = [x for x in 'A':'Z' if !in(x, existing_names)]
        if length(available_names) == 0
            available_names = ["$x$y" for x in 'A':'Z' for y in 'A':'Z' if !in("$x$y", existing_names)]
        end

        new_name = available_names[begin]
        new_var = Var(Symbol(new_name))
        term_to_var[term] = new_var
        new_var
    end
end


function to_pair_list(elems::Vector{Term})
   if length(elems) == 1
        push!(elems, Compound(:cend, []))
        Compound(:cons, elems)
   else
        args = Vector{Term}(undef, 2)
        args[1] = elems[begin]
        args[2] = to_pair_list(elems[2:end])
        Compound(:cons, args)
   end
end

function swipl_to_list(term::Cint)
    elements = Vector{Term}()
    list = PL_copy_term_ref(term)

    head = PL_new_term_ref()

    while PL_get_list(list, head, list)
        push!(from_swipl(head), elements)
    end

    to_pair_list(elements)
end

function swipl_to_pair(term::Cint)
    head = PL_new_term_ref()
    tail = PL_new_term_ref()

    PL_get_head(term, head)
    PL_get_tail(term, tail)

    Compound(:cons, Vector{Term}([from_swipl(head), from_swipl(tail)]))
end

function swipl_to_compound(term::Cint, term_to_var::Dict{Cint, Var})
    name, arity = PL_get_compound_name_arity(term)
    functor_name = PL_atom_chars(name)

    elems = Vector{Term}(undef, arity)
    for arg_index in 1:arity
        elem = PL_new_term_ref()
        PL_get_arg(arg_index, term, elem)
        elems[arg_index] = from_swipl(elem, term_to_var)
        # push!(elems, from_swipl(elem, term_to_var))
    end

    Compound(Symbol(functor_name), elems)
end

function from_swipl(term::Cint, term_to_var::Dict{Cint,Var})
    #println("from swipl")
    term_type = PL_term_type(term)
    #println("term type: $(term_type)")
    if PL_is_atom(term)
        #println("is atom")
        swipl_to_atom(term)
    elseif PL_is_string(term)
        swipl_to_string(term)
    elseif PL_is_integer(term)
        #println("is integer")
        swipl_to_int(term)
    elseif PL_is_float(term)
        #println("is float")
        swipl_to_float(term)
    elseif PL_is_list(term)
        #println("is list")
        swipl_to_list(term)
    elseif PL_is_compound(term)
        #println("is compound")
        swipl_to_compound(term, term_to_var)
    elseif PL_is_variable(term)
        #println("is variable")
        swipl_to_var(term, term_to_var)
    else
        error("unknown term type $(PL_term_type(term))")
    end
end

from_swipl(term::Cint) = from_swipl(term, Dict{Cint,Var}())





"""
    High-level interface
"""

function start(prolog::Swipl)
    PL_start()
    prolog.initiated = true
end

function stop(prolog::Swipl)
    PL_stop()
    prolog.initiated = false
end

function cleanup(prolog::Swipl)
    PL_cleanup()
    prolog.initiated = false
end

is_initialised(prolog::Swipl) = PL_is_initialised()

function abstract_assert(prolog::Swipl, predicate::String, clause::Union{Term,Clause})
    ##println("abstract_assert: $(predicate) and $(clause)")
    vars = Dict{Var,Cint}()
    swipl_repr = to_swipl(clause, vars)

    assert_pred = PL_predicate(predicate, 1)
    query = PL_open_query(assert_pred, swipl_repr)
    r = PL_next_solution(query)
    PL_close_query(query)

    r
end

asserta(prolog::Swipl, clause::Union{Term,Clause}) = abstract_assert(prolog, "asserta", clause)
assertz(prolog::Swipl, clause::Union{Term,Clause}) = abstract_assert(prolog, "assertz", clause)

function retract(prolog::Swipl, clause::Union{Clause,Term})
    vars = Dict{Var, Cint}()
    swipl_repr = to_swipl(clause, vars)

    retract_pred = PL_predicate("retract", 1)
    query = PL_open_query(retract_pred, swipl_repr)
    r = PL_next_solution(query)
    PL_close_query(query)

    r
end

function is_fact(clause::Clause)
    length(clause.body) == 0
end

function _assert_all(prolog::Swipl, clauses::Vector{Clause})
    for cl in clauses
        is_fact(cl) ? assertz(prolog, cl.head) : assertz(prolog, cl)
    end
end

function _retract_all(prolog::Swipl, clauses::Vector{Clause})
    for cl in clauses
        is_fact(cl) ? retract(prolog, cl.head) : retract(prolog, cl)
    end
end

function resolve(prolog::Swipl, query::Compound, clauses::Vector{Clause}; options...)
    #println("running resolve with $(query) and $(clauses)")
    #Unpakc options
    mode = get(options, :mode, :all)::Symbol  #:all, :any, :max
    if mode == :all
        max_solutions = -1
    elseif mode == :any
        max_solutions = 1
    else
        max_solutions = get(options, :max_solutions, -1)::Int64
    end
    keep_kb = get(options, :keep, false)::Bool

    _assert_all(prolog, clauses)

    query_vars = Dict{Var, Cint}()
    query_args = PL_new_term_refs(length(query.args))

    for ind = 0:length(query.args)-1
        to_swipl_ref(query.args[begin+ind], query_vars, convert(Int32, query_args+ind))
    end

    term_to_var_map = Dict((value, key) for (key, value) in query_vars)

    pred = PL_predicate(String(query.name), length(query.args))
    query = PL_open_query(pred, query_args)

    r = PL_next_solution(query)

    worked::Bool = r > 0 ? true : false

    all_solutions = Vector{Dict{Var,Term}}( )

    while r == 1 & (max_solutions != 0)
        max_solutions -= 1

        current_solution = Dict{Var,Term}()
        for (var, value) in query_vars
            current_solution[var] = from_swipl(value, term_to_var_map)
        end
        #println("pushing $(current_solution) to all_solutions")
        push!(all_solutions, current_solution)

        r = PL_next_solution(query)
    end

    PL_close_query(query)

    if ! keep_kb
        _retract_all(prolog, clauses)
    end

    worked, all_solutions
end

const swipl_resolve = HerbSWIPL.resolve




"""
    Foreign function interface
"""


function PL_register_foreign_deterministic(f::Function)
    func_name = String(Symbol(f))
    arity = first(methods(f)).nargs - 1

    eval(quote
    myfunc = function wrapping_func(term::Cint, arity::Cint, context::Ptr{Cvoid})
        # Unpack arguments to Julog terms
        julia_args = [from_swipl(convert(Cint, term+ind)) for ind in 0:(arity-1)]
        success, to_unify = $f(julia_args...)

        if success
            # if successful, unify what was provided
            for (arg_ind, val) in to_unify
                new_term = PL_new_term_ref()
                to_swipl_ref(val, Dict{Var,Cint}(), new_term)
                PL_unify_arg(arg_ind, term, new_term)
            end
        end

        return convert(Cint, success ? 1 : 0) 
    end
    end)

    eval(quote c_func = @cfunction(myfunc, Cint, (Cint, Cint, Ptr{Cvoid})) end)
    
    PL_register_foreign(func_name, arity, c_func, convert(Int64, PL_FA_VARARGS))
end

function register_foreign(f::Function; options...)
    #unpack options
    mode = get(options, :mode, :det)::Symbol  # :det or :stoch

    if mode == :det
        PL_register_foreign_deterministic(f)
    else
        println("not supported yet")
    end
end