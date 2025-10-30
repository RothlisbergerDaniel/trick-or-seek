local neighborhood = {}
  
  neighborhood.dimensions = {x=4,y=4,sx=48,sy=48,ox=72,oy=72} -- grid dimensions, house dimensions, offset between houses
  neighborhood.candyMax = 15
  neighborhood.candyDuration = 5 -- duration player must stay at house to collect candy
  
  function neighborhood.load()
    neighborhood.candyTimer = 0
    neighborhood.candyGrid = {
      [1] = {0,0,0,0},
      [2] = {0,0,0,0},
      [3] = {0,0,0,0},
      [4] = {0,0,0,0},
    }
  end
  
  
  
  function neighborhood.update(dt)
    if master then
      neighborhood.candyTimer = neighborhood.candyTimer + dt
      if neighborhood.candyTimer >= neighborhood.candyMax then
        neighborhood.addCandy()
      end
      
      neighborhood.checkCandyCollect(dt)
    end
    
    
  end
  
  function neighborhood.draw()
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    
    
    
    for i = 1, d.x do
      for j = 1, d.y do
        love.graphics.setColor(0.7,0.2,0.2)
        love.graphics.rectangle("fill", (i*d.ox)-(d.sx*0.5)+co.x, (j*d.oy)-(d.sy*0.5)+co.y, d.sx, d.sy) -- house
        
        love.graphics.setColor(0.35,0.1,0.1)
        love.graphics.rectangle("line", (i*d.ox)-(d.sx*0.5)+co.x+(d.sx*0.375), (j*d.oy)+co.y+(d.sy*0.5), d.sx*0.25, d.sy*0.375) -- candy collection box
        
        love.graphics.setColor(0.1,0.35,0.1)
        love.graphics.rectangle("line", (i*d.ox)-(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y+(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 1
        love.graphics.rectangle("line", (i*d.ox)+(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y+(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 2
        love.graphics.rectangle("line", (i*d.ox)-(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y-(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 3
        love.graphics.rectangle("line", (i*d.ox)+(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y-(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 4
        
      end
    end
    
    love.graphics.setColor(1,1,1)
    love.graphics.print("Candy: "..hCandy.."/"..rCandy, 20, 20)
    
  end
  
  function neighborhood.drawRooves()
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    if not master then
      if cGrid then
        g = cGrid
      end
    end
    
    
    
    for i = 1, d.x do
      for j = 1, d.y do
        love.graphics.setColor(0.6,0.2,0.2)
        love.graphics.rectangle("fill", (i*d.ox)-(d.sx*0.6)+co.x, (j*d.oy)-(d.sy*0.5)+co.y-8, d.sx*1.2, d.sy) -- roof
        if g[j][i] > 0 then
          
          love.graphics.setColor(1,0.9,0.7)
          
          if master then -- slave instance doesn't get to see candy collection progress!
            local cd=1-g[j][i]/neighborhood.candyDuration
            local dy=36*(1-cd)
            local dys=36*(cd)
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill", (i*d.ox)-(40*0.5)+co.x, (j*d.oy)-(40*0.5)+co.y-(d.sx*0.5), 40, 40) -- candy popup outline
            love.graphics.setColor(1,0.4,0.1)
            love.graphics.rectangle("fill", (i*d.ox)-(36*0.5)+co.x, co.y+(j*d.oy)-(d.sx*0.5)-(36*0.5)+dy, 36, dys) -- candy timer rect
            love.graphics.setColor(1,1,1)
          end
          
          
          love.graphics.rectangle("fill", (i*d.ox)-(32*0.5)+co.x, (j*d.oy)-(32*0.5)+co.y-(d.sx*0.5), 32, 32) -- candy popup rect
          
        end
        
      end
    end
    
    
    
    
  end
  
  function neighborhood.addCandy()
    local cPos = {x=1,y=1}
    local hit = false
    local count = 0
    local retries = neighborhood.dimensions.x * neighborhood.dimensions.y
    retries = 1
    repeat
      count = count+1
      cPos.x = math.random(1,neighborhood.dimensions.x); cPos.y = math.random(1,neighborhood.dimensions.y)
      if neighborhood.candyGrid[cPos.y][cPos.x] == 0 then hit = true end
      
    until hit or count > retries
    
    if count <= retries then
      neighborhood.candyGrid[cPos.y][cPos.x] = neighborhood.candyDuration
    end
    neighborhood.candyTimer = 0
    
  end
  
  function neighborhood.decreaseCandyTime(dt)
    local g = neighborhood.candyGrid
    
    for y = 1, #g do
      for x = 1, #g[y] do -- iterate through the candy grid
        
        if g[y][x] > 0 then
          g[y][x] = g[y][x] - dt -- reduce the timer
          if g[y][x] < 0 then
            g[y][x] = 0
          end
        end
          
        
      end
    end
    
    
  end
  
  function neighborhood.checkCandyCollect(dt)
    local d = neighborhood.dimensions
    local g = neighborhood.candyGrid
    
    
    
    
    for y = 1, #g do
      for x = 1, #g[y] do -- iterate through the candy grid
        
        local bBoxPos = {x=(x*d.ox)-(d.sx*0.5)+co.x+(d.sx*0.375), y=(y*d.oy)+co.y+(d.sy*0.5)}
        
        if g[y][x] > 0 and collisions.rectRect(mouse.x-pD.x*0.5,mouse.y-pD.y*0.5,pD.x,pD.y, bBoxPos.x,bBoxPos.y,d.sx*0.25,d.sy*0.375, "corner") then
          g[y][x] = g[y][x] - dt -- reduce the timer
          if g[y][x] < 0 then
            g[y][x] = 0
            hCandy = hCandy+1
          end
        end
          
        
      end
    end
    
    
    
  end
  
  
return neighborhood