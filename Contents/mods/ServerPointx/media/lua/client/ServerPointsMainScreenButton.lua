local ServerPointsUI = require "ServerPointsUI"
local SimpleUI = require "SimpleUI"  -- Add this line to include your SimpleUI

local oldMainScreen_render = MainScreen.render
local function newRender(self)
    oldMainScreen_render(self)

    if self.inGame and isClient() then
        self.bottomPanel:setHeight(self.pointsOption:getBottom())
    end
end

local oldMainScreen_instantiate = MainScreen.instantiate
function MainScreen:instantiate()
    oldMainScreen_instantiate(self)

    if self.inGame and isClient() then
        local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
        local core = getCore()
        local width = 800 * FONT_SCALE
        local height = 600 * FONT_SCALE
        self.serverPoints = ServerPointsUI:new((core:getScreenWidth() - width) / 2, (core:getScreenHeight() - height) / 2, width, height)
        self.serverPoints:initialise()
        self.serverPoints:setVisible(false)
        self.serverPoints:setAnchorRight(true)
        self.serverPoints:setAnchorBottom(true)
        self:addChild(self.serverPoints)

        local labelHgt = getTextManager():getFontHeight(UIFont.Large) + 8 * 2
        self.pointsOption = ISLabel:new(self.quitToDesktop.x, self.quitToDesktop.y + labelHgt + 16, labelHgt, string.upper(SandboxVars.ServerPoints.PointsName) .. " SHOP", 1, 1, 1, 1, UIFont.Large, true)
        self.pointsOption.internal = "POINTS"
        self.pointsOption:initialise()
        self.bottomPanel:addChild(self.pointsOption)
        self.render = newRender
        self.pointsOption.onMouseDown = function()
            getSoundManager():playUISound("UIActivateMainMenuItem")
            MainScreen.instance.serverPoints:setVisible(true)
            MainScreen.instance.simpleUI:setVisible(true)
        end
        self.pointsOption.onMouseMove = function(self)
            self.fade:setFadeIn(true)
        end
        self.pointsOption.onMouseMoveOutside = function(self)
            self.fade:setFadeIn(false)
        end
        self.pointsOption:setWidth(self.quitToDesktop.width)
        self.pointsOption.fade = UITransition.new()
        self.pointsOption.fade:setFadeIn(false)
        self.pointsOption.prerender = self.prerenderBottomPanelLabel

        -- Add your Simple UI component reverved for transfer ui------------------------
        local simpleUIWidth = 400
        local simpleUIHeight = 100
        local marginBottom = 100
        self.simpleUI = SimpleUI:new((core:getScreenWidth() - simpleUIWidth) / 2, core:getScreenHeight() - simpleUIHeight - marginBottom, simpleUIWidth, simpleUIHeight)
        self.simpleUI:initialise()
        self.simpleUI:setVisible(false)
        self:addChild(self.simpleUI)
    end
end

local timerEndTime = nil

function ShowServerPointsUI(duration)
    if MainScreen and MainScreen.instance and MainScreen.instance.serverPoints then
        MainScreen.instance.serverPoints:setVisible(true)
        print("ServerPoints UI is now visible.")

        duration = duration or (60 * 5)

        timerEndTime = os.time() + duration

        Events.OnTick.Add(CheckServerPointsUITimer)
    else
        print("Error: MainScreen or serverPoints UI is not initialized.")
    end
end

function HideServerPointsUI()
    if MainScreen and MainScreen.instance and MainScreen.instance.serverPoints then
        MainScreen.instance.serverPoints:setVisible(false)
        print("ServerPoints UI is now hidden.")
    else
        print("Error: MainScreen or serverPoints UI is not initialized.")
    end
end

function CheckServerPointsUITimer()
    -- Compare the current real-world time with the timer end time
    if timerEndTime and os.time() >= timerEndTime then
        HideServerPointsUI()
        timerEndTime = nil
        Events.OnTick.Remove(CheckServerPointsUITimer)
    end
end