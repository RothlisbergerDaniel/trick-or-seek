local kids = {}
neighborhood = require "lib.neighborhood"
  
  kids.kids = {} -- container for NPCs
  kids.interCheckTimer = 0.1
  kids.speeds = {min=10, max=16}
  
  function kids.generate(count)
    kids.kids = {} -- reset container
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    
    
    for i = 1, count do
      local x, y = math.random(1,d.x), math.random(1,d.y)
      table.insert(kids.kids, {x=(x*d.ox)+co.x, y=(y*d.oy)+co.y+(d.sy*0.7), dir={x=0,y=0}, speed=math.random(kids.speeds.min, kids.speeds.max), target={x=x,y=y}, delay=math.random()*4, interPos={x=x,y=y}, inInter = false, interPause = 0, costume=math.random(1,5), cdir=1}) -- position, movement direction (+/- 1), speed of movement (tweakable), target house coordinates, delay before moving (in seconds), intersection position (for setting new targets), pause at intersection
      kids.setTarget(kids.kids[i], 0)
      kids.getNextDir(kids.kids[i], true)
      
    end
    
    
  end
  
  
  function kids.update(dt)
    
    local g = neighborhood.candyGrid
    
    if master then
      for i = 1, #kids.kids do
        local k = kids.kids[i]
        
        if kids.checkTarget(k) then
          --k.dir.x = 0; k.dir.y = 0
          kids.setTarget(k, dt)
        else
          kids.interCheckTimer = kids.interCheckTimer - dt
          kids.npcMove(k, dt)
          if kids.interCheckTimer <= 0 then kids.interCheckTimer = 0.1 end
        end
        if k.dir.x == 0 then
          if math.random(1,150)==a1 then
            k.cdir = k.cdir * -1
          end
        end
        
      end
    else
      if kids.kids then
        for i = 1, #kids.kids do
          local k = kids.kids[i]
          
          kids.npcMove(k, dt)
          
        end
      end
      
    end
    
    
    
  end
  
  function kids.draw()
    local k = kids.kids
    
    if kids.kids then
      for i = 1, #kids.kids do
        if master then love.graphics.setColor(1,1,1, 0.7)
        else love.graphics.setColor(1,1,1,1) end
        --love.graphics.rectangle("fill", k[i].x - 16, k[i].y - 16, 32, 32)
        if k[i].cdir == 0 then k[i].cdir = -1 end
        drawAnimationFrame(kidsprites[k[i].costume], 3, k[i].x, k[i].y, k[i].cdir, 0, 1, 1)
        
        --love.graphics.setColor(0,1,0)
        --love.graphics.print(pprint.pformat(k[i].target), k[i].x, k[i].y)
        --love.graphics.print(pprint.pformat(k[i].dir), k[i].x, k[i].y-40)
      end
    end
    love.graphics.setColor(1,1,1,1)
    
    
  end
  
  --[[function kids.hiderMove()
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    
    
    
    
  end]]
  
  function kids.npcMove(k, dt)
    
    if master then
      local inter = k.inInter
      if kids.interCheckTimer <= 0 then
        inter = kids.checkInters(k)
      end
      if inter then
        if not k.inInter then
          k.inInter = true
          if k.dir.x > 0 then
            k.interPos.x = math.ceil(k.interPos.x) + 0.5
            k.cdir = 1
          elseif k.dir.x < 0 then
            k.interPos.x = math.floor(k.interPos.x) - 0.5
            k.cdir = -1
          end
          k.interPos.y = k.interPos.y + k.dir.y
          
          kids.getNextDir(k, false) -- update child direction
          if k.dir.y == 0 then k.cdir = k.dir.x end
          k.speed = math.random(kids.speeds.min, kids.speeds.max)
          k.interPause = math.random() * 0.5
        end
      else
        k.inInter = false
      end
    end
    
    if k.x <= 150 then k.dir.x = 1; k.cdir = 1 end
    if k.x >= 640-150 then k.dir.x = -1; k.cdir = -1 end
    if k.y <= 10 then k.dir.y = 1 end
    if k.y >= 360-10 then k.dir.y = -1 end
    
    if k.interPause == 0 then
      k.x = k.x + k.dir.x * k.speed * dt
      k.y = k.y + k.dir.y * k.speed * dt
    else
      k.interPause = k.interPause - dt
      if k.interPause <= 0 then
        k.interPause = 0
      end
    end
    
  end
  
  function kids.getNextDir(k, doSide)
    
    if (k.dir.x == 0 and k.dir.y == 0) or doSide then -- account for just-spawned npcs and npcs leaving a target
      if (k.dir.x == 0 and k.dir.y == 0) then
        if k.interPos.x < k.target.x then
          k.dir.x = 1
        else
          k.dir.x = -1
        end
        k.cdir = k.dir.x
      end
      k.dir.y = 0
    else
    
      if k.interPos.y == k.target.y then
        if k.interPos.x < k.target.x then
          k.dir.x = 1
        else
          k.dir.x = -1
        end
        k.dir.y = 0
        
      else
        if math.random(1,3) < 4 then
          if k.interPos.y < k.target.y then
            k.dir.y = 1
          else
            k.dir.y = -1
          end
          k.dir.x = 0
        else
          if k.interPos.x < k.target.x then
            k.dir.x = 1
          else
            k.dir.x = -1
          end
          k.dir.y = 0
        end
      end
    end
    
    
  end
  
  function kids.checkTarget(k)
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    
    local bBoxPos = {x=(k.target.x*d.ox)-(d.sx*0.5)+co.x+(d.sx*0.45), y=(k.target.y*d.oy)+co.y+(d.sy*0.5)}
    return collisions.rectRect(k.x-2,k.y-2,4,4, bBoxPos.x,bBoxPos.y,d.sx*0.1,d.sy*0.375, "corner")
  end
  
  function kids.checkInters(k) --check intersection collisions
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    --local hit = false
    for y = 1, #g do
      for x = 1, #g[y] do
        local iBoxPos = {
          {x=(x*d.ox)-(d.ox*0.5)+co.x-(d.sx*0.15), y=(y*d.oy)+co.y+(d.oy*0.5)-(d.sy*0.15)}, --1
          {x=(x*d.ox)+(d.ox*0.5)+co.x-(d.sx*0.15), y=(y*d.oy)+co.y+(d.oy*0.5)-(d.sy*0.15)}, --2
          {x=(x*d.ox)-(d.ox*0.5)+co.x-(d.sx*0.15), y=(y*d.oy)+co.y-(d.oy*0.5)-(d.sy*0.15)}, --3
          {x=(x*d.ox)+(d.ox*0.5)+co.x-(d.sx*0.15), y=(y*d.oy)+co.y-(d.oy*0.5)-(d.sy*0.15)}, --4
        }
        
        local coll = {
          collisions.pointRect(k.x,k.y, iBoxPos[1].x,iBoxPos[1].y,d.sx*0.3,d.sy*0.3, "corner"),
          collisions.pointRect(k.x,k.y, iBoxPos[2].x,iBoxPos[2].y,d.sx*0.3,d.sy*0.3, "corner"),
          collisions.pointRect(k.x,k.y, iBoxPos[3].x,iBoxPos[3].y,d.sx*0.3,d.sy*0.3, "corner"),
          collisions.pointRect(k.x,k.y, iBoxPos[4].x,iBoxPos[4].y,d.sx*0.3,d.sy*0.3, "corner"),
        }
        
        if coll[1] or coll[2] or coll[3] or coll[4] then return true end
        
        
      end
    end
    
    return false -- only triggers if no intersections are collided with
    
  end
  
  function kids.setTarget(k, dt)
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    
    if k.delay == 0 then
      
      if math.random(1,3) < 3 then
        
        k.target.x, k.target.y = math.random(1,d.x), math.random(1,d.y)
        k.delay = math.random(1, 10)
        
      else
        local count = 0
        local t = {}
        for y = 1, #g do
          for x = 1, #g do
            count=count+1
            
            if g[y][x] > 0 then
              table.insert(t, count)
            end
            
          end
        end
        if #t > 0 then 
          local c = math.random(1, #t) -- choose a random house with candy
          local tar = {x=((c-1)%4)+1, y=math.ceil(c/4)} -- calculate 2-dimensional coordinates from a 1D number
          k.target.x, k.target.y = tar.x, tar.y
          k.delay = math.random(1, 10)
        else
          k.target.x, k.target.y = math.random(1,d.x), math.random(1,d.y)
          k.delay = math.random(1, 10)
        end
        
        
      end
      
      if k.dir.x == 0 and k.dir.y == 0 then
        kids.getNextDir(k, false)
      else
        --kids.getNextDir(k, true)
      end
      
    else
      k.delay = k.delay - dt
      if k.delay < 0 then k.delay = 0 end -- reduce target reassignment timer
    end
    
  end
  
  
return kids