pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cellular automata simulator
-- by Andrew Phifer


--TODO: draw field needs to line up with the actual display.  draw index looks to be from 0 to 127, rather than 1 to 128

function binaryToInteger(inputList)
    local exponent = 0
    local output = 1

    for value in all(inputList) do        
        output += value * (2 ^ exponent)
        exponent += 1
    end
    
    return(output)
end


--need to actually write this function.  complex-piece-wise
function mapToroid(maxValue, index)
    toroidIndex = index - ((index \ maxValue) * maxValue)
    
end


function worldIndex(world, index)
    if index == 0 then
        toroidIndex = 127
    elseif index == 128 then
        toroidIndex = 1
    else
        toroidIndex = index
    end
    --toroidIndex = index - ((index \ #world) * #world)    
    return world[toroidIndex]
end


function generateHomogeniousList(size, value)    
    local x = 1
    local output = {}

    while x <= size do
        x += 1
        add(output, value)
    end

    return(output)
end


function round(x)
    local high = ceil(x)
    local low = flr(x)
    local diff = high - x
    local roundUp = diff < 0.5
    local output = 0

    if roundUp then
        output = high
    else
        output = low
    end

    return output
end


function generateRandomList(size, minV, maxV, offset)
    local x = 1
    local output = {}
    range = maxV - minV

    while x <= size do
        x += 1
        value = minV + round(rnd(range) + offset)
        add(output, value)
    end

    return(output)
end


function copyWorld(originalWorld)
    local output = {}
    local index = 1

    for element in all(originalWorld) do
        add(output, element)
    end

    return(output)
end


function configureSimParams()
    mode = "config"
    cursorPosition = 1    
end


function restartSim()
    cls()
    mode = "run"
    newColor = randomColor(0)
    iterationnumber = 0
    newworld = generateHomogeniousList(128, 0)
    --{"random even", "random high", "random low", "single middle", "single random"}
    if worldGenMode == "random even" then
        oldworld = generateRandomList(128, 0, 1, 0)    
    elseif worldGenMode == "random low" then
        oldworld = generateRandomList(128, 0, 1, -0.25)
    elseif worldGenMode == "random high" then
        oldworld = generateRandomList(128, 0, 1, 0.25)
    elseif worldGenMode == "single middle" then
        oldworld = generateHomogeniousList(128, 0)
        oldworld[#oldworld \ 2] = 1
    elseif worldGenMode == "single random" then
        oldworld = generateHomogeniousList(128, 0)
        oldworld[rnd(128) \ 1] = 1
    end

    
end


function choose(cond, choice1, choice2)
    if cond then
        output = choice1
    else
        output = choice2
    end

    return output
end


function sequenceGen(low, high, step)
    output = {}    

    for v = low, high, step do
        add(output, v)
    end

    return output
end


function updateConfigElement(line, leftButtonPressed, rightButtonPressed, isSelected)
    local valueIndex = line[2]
    local valueSet = line[12]

    if isSelected then

        if leftButtonPressed then
            valueIndex -= 1
        elseif rightButtonPressed then
            valueIndex += 1
        else
            valueIndex = valueIndex
        end
        
        if valueIndex < 1 then
            valueIndex = #valueSet
        elseif valueIndex > #valueSet then
            valueIndex = 1
        else
            valueIndex = valueIndex
        end

        line[2] = valueIndex
    end
end


function executeConfigCallBack(line)
    local funct = line[15]
    local data = line[2]
    local hasBeenUpdated = line[16]
    local valueSet = line[12]

    if hasBeenUpdated then
        funct(valueSet[data])
        line[16] = false        
    end
end


function renderConfigElement(line, leftButtonPressed, rightButtonPressed, isSelected)
    local leadingText = line[1]
    local valueIndex = line[2]
    local closingText = line[3]
    local valueDecoratorLeftNormal = line[4]
    local valueDecoratorRightNormal = line[5]
    local valueDecoratorLeftPressed = line[6]
    local valueDecoratorRightPressed = line[7]
    local lineDecoratorLeftNormal = line[8]
    local lineDecoratorRightNormal = line[9]
    local lineDecoratorLeftSelected = line[10]
    local lineDecoratorRightSelected = line[11]
    local valueSet = line[12]
    local countDown = line[13]
    local lastPressed = line[14]
    local hasBeenUpdated = line[16]

    if (countDown != indicatorPersist) then
        countDown -= 1
    elseif (isSelected and leftButtonPressed) then
        countDown = indicatorPersist - 1
        lastPressed = "left"
        hasBeenUpdated = true
    elseif (isSelected and rightButtonPressed) then
        countDown = indicatorPersist - 1
        lastPressed = "right"
        hasBeenUpdated = true
    end

    if countDown < 0 then
        countDown = indicatorPersist
        lastPressed = ""
    end

    local value = valueSet[valueIndex]
    local leftLineDecorator = choose(isSelected, lineDecoratorLeftSelected, lineDecoratorLeftNormal)
    local rightLineDecorator = choose(isSelected, lineDecoratorRightSelected, lineDecoratorRightNormal)
    local leftValueDecorator = choose(isSelected and (countDown != indicatorPersist) and (lastPressed == "left"), valueDecoratorLeftPressed, valueDecoratorLeftNormal)
    local rightValueDecorator = choose(isSelected and (countDown != indicatorPersist) and (lastPressed == "right"), valueDecoratorRightPressed, valueDecoratorRightNormal)
    local output = leftLineDecorator .. leadingText .. leftValueDecorator .. value .. rightValueDecorator .. closingText .. rightLineDecorator
    line[13] = countDown
    line[14] = lastPressed
    line[16] = hasBeenUpdated

    return output
end


function updateRule(data)    
    local output = {}
    for x = 7, 0, -1 do
        result = (data - (2 ^ x) >= 0)
        buffer = choose(result, 1, 0)
        
        if result then
            data -= 2 ^ x
        end

        output[x + 1] = buffer
    end

    rule = output    
end


function updateWorldGen(data)
    worldGenMode = data
end


function updateColors(data)
    colorsMode = data
end


function _init()
    indicatorPersist = 8 --measured in frames
    rule = {0,1,1,0,1,0,1,0}
    mode = "run"
    worldGenMode = "random even"
    colorsMode = "random line"
    maxiterationnumber = 127
    restartSim()
    configBuffer = {}
    ruleRange = sequenceGen(0, 255, 1)
    worldGenOptions = {"random even", "random high", "random low", "single middle", "single random"}
    colorOptions = {"random line", "random noise", "solid"}
    add(configBuffer, {"rule", 106, "", " ", " ", "<", ">", "*", "*", "[", "]", ruleRange, indicatorPersist, "", updateRule})
    add(configBuffer, {"world gen", 1, "", " ", " ", "<", ">", "*", "*", "[", "]", worldGenOptions, indicatorPersist, "", updateWorldGen})
    add(configBuffer, {"colors", 1, "", " ", " ", "<", ">", "*", "*", "[", "]", colorOptions, indicatorPersist, "", updateColors})
    menuitem(1, "run", function() restartSim() end)
    menuitem(2, "configure", function() configureSimParams() end)
    menuitem(3, "exit", function () stop() end)
end


function _update()
    --print("update")
    if mode == "run" then
        if iterationnumber < maxiterationnumber then
            iterationnumber += 1
            local x = 1
            newworld = {}            
            while x <= 127 do
                local v0 = worldIndex(oldworld, x - 1)
                local v1 = worldIndex(oldworld, x)
                local v2 = worldIndex(oldworld, x + 1)            
                local buffer = {v0, v1, v2}
                local index = binaryToInteger(buffer)            
                add(newworld, rule[index])
                x += 1
            end
        else
            --stop()
        end
    elseif mode == "config" then --interface code
        if btnp(2) then --up pressed
            cursorPosition -= 1 
        elseif btnp(3) then --down pressed
            cursorPosition += 1
        end

        if cursorPosition > #configBuffer then --wrap around
            cursorPosition = 1
        elseif cursorPosition == 0 then
            cursorPosition = #configBuffer
        else
            cursorPosition = cursorPosition
        end     
    end
end


function randomColor(excludedColor)
    output = flr(rnd(16))

    while output == excludedColor do
        output = flr(rnd(16))
    end

    return output
end


function _draw()
    --print("draw")
    if mode == "run" then        
        local xpos = 0

        --colorOptions = {"random line", "random noise", "solid"}
        if iterationnumber < maxiterationnumber then
            if colorsMode == "random line" then
                newColor = randomColor(0)
            end

            for element in all(newworld) do
                if colorsMode == "random noise" then
                    newColor = randomColor(0)
                end            

                pset(xpos, iterationnumber, newColor * element)
                xpos += 1
            end
            
            oldworld = copyWorld(newworld)
        end
    elseif mode == "config" then
        local left = btnp(0)
        local right = btnp(1)
        cls() --should be changed to event based processing
        color(6)
                
        for index, element in pairs(configBuffer) do
            local isSelected = (index == cursorPosition)
            updateConfigElement(element, left, right, isSelected)
            executeConfigCallBack(element)
            print(renderConfigElement(element, left, right, isSelected))
        end                
    else
        print("unknown operating mode: " .. mode)
        stop()
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
