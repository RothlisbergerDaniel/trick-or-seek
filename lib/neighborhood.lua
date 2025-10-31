local neighborhood = {}
  
  neighborhood.dimensions = {x=4,y=4,sx=48,sy=48,ox=67,oy=67} -- grid dimensions, house dimensions, offset between houses
  neighborhood.candyMax = 15
  neighborhood.candyDuration = 15 -- duration player must stay at house to collect candy
  
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
    
    love.graphics.setColor(1,1,1)
    drawAnimationFrame(streets, 1, 320, 180, 1, 0, 0.925, 0.925)
    
    for i = 1, d.x do
      for j = 1, d.y do
        --love.graphics.setColor(0.7,0.2,0.2)
        --love.graphics.rectangle("fill", (i*d.ox)-(d.sx*0.5)+co.x, (j*d.oy)-(d.sy*0.5)+co.y, d.sx, d.sy) -- house
        love.graphics.setColor(1,1,1)
        drawAnimationFrame(base, 1, (i*d.ox)+co.x-2, (j*d.oy)+co.y-1, 1, 0, 1, 1)
        
        --love.graphics.setColor(0.35,0.1,0.1)
        --love.graphics.rectangle("line", (i*d.ox)-(d.sx*0.5)+co.x+(d.sx*0.45), (j*d.oy)+co.y+(d.sy*0.5), d.sx*0.1, d.sy*0.375) -- candy collection box
        
        --[[love.graphics.setColor(0.1,0.35,0.1)
        love.graphics.rectangle("line", (i*d.ox)-(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y+(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 1
        love.graphics.rectangle("line", (i*d.ox)+(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y+(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 2
        love.graphics.rectangle("line", (i*d.ox)-(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y-(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 3
        love.graphics.rectangle("line", (i*d.ox)+(d.ox*0.5)+co.x-(d.sx*0.05), (j*d.oy)+co.y-(d.oy*0.5)-(d.sy*0.05), d.sx*0.1, d.sy*0.1) -- intersection box 4]]
        
      end
    end
    
    love.graphics.setColor(1,0.9,0.7)
    
    if gameState == "game" and not master then -- master instance doesn't get to see scan recharge!
      local cd=1-scanDelay/maxScanDelay
      local dy=52*(1-cd)
      local dys=52*(cd)
      love.graphics.setColor(0,0,0)
      love.graphics.rectangle("fill", 640-80, 20, 60, 60) -- candy popup outline
      love.graphics.setColor(1,0.4,0.1)
      love.graphics.rectangle("fill", 640-76, 24+dy, 52, dys) -- candy timer rect
      love.graphics.setColor(1,1,1)
      love.graphics.rectangle("fill", 640-72, 28, 44, 44) -- candy popup rect
      drawAnimationFrame(scanner, 1, 640-50, 50, 1, 0, 1, 1)
    end
    
    
    
    
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
        --love.graphics.setColor(0.6,0.2,0.2)
        --love.graphics.rectangle("fill", (i*d.ox)-(d.sx*0.6)+co.x, (j*d.oy)-(d.sy*0.5)+co.y-8, d.sx*1.2, d.sy) -- roof
        love.graphics.setColor(1,1,1)
        drawAnimationFrame(roof, 1, (i*d.ox)+co.x-2, (j*d.oy)+co.y-1, 1, 0, 1, 1)
        if g[j][i] > 0 and gameState == "game" then
          
          love.graphics.setColor(1,0.9,0.7)
          
          
          local cd=1-g[j][i]/neighborhood.candyDuration
          local dy=36*(1-cd)
          local dys=36*(cd)
          love.graphics.setColor(0,0,0)
          love.graphics.rectangle("fill", (i*d.ox)-(40*0.5)+co.x, (j*d.oy)-(40*0.5)+co.y-(d.sx*0.5), 40, 40) -- candy popup outline
          if master then -- slave instance doesn't get to see candy collection progress!
            love.graphics.setColor(1,0.4,0.1)
            love.graphics.rectangle("fill", (i*d.ox)-(36*0.5)+co.x, co.y+(j*d.oy)-(d.sx*0.5)-(36*0.5)+dy, 36, dys) -- candy timer rect
          end
          love.graphics.setColor(1,1,1)
          
          --love.graphics.rectangle("fill", (i*d.ox)-(32*0.5)+co.x, (j*d.oy)-(32*0.5)+co.y-(d.sx*0.5), 32, 32) -- candy popup rect
          drawAnimationFrame(itembox, 1, (i*d.ox)+co.x, (j*d.oy)+co.y-(d.sx*0.4), 1, 0, 1, 1)
          drawAnimationFrame(candy, 1, (i*d.ox)+co.x, (j*d.oy)+co.y-(d.sx*0.4), 1, 0, 1, 1)
          
        end
        
        if gameState == "setup" then
          if master then
            if hTarget.x == i and hTarget.y == j then
              love.graphics.setColor(1,1,1)
              love.graphics.rectangle("fill", (i*d.ox)-(40*0.5)+co.x, (j*d.oy)-(40*0.5)+co.y-(d.sx*0.5), 40, 40) -- candy popup rect
              drawAnimationFrame(itembox, 1, (i*d.ox)+co.x, (j*d.oy)+co.y-(d.sx*0.4), 1, 0, 1, 1)
              love.graphics.setColor(0,0,0)
              love.graphics.print("MOVE", (i*d.ox)-(32*0.5)+co.x-1, (j*d.oy)-(32*0.5)+co.y-(d.sx*0.5))
              love.graphics.print("HERE", (i*d.ox)-(32*0.5)+co.x-1, (j*d.oy)-(32*0.5)+co.y-(d.sx*0.5)+16)
              
              
            end
          else
            love.graphics.print("Please wait for\nthe Ghost to\nbe ready...", 20, 20)
          end
          
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
        
        local bBoxPos = {x=(x*d.ox)-(d.sx*0.5)+co.x+(d.sx*0.45), y=(y*d.oy)+co.y+(d.sy*0.5)}
        
        if g[y][x] > 0 then
          g[y][x] = g[y][x] - dt -- reduce the timer
          if collisions.rectRect(mouse.x-12,mouse.y-12,24,24, bBoxPos.x,bBoxPos.y,d.sx*0.1,d.sy*0.375, "corner") then -- reduce the timer AGAIN
            g[y][x] = g[y][x] - dt  
          end
          if g[y][x] < 0 then
            g[y][x] = 0
            if collisions.rectRect(mouse.x-12,mouse.y-12,24,24, bBoxPos.x,bBoxPos.y,d.sx*0.1,d.sy*0.375, "corner") then
              hCandy = hCandy+1
              if hCandy == rCandy then gameState = "hwin"; gsTimer = 10 end
            end
          end
        end
          
        
      end
    end
    
    
    
  end
  
  function neighborhood.checkPlayerStartPos(dt)
    local d = neighborhood.dimensions
    local bBoxPos = {x=(hTarget.x*d.ox)-(d.sx*0.5)+co.x+(d.sx*0.45), y=(hTarget.y*d.oy)+co.y+(d.sy*0.5)}
        
      if collisions.rectRect(mouse.x-pD.x*0.5,mouse.y-pD.y*0.5,pD.x,pD.y, bBoxPos.x,bBoxPos.y,d.sx*0.1,d.sy*0.375, "corner") then -- reduce the timer AGAIN
        gsTimer = gsTimer - dt
        if gsTimer <= 0 then startGame() end
      else
        gsTimer = 3
      end
    
  end
  
  function neighborhood.checkScanHit(pos)
    local d = neighborhood.dimensions
    local bBoxPos = {x=(pos.x*d.ox)-(d.sx*0.5)+co.x+(d.sx*0.45), y=(pos.y*d.oy)+co.y+(d.sy*0.5)}
    --pprint(bBoxPos)
    if collisions.rectRect(mouse.x-20,mouse.y-20,40,40, bBoxPos.x,bBoxPos.y,d.sx*0.1,d.sy*0.375, "corner") then
      gameState = "swin"; gsTimer = 10
      print("seekerwin")
    end
    
    
  end
  
  
return neighborhood