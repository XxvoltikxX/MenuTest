local Interactions = {}
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Funkcja pomocnicza do pobierania pozycji myszy/dotyku
local function getInputPos(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

function Interactions:MakeDraggable(clickObj, moveObj, onTapCallback)
    local dragging = false
    local dragStart, startPos
    local dragInput = nil
    local movedDistance = 0
    local DRAG_THRESHOLD = 8

    clickObj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = moveObj.Position
            movedDistance = 0
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local dist = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)
            if dist > movedDistance then
                movedDistance = dist
            end
            if movedDistance >= DRAG_THRESHOLD then
                moveObj.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X, 
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local wasTap = (movedDistance < DRAG_THRESHOLD)
            dragging = false
            dragInput = nil
            if wasTap and type(onTapCallback) == "function" then
                pcall(onTapCallback)
            end
        end
    end)
end

function Interactions:MakeResizable(handle, mainFrame, minX, minY)
    local resizing = false
    minX = minX or 350
    minY = minY or 230

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            local startSize = mainFrame.AbsoluteSize
            local startPos = mainFrame.Position
            local startInputPos = input.Position

            local camera = workspace.CurrentCamera
            local vp = camera and camera.ViewportSize or Vector2.new(1600, 900)
            local dynamicMaxX = math.max(minX + 50, vp.X - 10)
            local dynamicMaxY = math.max(minY + 50, vp.Y - 10)
            
            local moveCon
            moveCon = UIS.InputChanged:Connect(function(moveInput)
                if resizing and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = moveInput.Position - startInputPos
                    
                    local newX = math.clamp(startSize.X + delta.X, minX, dynamicMaxX)
                    local newY = math.clamp(startSize.Y + delta.Y, minY, dynamicMaxY)
                    
                    local diffX = newX - startSize.X
                    local diffY = newY - startSize.Y
                    
                    -- Aktualizacja rozmiaru i kompensacja pozycji dla AnchorPoint 0.5
                    mainFrame.Size = UDim2.new(0, newX, 0, newY)
                    mainFrame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + (diffX / 2), 
                        startPos.Y.Scale, startPos.Y.Offset + (diffY / 2)
                    )
                end
            end)

            local endCon
            endCon = UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    resizing = false
                    moveCon:Disconnect()
                    endCon:Disconnect()
                end
            end)
        end
    end)
end

return Interactions