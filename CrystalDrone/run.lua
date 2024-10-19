-- Configuration
local serverURL = "http://10.0.0.228/" -- Replace with your server endpoint

-- Helper function to gather turtle info
local function getTurtleInfo()
    local info = {
        id = os.getComputerID(),
        label = os.getComputerLabel(),
        fuelLevel = turtle.getFuelLevel(),
        selectedSlot = turtle.getSelectedSlot(),
        inventory = getInventory(),
        lookingAt = getLookingAtInfo()
    }
    return info
end

-- Collect inventory details
local function getInventory()
    local inventory = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            inventory[slot] = item
        end
    end
    return inventory
end

-- Get the block or entity in front of the turtle
local function getLookingAtInfo()
    local success, data = turtle.inspect()
    if success then
        return data
    else
        return { name = "air", description = "Nothing detected" }
    end
end

-- HTTP Request to send data and get server response
local function sendInfoAndGetCommand(info)
    local json = textutils.serializeJSON(info)
    local response = http.post(serverURL, json, { ["Content-Type"] = "application/json" })
    if response then
        local result = response.readAll()
        response.close()
        return textutils.unserializeJSON(result)
    else
        print("Failed to connect to the server.")
        return nil
    end
end

-- Execute commands from the server
local function executeCommand(command)
    if command == "moveForward" then
        turtle.forward()
    elseif command == "moveBack" then
        turtle.back()
    elseif command == "turnLeft" then
        turtle.turnLeft()
    elseif command == "turnRight" then
        turtle.turnRight()
    elseif command == "dig" then
        turtle.dig()
    elseif command == "refuel" then
        turtle.refuel()
    elseif command == "attack" then
        turtle.attack()
    elseif command == "shutdown" then
        os.shutdown()
    else
        print("Unknown command: " .. tostring(command))
    end
end

-- Main loop
while true do
    local info = getTurtleInfo()
    local command = sendInfoAndGetCommand(info)
    if command then
        executeCommand(command)
    end
    sleep(5) -- Wait 5 seconds before the next update
end
