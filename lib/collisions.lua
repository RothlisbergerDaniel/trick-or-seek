local collisions = {}

  function collisions.pointCircle(px,py, cx,cy,cr) -- collision between point and circle given coordinates and circle radius
    local dx = px - cx; local dy = py - cy
    local dist = math.mag(dx, dy) -- get distance between point and circle
    
    if dist <= cr then return true else return false end
  end

  function collisions.circleCircle(c1x,c1y,c1r, c2x,c2y,c2r) -- collision between circles given coordinates and radii
    local dx = c1x - c2x; local dy = c1y - c2y
    local dist = math.mag(dx, dy) -- get distance between circles
    
    if dist <= c1r + c2r then return true else return false end -- as long as the distance is less than the sum of both radii, there is a collision.
  end

  function collisions.pointRect(px,py, rx,ry,rw,rh, mode) -- collision between point and rectangle, useful for buttons. "mode" optionally dictates corner- vs. center-based collisions.
    local rl,rr,rt,rb -- left, right, top and bottom edges
    if mode == "corner" then
      rl = rx; rr = rx + rw; rt = ry; rb = ry + rh --set edges based on top left corner
    else
      rl = rx - (rw/2); rr = rx + (rw/2); rt = ry + (rh/2); rb = ry - (rh/2) --set edges based on center
    end
    
    if px >= rl and px <= rr and py >= rb and py <= rt then return true else return false end --if the point is within bounds, return true
  end

  function collisions.rectRect(r1x,r1y,r1w,r1h, r2x,r2y,r2w,r2h, mode) -- collision between rectangles given coordinates and dimensions.
    local r1l,r1r,r1t,r1b, r2l,r2r,r2t,r2b -- left, right, top and bottom edges
    if mode == "corner" then
      r1l = r1x; r1r = r1x + r1w; r1t = r1y; r1b = r1y + r1h
      r2l = r2x; r2r = r2x + r2w; r2t = r2y; r2b = r2y + r2h -- set edges based on top left corners
    else
      r1l = r1x - (r1w/2); r1r = r1x + (r1w/2); r1t = r1y - (r1h/2); r1b = r1y + (r1h/2)
      r2l = r2x - (r2w/2); r2r = r2x + (r2w/2); r2t = r2y - (r2h/2); r2b = r2y + (r2h/2) -- set edges based on centers
    end
    
    if r1l <= r2r and r1r >= r2l and r1b <= r2t and r1t >= r2b then return true else return false end -- as long as rectangles are properly colliding, return true
  end

  function collisions.circleRect(cx,cy,cr, rx,ry,rw,rh, mode) -- collision between circle and rectangle, given coordinates and dimensions.
    local rl,rr,rt,rb -- left, right, top and bottom edges
    if mode == "corner" then
      rl = rx; rr = rx + rw; rt = ry; rb = ry + rh --set edges based on top left corner
    else
      rl = rx - (rw/2); rr = rx + (rw/2); rt = ry - (rh/2); rb = ry + (rh/2) --set edges based on center
    end
    
    local tx = cx; local ty = cy -- edges to test against, with a fallback to circle origin
    if cx < rl then tx = rl elseif cx > rr then tx = rr end
    if cy > rb then ty = rb elseif cy < rt then ty = rt end -- set edges to test against if within bounds
    
    local dx = cx - tx; local dy = cy - ty
    local dist = math.mag(dx, dy) -- get distance between circle and comparative edges
    
    if dist <= cr then return true else return false end -- returns true if any part of the circle is within bounds
  end

  function collisions.pointLine(px,py, x1,y1, x2,y2, b) -- collision between point and line, given coordinates of point and two line endpoints, with optional buffer
    local d1 = math.dist(px,py, x1,y1); local d2 = math.dist(px,py, x2,y2) -- distance between point and line endpoints
    local length = math.dist(x1,y1, x2,y2) -- line length
    
    local buffer -- allow for slight inaccuracy. Higher numbers give less accurate collisions.
    if type(b) == "number" then buffer = b else buffer = 0.1 end -- default buffer is 0.1, can be optionally set
    
    if d1 + d2 >= length - buffer and d1 + d2 <= length + buffer then return true else return false end -- return true if point and line roughly overlap
  end

  function collisions.lineCircle(x1,y1, x2,y2, cx,cy,cr) -- collision between line and circle. Complex math, good for raycast collisions.
    local ep1In = collisions.pointCircle(x1,y1, cx,cy,cr); local ep2In = collisions.pointCircle(x2,y2, cx,cy,cr) -- check whether circle contains either line endpoint
    if ep1In or ep2In then return true -- if circle contains an endpoint, immediately return true
    else
      local length = math.dist(x1,y1, x2,y2)
      local dp = ( ((cx-x1)*(x2-x1)) + ((cy-y1)*(y2-y1)) ) / length^2 -- get dot product of line and circle positions
      local nx = x1 + (dp*(x2-x1)); local ny = y1 + (dp*(y2-y1)) -- get the nearest point on the line to the circle using previously calculated dot product
      local onLine = collisions.pointLine(nx,ny, x1,y1, x2,y2) -- check if the nearest point is actually on the given line segment
      if not onLine then return false -- we can automatically return false if the closest point is not on the segment
      else
        if collisions.pointCircle(nx,ny, cx,cy,cr) then return true else return false end -- return true if nearest point on line is colliding with given circle
      end
    end
  end

  function collisions.lineLine(x1,y1, x2,y2, x3,y3, x4,y4) -- collision between two lines. Returns collision validity as well as point of intersection.
    local ua = ( (x4-x3)*(y1-y3) - (y4-y3)*(x1-x3) ) / ( (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1) )
    local ub = ( (x2-x1)*(y1-y3) - (y2-y1)*(x1-x3) ) / ( (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1) ) -- both ua and ub should return a value between 1 and 0 if a collision is present
    local collision
    if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then collision = true else collision = false end -- set collision validity
    
    local ix, iy
    ix = x1 + (uA * (x2-x1))
    iy = y1 + (uA * (y2-y1)) -- set intersection points
    
    if collision then return true, ix, iy else return false, nil, nil end -- return true and intersection point if collision is present
  end

  function collisions.lineRect(x1,y1, x2,y2, rx,ry,rw,rh, mode) -- collision between a line and a rectangle. Does not return points of intersection (yet).
    local rl,rr,rt,rb -- left, right, top and bottom edges
    if mode == "corner" then
      rl = rx; rr = rx + rw; rt = ry; rb = ry + rh --set edges based on top left corner
    else
      rl = rx - (rw/2); rr = rx + (rw/2); rt = ry - (rh/2); rb = ry + (rh/2) --set edges based on center
    end
    
    local lhit, rhit, thit, bhit
    local iPoints = {}
    lhit, iPoints.x1, iPoints.y1 = collisions.lineLine(x1,y1, x2,y2, rl,rt, rl,rb)
    rhit, iPoints.x2, iPoints.y2 = collisions.lineLine(x1,y1, x2,y2, rr,rt, rr,rb)
    thit, iPoints.x3, iPoints.y3 = collisions.lineLine(x1,y1, x2,y2, rl,rt, rr,rt)
    bhit, iPoints.x4, iPoints.y4 = collisions.lineLine(x1,y1, x2,y2, rl,rb, rr,rb) -- get line collision with each rectangle line, and points of intersection.
    
    if lhit or rhit or thit or bhit then return true, iPoints else return false, nil end -- return true if any line is intersected
  end

return collisions