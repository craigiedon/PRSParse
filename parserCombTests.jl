using ParserCombinator
includet("parserCombExample.jl")


# rel_1 = parse_one("above", relative_pos_ids)[1]
# oj = parse_one("Table", obj_constructor)[1]
# oj_2 = parse_one("Table with width 0.8", obj_constructor)[1]
# oj_3 = parse_one("Table with width 0.8, with height 0.9, with length 1.2", obj_constructor)
# oj_4 = parse_one("Couch at V3D(0.1, 2, -3.33), with width 1.2", obj_constructor)[1]

pc1 = parse_one("t = Table on V3D(0, 0, 0)", prs_code)[1]
pc2 = parse_one("r1 = Robot on top back t", prs_code)[1]

# TODO: Vector Addition (and regular number addition?)
pc3 = parse_one("r2 = Robot on (top back t) + V3D(0.4, 0, 0)", prs_code)[1]
pc4 = parse_one("tr_1 = Tray completely on t, ahead of r1, left of t", prs_code)[1]
pc5 = parse_one("tr_2 = Tray completely on t, ahead of r2, right of t", prs_code)[1]
pc6 = parse_one("Cube completely on tr_1", prs_code)[1]
pc7 = parse_one("Camera at V3D((-0.1, 0.1), (-0.1, 0.1), (1.9, 2.1)), facing V3D(0, 0, -1)", prs_code)[1]