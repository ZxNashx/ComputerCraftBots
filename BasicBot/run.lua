-- Function to make the turtle walk in a square
function walkSquare(sideLength)
    for i = 1, 4 do  -- Four sides of a square
        for j = 1, sideLength do
            turtle.forward()  -- Move forward by 1 block
        end
        turtle.turnRight()  -- Turn 90 degrees to the right
    end
end

-- Example usage: Move in a square of 5 blocks per side
walkSquare(5)
