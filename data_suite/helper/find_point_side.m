% Find the side of the line on which a point lies

function position = find_point_side(p1,p2,p)
position = sign((p2(1) - p1(1)) * (p(2) - p1(2)) - (p2(2) - p1(2)) * (p(1) - p1(1)));