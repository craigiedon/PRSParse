using ParserCombinator

struct VarAssgn
     label
     val
end

abstract type Samplable end

struct Uniform <: Samplable
    low :: Samplable
    high :: Samplable
end

struct Normal <: Samplable
    mean :: Samplable
    var :: Samplable
end

struct Const_Dist <: Samplable
    val :: Float64
end

@enum PosRel left_of right_of ahead_of behind above below 

function to_pos_rel(pr :: String) :: PosRel
    pr_map = Dict(
        "left of" => left_of,
        "right of" => right_of,
        "ahead of" => ahead_of,
        "behind" => behind,
        "above" => above,
        "below" => below
    )

    return pr_map[pr]
end

@enum Side left right top bottom front back
function to_side(s :: String) :: Side
    side_map = Dict(
        "top" => top,
        "bottom" => bottom,
        "left" => left,
        "right" => right,
        "back" => back,
        "front" => front
    )
    return side_map[s]
end

abstract type Specifier end

struct ObjConstruct
    class_name :: String
    specifiers :: Vector{Specifier}
end

struct ObjRef
    label_name :: String
end

const ObjRes = Union{ObjConstruct, ObjRef}

struct SideObj
    side_dirs :: Vector{Side}
    rel_obj :: ObjRes
end

function to_side_obj(s1 :: Side, rel_obj) :: SideObj
    SideObj([s1], rel_obj)
end

function to_side_obj(s1 :: Side, s2 :: Side, rel_obj) :: SideObj
    SideObj([s1, s2], rel_obj)
end


struct V3D
    x :: Samplable
    y :: Samplable
    z :: Samplable
end

const PointNode = Union{ObjRes, V3D, SideObj}

struct WithSpec <: Specifier
    prop_name :: String
    value :: Any
end


struct AtSpec <: Specifier
    value :: V3D
end

struct BeyondSpec <: Specifier
    beyond_obj :: PointNode
    amount :: Union{Float64, V3D}
    origin_perspective :: PointNode
end

struct InSpec <: Specifier
    in_obj :: ObjRes
end

struct RelSpec <: Specifier
    pr :: PosRel
    rel_obj :: PointNode
end

struct OnSpec <: Specifier
    completely :: Bool
    rel_obj :: PointNode
end

function on_spec_cons(on_tag :: String, rel_obj :: PointNode) :: OnSpec
    return OnSpec(on_tag == "completely on", rel_obj)
end


struct AlignedSpec <: Specifier
    rel_obj :: PointNode
    axis :: String
end

struct FacingSpec <: Specifier
    rel_vec :: V3D
end

struct FacingTowardsSpec <: Specifier
    rel_obj :: PointNode
end


function obj_cons(class_name, specs...) :: ObjConstruct
    sp_list :: Vector{Specifier} = [s for s in specs]
    return ObjConstruct(class_name, sp_list)
end



### The Grammar
## Arithmetic Expressions
spc = Drop(Star(Space()))
@with_pre spc begin
    # Distribution Expressions
    dist = Delayed()

    uni = (E"Uniform(" + spc + dist + spc + E"," + spc + dist + spc + E")") | (E"(" + spc + dist + spc + E"," + spc + dist + spc + E")") > Uniform
    norm = E"Normal(" + spc + dist + spc + E"," + spc + dist + spc + E")" > Normal
    c_dist = PFloat64() > Const_Dist

    dist.matcher = uni | norm | c_dist

    v3d_cons = E"V3D(" + spc + dist + E"," + spc + dist + spc + E"," + spc + dist + spc + E")" > V3D

    class_name = Not(Lookahead(v3d_cons | dist)) + p"[A-Z][\d\w]*"
    label_name = p"[a-z][\d\w]*"
    prop_name = p"[a-z][\d\w]*"

    obj_ref = label_name > ObjRef

    obj_res = Delayed()


    # Region Constructors
    # May not be necessary to explicitly set in language?
    # Cuboid
    # Rect3D
    # Halfspace
    # ConvexPolygon
    # ConvexPolyhedron
    # All
    # Empty

    relative_pos_ids = e"left of" | e"right of" | e"ahead of" | e"behind" | e"above" | e"below" > to_pos_rel
    sides_ids = e"top" | e"bottom" | e"left" | e"right" | e"back" | e"front" > to_side

    side_obj = Repeat(sides_ids, 1, 2) + obj_res > to_side_obj

    point_node = v3d_cons | side_obj | obj_res

    ### Specifiers
    ## Position Specifiers
    at_spec= E"at" + spc + v3d_cons > AtSpec
    in_spec = E"in" + spc + obj_res > InSpec
    rel_spec = relative_pos_ids + spc + point_node > RelSpec
    on_spec = (e"on" | e"completely on") + spc + point_node > on_spec_cons
    aligned_spec = (E"aligned with" + spc + point_node + spc + E"along" + spc + (e"x" | e"y" | e"z")) > AlignedSpec
    beyond_spec= E"beyond" + spc + point_node + spc + E"by" + spc + (dist | v3d_cons) + spc + E"from" + spc + point_node > BeyondSpec

    ## Orientation Specifiers
    facing_spec = E"facing" + spc + (v3d_cons) > FacingSpec
    facing_towards_spec = E"facing towards" + spc + point_node > FacingTowardsSpec

    ## Generic Specifiers
    with_spec= E"with " + spc + prop_name + spc + dist > WithSpec


    specifier = at_spec | in_spec | rel_spec | on_spec | aligned_spec | beyond_spec | facing_spec | facing_towards_spec | with_spec
    spec_list = Delayed()
    spec_list.matcher = (specifier + spc + E"," + spc + spec_list) | specifier

    obj_constructor = class_name + Repeat(spec_list, 0, 1) > obj_cons

    obj_res.matcher = obj_ref | obj_constructor

    # Assignment Expressions
    assgn_val = dist | obj_constructor
    v_ass = label_name + spc + E"=" + assgn_val > VarAssgn

    # Full Code
    prs_code = Repeat(v_ass | obj_constructor) + Eos()
end