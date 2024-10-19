local currentLocation = vector.new(0,0,0)
local mineFrameCoords = vector.new(0,0,0)
local mineEntrance = vector.new(0,0,0)
local mineExit = vector.new(0,0,0)
local fuelChest = vector.new(0,0,0)
local dropChest = vector.new(0,0,0)
local status = "idle"
local bearing = "north"
local rednetID = os.getComputerID()
local assignedLevel = currentLocation.y
local range = 10
local mineFrameId = 0
local tunnelId = 0
local valuableOres = {
    ["minecraft:diamond_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:emerald_ore"] = true,
	["minecraft:coal_ore"] = true,
    -- Add more ore types as needed
}
local blacklisted = {
	["computercraft:turtle_advanced"] = true
}

function blacklist(name)
	return blacklisted[name] or false
end

function isValuableOre(name)
    return valuableOres[name] or false
end

function mineTunnel(length, dir)
	status = "mining"
	move(dir, 0)
	local down = true
    for i = 1, length do
		if down then
			turtle.dig()
			turtle.forward()
			scanMine()
			turtle.digUp()
			turtle.up()
			scanMine()
			down = false
		else
			turtle.dig()
			turtle.forward()
			scanMine()
			turtle.digDown()
			turtle.down()
			scanMine()
			down = true
		end
		fuelInvCheck(vector.new(gps.locate()), bearing)
    end
	status = "complete"
	sendUpdate(tunnelId)
end

function scan()
    local directions = {
        {name = "front", inspect = turtle.inspect, turn = function() end, return_turn = function() end, },
        {name = "up", inspect = turtle.inspectUp, turn = function() end, return_turn = function() end},
        {name = "down", inspect = turtle.inspectDown, turn = function() end, return_turn = function() end},
        {name = "right", inspect = turtle.inspect, turn = turtle.turnRight, return_turn = turtle.turnLeft},
		{name = "left", inspect = turtle.inspect, turn = turtle.turnLeft, return_turn = turtle.turnRight}
    }
    
    for _, direction in ipairs(directions) do
        direction.turn()
        local success, data = direction.inspect()
		if success and blacklist(data.name) then
			sleep(5)
		end
        if success and isValuableOre(data.name) then
			direction.return_turn()
            return true, direction.name
        end
		direction.return_turn()
    end
    return false, "none"
end

--will mine out an ore vein and then retrace steps to starting position
function scanMine()
    local moveHist = {}
    local inProgress = true
    while inProgress do
        local success, direction = scan()
        if success then
            if direction == "front" then
                turtle.dig()
                turtle.forward()
                table.insert(moveHist, "front")
            elseif direction == "up" then
                turtle.digUp()
                turtle.up()
                table.insert(moveHist, "up")
            elseif direction == "down" then
                turtle.digDown()
                turtle.down()
                table.insert(moveHist, "down")
            elseif direction == "right" then
                turtle.turnRight()
                turtle.dig()
                turtle.forward()
                table.insert(moveHist, "right")
            elseif direction == "left" then
                turtle.turnLeft()
                turtle.dig()
                turtle.forward()
                table.insert(moveHist, "left")
            end
        else
            -- Trace steps back to start
            if #moveHist > 0 then
                local lastMove = table.remove(moveHist)
                if lastMove == "front" then
                    turtle.back()
                elseif lastMove == "up" then
                    turtle.down()
                elseif lastMove == "down" then
                    turtle.up()
                elseif lastMove == "right" then
                    turtle.back()
                    turtle.turnLeft()
                elseif lastMove == "left" then
                    turtle.back()
                    turtle.turnRight()
                end
            else
                inProgress = false
            end
        end
    end
end

function move(dir, dis)
    local horizontalDirections = {"north", "east", "south", "west"}
    local moveSuccess = true
    -- Check if it's a vertical movement
    if dir == "up" or dir == "down" then
        -- Handle vertical movement
        if dis > 0 then
            for i = 1, dis do
                moveSuccess = false
                for j = 1, 10 do
                    if dir == "up" then
                        if turtle.up() then
                            moveSuccess = true
                            break
                        end
                    else
                        if turtle.down() then
                            moveSuccess = true
                            break
                        end
                    end
                    sleep(2)
                end
                if not moveSuccess then
					print("movement FAILED")
                    break
                end
            end
        end
    else
        -- Handle horizontal movement
        local currentIndex = table.indexOf(horizontalDirections, bearing)
        local targetIndex = table.indexOf(horizontalDirections, dir)
        
        if not currentIndex or not targetIndex then
            print("Invalid horizontal direction")
            return
        end
        
        -- Calculate turn
        local turn = (targetIndex - currentIndex + 4) % 4
        
        -- Execute turn
        if turn == 1 then
            turtle.turnRight()
        elseif turn == 2 then
            turtle.turnRight()
            turtle.turnRight()
        elseif turn == 3 then
            turtle.turnLeft()
        end
        
        -- Update bearing
        bearing = dir
        
        -- Move forward
        if dis > 0 then
            for i = 1, dis do
                if not turtle.forward() then
					for i=1, 10 do
						sleep(2)
						if turtle.forward() then
							moveSuccess = true
							break
						end
						moveSuccess = false
					end
				end
            end
        end
    end
	currentLocation = vector.new(gps.locate())
	return moveSuccess
end

-- Helper function to find index in table
function table.indexOf(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
    return nil
end

function moveTo(location)
	print("moving to location:" , location.x, location.y, location.z)
	currentLocation = vector.new(gps.locate())
	if currentLocation.x > mineExit.x then
		move("west", math.abs(currentLocation.x - mineExit.x))
	elseif currentLocation.x < mineExit.x then
		move("east", math.abs(currentLocation.x - mineExit.x))
	end
	if location.y ~= currentLocation.y then
		local shaft = vector.new(0,0,0)
		if location.y > currentLocation.y then
			shaft = mineExit
		else
			shaft = mineEntrance
		end
		if currentLocation.z > mineExit.z then
			move("north", math.abs(currentLocation.z - shaft.z))
		elseif currentLocation.z < mineExit.z then
			move("up", 1)
			move("south", math.abs(currentLocation.z - shaft.z))
			currentLocation = vector.new(gps.locate())
		end
		if currentLocation.y > location.y then
			move("down", math.abs(currentLocation.y - location.y))
		elseif currentLocation.y < location.y then
			move("up", math.abs(currentLocation.y - location.y))
		end
	end
	currentLocation = vector.new(gps.locate())
	if currentLocation.z > location.z then
		move("north", math.abs(currentLocation.z - location.z))
	elseif currentLocation.z < location.z then
		move("up", 1)
		move("south", math.abs(currentLocation.z - location.z))
		move("down", 1)
	end
	if currentLocation.x > location.x then
		move("west", math.abs(currentLocation.x - location.x))
	elseif currentLocation.x < location.x then
		move("east", math.abs(currentLocation.x - location.x))
	end
end

function dropOff()
	moveTo(dropChest)
	move("south", 0)
	for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            local dropped = turtle.drop()
            if not dropped then
                print("Failed to drop items from slot " .. slot)
                return false
            end
        end
    end
    turtle.select(1)
    return true
end

function refuel()
	moveTo(fuelChest)
	move("south", 0)
	local targetFuelLvl = 5000
	while turtle.getFuelLevel() < targetFuelLvl do
        if not turtle.suck(1) then
            print("No fuel in chest")
            return false
        end
        -- Try to refuel with the item
        if turtle.refuel(1) then
            fueledSuccessfully = true
            print("Refueled. Current fuel level: " .. turtle.getFuelLevel())
        else
            -- If the item wasn't fuel, put it back
            turtle.drop(1)
            print("Non-fuel item encountered and returned to chest.")
        end
    end
end

function inventoryFull()
	local maxSlots = 16
	local filledSlots = 0
	local threshold = 15

		for slot = 1, maxSlots do
		if turtle.getItemCount(slot) > 0 then
			filledSlots = filledSlots + 1
		end
	end
	turtle.select(1)
	return filledSlots >= threshold
end

function fuelInvCheck(location, currentBearing)
	local minFuelLvl = 1000
	local wentToSurface = false
	if turtle.getFuelLevel() < minFuelLvl then
		refuel()
		wentToSurface = true
	end
	if inventoryFull() then
		dropOff()
		wentToSurface = true
	end
	if wentToSurface then
		moveTo(location)
		move(currentBearing, 0)
	end
end

function sendUpdate(arg1, arg2, arg3)
	currentLocation = vector.new(gps.locate())
    local update = {currentLocation, status}
	if arg1 then
        table.insert(update,arg1)
    end
	if arg2 then
        table.insert(update,arg2)
    end
	if arg3 then
        table.insert(update,arg3)
    end
	print("sending status: ", status)
	rednet.send(mineFrameId, update)
	local _, received = rednet.receive(5)
	if received == nil then
		for i = 1, 5 do
			print("update failed to send, retrying...")
			rednet.send(mineFrameId, update)
			_, received = rednet.receive(5)
			if received then
				return true
			end
		end
		return false
	end
    return true
end

function joinRegister()
	currentLocation = vector.new(gps.locate())
	rednet.open("left")
	print("enter mineFrame ID:")
	mineFrameId = tonumber(io.read())
	status = "join"
	sendUpdate()
	local _, command = rednet.receive()
	rednet.send(mineFrameId, true)
	local order, destination, mineFrameLoc = table.unpack(command)
	print("orders received: ", order)
	mineFrameCoords = mineFrameLoc
	mineEntrance = mineFrameCoords + vector.new(0, -1, -6)
	mineExit = mineFrameCoords + vector.new(0, -1, -7)
	dropChest = mineFrameCoords + vector.new(-1, -1, -1)
	fuelChest = mineFrameCoords + vector.new(1, -1, -1)
	move("south", 0)
	turtle.suck(1)
	turtle.suck(1)
	turtle.suck(1)
	turtle.refuel(1)
	turtle.refuel(1)
	turtle.refuel(1)
	moveTo(destination)
	status = "idle"
	sendUpdate()
end

function main()
	joinRegister()
	while true do
		local _, command = rednet.receive()
		rednet.send(mineFrameId, true)
		local order, destination, direction, tunnel = table.unpack(command)
		if order == "depot" then
			moveTo(destination)
			status = "idle"
			sendUpdate()
		elseif order == "mine" then
			tunnelId = tunnel
			status = "mining"
			moveTo(destination)
			mineTunnel(range, direction)
		end
	end
end

main()