local composer = require ("composer")
local scene = composer.newScene()
function scene:create(event)
	local group = self.view
	local background = display.newImage( "background.png" )
	background.x = 160
	background.y = 240
	background.width = 320
	background.height = 480
	group:insert(background)
    
    local names = {}
    names = {"Ieuan Weston", "Vilius Drumsta", "Matthew Murphy", "Kristof Flaks", "Potato Sack Hobo"}
    
    -- function moveNames ( self, event )
        -- if self.y < display.contentHeight + 60 then                 -- when it goes bellow screen it places it 80 pixels above the dash that was in front
            -- self.y
        -- else
            -- if isRoundOver == false then
                -- self.y = self.y + carSpeed
            -- end
        -- end
    -- end

    -- function createEventForLaneDashMovement(self)
        -- self.enterFrame = moveNames
        -- Runtime:addEventListener("enterFrame", self)
    -- end
    
    function goBackToOptions( event )        
        composer.removeScene("credits") 
        composer.gotoScene("options")
    end
    
    creditsText = {}
    for i = 1, #names do
        creditsText[i] = display.newText( names[i], display.contentWidth / 2, display.contentHeight + i * 50, "Comic Sans MS", 20 )
        -- createEventForNameMovement(creditsText[i])
        if i == #names then
            transition.to(creditsText[i], {time = 5000 + i * 500, y = -100})
        else
            transition.to(creditsText[i], {time = 5000 + i * 500, y = -100})
        end
        group:insert(creditsText[i])
    end
    timer.performWithDelay( 7000, goBackToOptions)
end
function scene:show(event)
end
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)

    
return scene