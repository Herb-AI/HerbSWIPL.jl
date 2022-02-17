const SWIPL_LIB = "libswipl"

"""
    Flags
#ifdef PL_KERNEL
#define PL_Q_DEBUG              0x0001  /* = TRUE for backward compatibility */
#endif
#define PL_Q_NORMAL             0x0002  /* normal usage */
#define PL_Q_NODEBUG            0x0004  /* use this one */
#define PL_Q_CATCH_EXCEPTION    0x0008  /* handle exceptions in C */
#define PL_Q_PASS_EXCEPTION     0x0010  /* pass to parent environment */
#define PL_Q_ALLOW_YIELD        0x0020  /* Support I_YIELD */
#define PL_Q_EXT_STATUS         0x0040  /* Return extended status */
#ifdef PL_KERNEL
#define PL_Q_DETERMINISTIC      0x0100  /* call was deterministic */
#endif
"""

const PL_Q_DEBUG = 0x0001
const PL_Q_NORMAL = 0x0002
const PL_Q_NODEBUG = 0x0004
const PL_Q_CATCH_EXCEPTION = 0x0008
const PL_Q_PASS_EXCEPTION = 0x0010
const PL_Q_ALLOW_YIELD = 0x0020
const PL_Q_EXT_STATUS = 0x0040

"""
    Term types 
#define PL_VARIABLE      (1)            /* nothing */
#define PL_ATOM          (2)            /* const char * */
#define PL_INTEGER       (3)            /* int */
#define PL_RATIONAL      (4)            /* rational number */
#define PL_FLOAT         (5)            /* double */
#define PL_STRING        (6)            /* const char * */
#define PL_TERM          (7)
#define PL_NIL           (8)            /* The constant [] */
#define PL_BLOB          (9)            /* non-atom blob */
#define PL_LIST_PAIR     (10)           /* [_|_] term */
                                        /* PL_unify_term() */
#define PL_FUNCTOR       (11)           /* functor_t, arg ... */
#define PL_LIST          (12)           /* length, arg ... */
#define PL_CHARS         (13)           /* const char * */
#define PL_POINTER       (14)           /* void * */
"""

const PL_VARIABLE = 1
const PL_ATOM = 2
const PL_INTEGER = 3
const PL_FLOAT = 5
const PL_STRING = 6
const PL_TERM = 7
const PL_NIL = 8
const PL_LIST_PAIR = 10
const PL_FUNCTOR = 11



"""
Foreign functions Flags

#define PL_FA_NOTRACE           (0x01)  /* foreign cannot be traced */
#define PL_FA_TRANSPARENT       (0x02)  /* foreign is module transparent */
#define PL_FA_NONDETERMINISTIC  (0x04)  /* foreign is non-deterministic */
#define PL_FA_VARARGS           (0x08)  /* call using t0, ac, ctx */
#define PL_FA_META              (0x40)  /* Additional meta-argument spec */
#define PL_FA_SIG_ATOMIC        (0x80)  /* Internal: do not dispatch signals */
"""

const PL_DETERMINISTIC = 0
const PL_FA_META = 0x40
const PL_FA_TRANSPARENT = 0x02
const PL_FA_NONDETERMINISTIC = 0x04
const PL_FA_NOTRACE = 0x01
const PL_FA_VARARGS = 0x08



"""
 Functions for starting and shutting down the SWIPL instance
"""
function PL_start(exec_path::String)
    argv = [exec_path, "-q"]
    ccall((:PL_initialise, SWIPL_LIB), Cint, (Cint, Ptr{Ptr{UInt8}}), length(argv), argv)
end

PL_start() = PL_start("/usr/local/bin/swipl")

function PL_is_initialised(exec_path::String)
    argv = [exec_path, "-q"]
    ccall((:PL_is_initialised, SWIPL_LIB), Cint, (Cint, Ptr{Ptr{UInt8}}), length(argv), argv)
end

PL_is_initialised() = PL_is_initialised()

function PL_stop(status::Int64)
    ccall((:PL_halt, SWIPL_LIB), Cint, (Cint,), convert(Cint, status))
end

PL_stop() = PL_stop(0)

function PL_cleanup(status::Int64)
    ccall((:PL_cleanup, SWIPL_LIB), Cint, (Cint,), status)
end

PL_cleanup() = PL_cleanup(0)



"""
    Atoms and functors
"""

function PL_new_atom(name::String)
    name_to_use = collect([convert(UInt8, c) for c in name])
    ccall((:PL_new_atom, SWIPL_LIB), Cint, (Cstring,), name) #Cstring(pointer(name)))
end

function PL_atom_chars(term::Cint)
    r = ccall((:PL_atom_chars, SWIPL_LIB), Cstring, (Cint,), term)
    unsafe_string(r)
end

function PL_new_functor(atom::Cint, arity::Int64)
    ccall((:PL_new_functor, SWIPL_LIB), Cint, (Cint, Cint), atom, convert(Cint, arity))
end


function PL_functor_name(functor::Cint)
    ccall((:PL_functor_name, SWIPL_LIB), Cint, (Cint,), functor)
end

function PL_functor_arity(functor::Cint)
    ccall((:PL_functor_arity, SWIPL_LIB), Cint, (Cint,), functor)
end







"""
    Testing types of terms
"""

function PL_term_type(term::Cint)
    ccall((:PL_term_type, SWIPL_LIB), Cint, (Cint,), term)
end

function PL_is_variable(term::Cint)
    ccall((:PL_is_variable, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_ground(term::Cint)
    ccall((:PL_is_ground, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_atom(term::Cint)
    ccall((:PL_is_atom, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_string(term::Cint)
    ccall((:PL_is_string, SWIPL_LIB), Cint, (Cint,), term) > 0
end


function PL_is_integer(term::Cint)
    ccall((:PL_is_integer, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_float(term::Cint)
    ccall((:PL_is_float, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_callable(term::Cint)
    ccall((:PL_is_callable, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_compound(term::Cint)
    ccall((:PL_is_compound, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_list(term::Cint)
    ccall((:PL_is_list, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_pair(term::Cint)
    ccall((:PL_is_pair, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_atomic(term::Cint)
    ccall((:PL_is_atomic, SWIPL_LIB), Cint, (Cint,), term) > 0
end

function PL_is_number(term::Cint)
    ccall((:PL_is_number, SWIPL_LIB), Cint, (Cint,), term) > 0
end


"""
    Getting data from terms
"""

function PL_get_atom(term::Cint)
    atm = Ref{Cint}(0)
    ccall((:PL_get_atom, SWIPL_LIB), Cint, (Cint, Ref{Cint}), term, atm)
    atm[]
end

function PL_get_chars(term::Cint)
    atm = Ref{Cstring}(C_NULL)
    ccall((:PL_get_chars, SWIPL_LIB), Cint, (Cint, Ref{Cstring}, Cint), term, atm, convert(Cint, 0x00000002))
    unsafe_string(atm[])
end

function PL_get_integer(term::Cint)
    atm = Ref{Cint}(0)
    ccall((:PL_get_integer, SWIPL_LIB), Cint, (Cint, Ref{Cint}), term, atm)
    atm[]
end

function PL_get_bool(term::Cint)
    atm = Ref{Cint}(0)
    ccall((:PL_get_bool, SWIPL_LIB), Cint, (Cint, Ref{Cint}), term, atm)
    atm[]
end


function PL_get_atom_chars(term::Cint)
    tmp = Ref{Cstring}(C_NULL)
    rc = ccall((:PL_get_atom_chars, SWIPL_LIB), Cint, (Cint, Ref{Cstring}), term, tmp)
    unsafe_string(tmp[])
end


function PL_get_float(term::Cint)
    val = Ref{Cfloat}(0)
    ccall((:PL_get_float, SWIPL_LIB), Cint, (Cint, Ref{Cfloat}), term, val)
    val[]
end


function PL_get_arity_name(term::Cint)
    name = Ref{Cint}(0)
    ar = Ref{Csize_t}(0)
    ccall((:PL_get_arity_name, SWIPL_LIB), Cint, (Cint, Ref{Cint}, Ref{Csize_t}), term, name, ar)
    (name[], ar[])
end


function PL_get_compound_name_arity(term::Cint)
    name = Ref{Cint}(0)
    ar = Ref{Csize_t}(0)
    ccall((:PL_get_compound_name_arity, SWIPL_LIB), Cint, (Cint, Ref{Cint}, Ref{Csize_t}), term, name, ar)
    (name[], ar[])
end


function PL_get_arg(index::Csize_t, term::Cint, term_result::Cint)
    ccall((:PL_get_arg, SWIPL_LIB), Cint, (Csize_t, Cint, Cint), index, term, term_result)
end


function PL_get_list(list::Cint, head::Cint, tail::Cint)
    ccall((:PL_get_list, SWIPL_LIB), Cint, (Cint, Cint, Cint), list, head, tail)
end




"""
    Constructing terms
"""
function PL_new_term_ref()
    ccall((:PL_new_term_ref, SWIPL_LIB), Cint, ())
end

function PL_new_term_refs(arity::Int64)
    ccall((:PL_new_term_refs, SWIPL_LIB), Cint, (Cint,), arity)
end

function PL_put_variable(term::Cint)
    ccall((:PL_put_variable, SWIPL_LIB), Cvoid, (Cint,), term)
end


function PL_put_atom(term::Cint, atom::Cint)
    ccall((:PL_put_atom, SWIPL_LIB), Cvoid, (Cint, Cint), term, atom)
end

function PL_put_bool(term::Cint, atom::Cint)
    ccall((:PL_put_bool, SWIPL_LIB), Cvoid, (Cint, Cint), term, atom)
end


function PL_put_atom_chars(term::Cint, name::String)
    ccall((:PL_put_atom_chars, SWIPL_LIB), Cint, (Cint, Cstring), term, name)
end

function PL_put_string_chars(term::Cint, name::String)
    ccall((:PL_put_string_chars, SWIPL_LIB), Cint, (Cint, Cstring), term, name)
end


function PL_put_integer(term::Cint, val::Int64)
    ccall((:PL_put_integer, SWIPL_LIB), Cint, (Cint, Clong), term, val)
end

function PL_put_float(term::Cint, val::Float64)
    ccall((:PL_put_float, SWIPL_LIB), Cint, (Cint, Cdouble), term, val)
end


function PL_put_functor(term::Cint, functor::Cint)
    ccall((:PL_put_functor, SWIPL_LIB), Cint, (Cint, Cint), term, functor)
end

function PL_put_term(term::Cint, functor::Cint)
    ccall((:PL_put_term, SWIPL_LIB), Cint, (Cint, Cint), term, functor)
end

function PL_put_list(term::Cint)
    ccall((:PL_put_list, SWIPL_LIB), Cint, (Cint,), term)
end

function PL_put_nil(term::Cint)
    ccall((:PL_put_nil, SWIPL_LIB), Cint, (Cint,), term)
end

function PL_copy_term_ref(term::Cint)
    ccall((:PL_copy_term_ref, SWIPL_LIB), Cint, (Cint,), term)
end

function PL_cons_functor(term::Cint, functor::Cint, compound_term::Cint)
    ccall((:PL_cons_functor_v, SWIPL_LIB), Cint, (Cint, Cint, Cint), term, functor, compound_term)
end

function PL_cons_list(term::Cint, head::Cint, tail::Cint)
    ccall((:PL_cons_list, SWIPL_LIB), Cint, (Cint, Cint, Cint), term, head, tail)
end







"""
    Unification
"""

function PL_unify(term1::Cint, term2::Cint)
    ccall((:PL_unify, SWIPL_LIB), Cint, (Cint, Cint), term1, term2)
end

function PL_unify_atom(term1::Cint, term2::Cint)
    ccall((:PL_unify, SWIPL_LIB), Cint, (Cint, Cint), term1, term2)
end

function PL_unify_bool(term::Cint, val::Bool)
    ccall((:PL_unify_book, SWIPL_LIB), Cint, (Cint, Cint), term, val)
end

function PL_unify_atom_chars(term::Cint, val::String)
    ccall((:PL_unify_atom_chars, SWIPL_LIB), Cint, (Cint, Cstring), term, val)
end

function PL_unify_string_chars(term::Cint, val::String)
    ccall((:PL_unify_string_chars, SWIPL_LIB), Cvoid, (Cint, Cstring), term, val)
end

function PL_unify_integer(term::Cint, val::Int64)
    ccall((:PL_unify_integer, SWIPL_LIB), Cint, (Cint, Cint), term, val)
end

function PL_unify_float(term::Cint, val::Float64)
    ccall((:PL_unify_float, SWIPL_LIB), Cint, (Cint, Cdouble), term, val)
end

function PL_unify_functor(term::Cint, functor::Cint)
    ccall((:PL_unify_functor, SWIPL_LIB), Cint, (Cint, Cint), term, functor)
end

function PL_unify_compound(term::Cint, functor::Cint)
    ccall((:PL_unify_compound, SWIPL_LIB), Cint, (Cint, Cint), term, functor)
end

function PL_unify_list(term::Cint, head::Cint, tail::Cint)
    ccall((:PL_unify_list, SWIPL_LIB), Cint, (Cint, Cint, Cint), term, head, tail)
end

function PL_unify_nil(term::Cint)
    ccall((:PL_unify_nil, SWIPL_LIB), Cint, (Cint, ), term)
end

function PL_unify_arg(index::Int64, term::Cint, arg_term::Cint)
    ccall((:PL_unify_arg, SWIPL_LIB), Cint, (Cint, Cint, Cint), index, term, arg_term)
end







"""
    Calling Prolog
"""

function PL_predicate(predicate_name::String, arity::Int64)
    ccall((:PL_predicate, SWIPL_LIB), Ptr{Cvoid}, (Cstring, Cint, Cstring), predicate_name, arity, C_NULL)
end

function PL_open_query(predicate_t::Ptr{Cvoid}, term::Cint, flag::UInt16)
    ccall((:PL_open_query, SWIPL_LIB), Cint, (Ptr{Cvoid}, Cint, Ptr{Cvoid}, Cint), C_NULL, flag, predicate_t, term)
end

PL_open_query(predicate_t::Ptr{Cvoid}, term::Cint) = PL_open_query(predicate_t, term, PL_Q_NORMAL)

function PL_next_solution(qid_t::Cint)
    ccall((:PL_next_solution, SWIPL_LIB), Cint, (Cint, ), qid_t)
end


function PL_cut_query(qid_t::Cint)
    ccall((:PL_cut_query, SWIPL_LIB), Cint, (Cint, ), qid_t)
end

function PL_close_query(qid_t::Cint)
    ccall((:PL_close_query, SWIPL_LIB), Cint, (Cint,), qid_t)
end



"""
    Foreign function interface
"""
function PL_register_foreign(name::String, arity::Int64, fnc::Ptr{Cvoid}, flag::Int64)
    ccall((:PL_register_foreign, SWIPL_LIB), Cint, (Cstring, Cint, Ptr{Cvoid}, Cint), name, arity, fnc, flag)
end

