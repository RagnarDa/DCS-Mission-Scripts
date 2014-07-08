-- Capture the flag script by RagnarDa 2013

if (CTF ~= nil) then return 0 end
CTF = {}

-- - Start of settings for mission designer: -
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Units on red side (unit name):
CTF.RedUnits = {"RedUnit #001", "RedUnit #002", "RedUnit #003", "RedUnit #004", "RedUnit #005", "RedUnit #006", "RedUnit #007", "RedUnit #008"}
-- Units on blue side (unit name):
CTF.BlueUnits = {"BlueUnit #001", "BlueUnit #002", "BlueUnit #003", "BlueUnit #004", "BlueUnit #005", "BlueUnit #006", "BlueUnit #007", "BlueUnit #008"}
-- Red base unit position
CTF.RedBaseUnitPos = Unit.getByName("RED BASE"):getPosition().p
-- Blue base unit position
CTF.BlueBaseUnitPos = Unit.getByName("BLUE BASE"):getPosition().p
-- Red base location in game-world (Vec3) position format:
CTF.RedBase = {x=CTF.RedBaseUnitPos.x, z=CTF.RedBaseUnitPos.z, y=CTF.RedBaseUnitPos.y + 15}
-- Blue base location in game-world (Vec3) position format:
CTF.BlueBase = {x=CTF.BlueBaseUnitPos.x, z=CTF.BlueBaseUnitPos.z, y=CTF.BlueBaseUnitPos.y + 15}
-- Return own flag when succesfully captured enemy flag?
CTF.ReturnOnCapture = true
-- Return flag if flag carrier fires weapon?
CTF.ReturnOnFire = true
-- Triple flare or single flare
CTF.TripleFlare = false
-- Require own flag in own base for capture
CTF.OwnFlagHomeForCapture = false
-- Set to true to display error dialogs (recommend false for release)
CTF.displayerrordialog = false

-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--  - End of settings for mission designer -



-- Flags starting location is "HOME"
CTF.RedFlagHolder = "HOME"
CTF.BlueFlagHolder = "HOME"
CTF.RedFlagPosition = CTF.RedBase
CTF.BlueFlagPosition = CTF.BlueBase
CTF.RedScore = 0
CTF.BlueScore = 0
CTF.RedFlagNilHolder = ""
CTF.BlueFlagNilHolder = ""
CTF.RedFlagHolderUnit = nil
CTF.BlueFlagHolderUnit = nil

function measuredistance3(v1, v2)
	local distance = 0
	local v1x = v1.x
	local v2x = v2.x
	local v1z = v1.z
	local v2z = v2.z
        local v1y = v1.y
        local v2y = v2.y
	if v1x > v2x then
		distance = distance + (v1x - v2x)
	else
		distance = distance + (v2x - v1x)
	end
	if v1z > v2z then
		distance = distance + (v1z - v2z)
	else
		distance = distance + (v2z - v1z)
	end
        if v1y > v2y then
		distance = distance + (v1y - v2y)
	else
		distance = distance + (v2y - v1y)
	end
	return distance
end

function tablecontains(Tbl, trgt)
    local contains = false
    for _,x in pairs(Tbl) do
        if (x==trgt) then
            contains=true
        end
    end
    return contains
end

-- Flag capture loop looks for if someone takes the flags
function CTF.FlagCaptureLoop()
    local status, err = pcall(
		function (_arg)
			if CTF.BlueFlagHolder == "HOME" or CTF.BlueFlagHolder == "NOONE" then
                local _closestdist = 1000000
                local _closestunit = nil
                for _i, _RedPlane in pairs(CTF.RedUnits) do
                    local _unit = Unit.getByName(_RedPlane)
					if _unit ~= nil then
						local _pos = _unit:getPosition().p
						local _distance = measuredistance3(_pos, CTF.BlueFlagPosition)
						if (_distance < _closestdist) then
							_closestdist = _distance
							_closestunit = _RedPlane
						end
					end
                end
                if (_closestdist < 50) then
                    -- Red takes blue flag
                    trigger.action.outText(string.format("%s took the blue flag.", Unit.getPlayerName(Unit.getByName(_closestunit))), 5)
                    CTF.BlueFlagHolder = _closestunit
					CTF.BlueFlagHolderUnit = Unit.getByName(_closestunit)
					trigger.action.setUserFlag("8001", true) -- Play sound
				else
					if (CTF.BlueFlagHolder == "NOONE") then
						for _i, _BluePlane in pairs(CTF.BlueUnits) do
							local _unit = Unit.getByName(_BluePlane)
							if _unit ~= nil then
								local _pos = _unit:getPosition().p
								local _distance = measuredistance3(_pos, CTF.BlueFlagPosition)
								if (_distance < _closestdist) then
									_closestdist = _distance
									_closestunit = _BluePlane
								end
							end
						end
						if (_closestdist < 50) then
							-- Blue returns blue flag
							trigger.action.outText(string.format("%s returns the blue flag.", Unit.getPlayerName(Unit.getByName(_closestunit))), 5)
							CTF.BlueFlagHolder = "HOME"
							CTF.BlueFlagPosition = CTF.BlueBase
							trigger.action.setUserFlag("8003", true) -- Play sound
						end
                    end
                end
            else
                -- Flag is being held by someone, check if nearing own base
                if (Unit.getByName(CTF.BlueFlagHolder) ~= nil) then 
					CTF.BlueFlagPosition = Unit.getPosition(Unit.getByName(CTF.BlueFlagHolder)).p 
				else
					trigger.action.outText("Blue flag has been dropped", 5)
                    CTF.BlueFlagNilHolder = CTF.BlueFlagHolder
					CTF.BlueFlagHolder = "NOONE"
					CTF.BlueFlagPosition.y = CTF.BlueFlagPosition.y + 20
				
				end
                if (CTF.OwnFlagHomeForCapture == false or CTF.RedFlagHolder == "HOME") then
                if (measuredistance3(CTF.BlueFlagPosition, CTF.RedBase) < 50) then
                    -- Red captured blue flag
                    trigger.action.outText(string.format("%s captured the blue flag. Red team gets one point!", Unit.getPlayerName(Unit.getByName(CTF.BlueFlagHolder))), 5)
                    CTF.BlueFlagHolder = "HOME"
                    CTF.BlueFlagPosition = CTF.BlueBase
					CTF.RedScore = CTF.RedScore + 1
					trigger.action.setUserFlag("8002", true) -- Play sound
                    if (CTF.ReturnOnCapture) then
                        CTF.RedFlagHolder = "HOME"
                        CTF.RedFlagPosition = CTF.RedBase
                    end
                end
                end
            end
            -- Check posession of red flag
            if CTF.RedFlagHolder == "HOME" or CTF.RedFlagHolder == "NOONE" then
                local _closestdist = 1000000
                local _closestunit = nil
                for _i, _BluePlane in pairs(CTF.BlueUnits) do
                    local _unit = Unit.getByName(_BluePlane)
					if _unit ~= nil then
						local _pos = _unit:getPosition().p
						local _distance = measuredistance3(_pos, CTF.RedFlagPosition)
						if (_distance < _closestdist) then
							_closestdist = _distance
							_closestunit = _BluePlane
						end
					end
                end
                if (_closestdist < 50) then
                    -- Blue takes red flag
                    trigger.action.outText(string.format("%s took the red flag.", Unit.getPlayerName(Unit.getByName(_closestunit))), 5)
                    CTF.RedFlagHolder = _closestunit
					CTF.RedFlagHolderUnit = Unit.getByName(_closestunit)
					trigger.action.setUserFlag("8001", true) -- Play sound
                else
					if (CTF.RedFlagHolder == "NOONE") then
						-- No one has the flag so the red side can return it
						for _i, _RedPlane in pairs(CTF.RedUnits) do
							local _unit = Unit.getByName(_RedPlane)
							if _unit ~= nil then
								local _pos = _unit:getPosition().p
								local _distance = measuredistance3(_pos, CTF.RedFlagPosition)
								if (_distance < _closestdist) then
									_closestdist = _distance
									_closestunit = _RedPlane
								end
							end
						end
                    
						if (_closestdist < 50) then
							-- Red returns red flag
							trigger.action.outText(string.format("%s returns the red flag.", Unit.getPlayerName(Unit.getByName(_cloestunit))), 5)
							CTF.RedFlagHolder = "HOME"
							CTF.RedFlagPosition = CTF.RedBase
							trigger.action.setUserFlag("8003", true) -- Play sound
						end
					end
                end
            else
                -- Flag is being held by someone, check if nearing own base
                if (Unit.getByName(CTF.RedFlagHolder) ~= nil) then 
					CTF.RedFlagPosition = Unit.getPosition(Unit.getByName(CTF.RedFlagHolder)).p 
				else
					trigger.action.outText("Red flag has been dropped.", 5)
					CTF.RedFlagHolder = "NOONE"
                    CTF.RedFlagNilHolder = CTF.RedFlagHolder
					CTF.RedFlagPosition.y = CTF.RedFlagPosition.y + 20
				end
                if (CTF.OwnFlagHomeForCapture == false or CTF.BlueFlagHolder == "HOME") then
                if (measuredistance3(CTF.RedFlagPosition, CTF.BlueBase) < 50) then
                    -- Blue captured red flag
                    trigger.action.outText(string.format("%s captured the red flag. Blue team gets one point!", Unit.getPlayerName(Unit.getByName(CTF.RedFlagHolder))), 5)
                    CTF.RedFlagHolder = "HOME"
                    CTF.RedFlagPosition = CTF.RedBase
					CTF.BlueScore = CTF.BlueScore + 1
					trigger.action.setUserFlag("8002", true) -- Play sound
                    if (CTF.ReturnOnCapture) then
                        CTF.BlueFlagHolder = "HOME"
                        CTF.BlueFlagPosition = CTF.BlueBase
                    end
                end
                end
            end
		end
	, {""})
	if (not status) then env.error(string.format("Error in FlagCaptureLoop\n\n%s",err), CTF.displayerrordialog) end
	return timer.getTime() + 0.01
end

-- This function spawns flares representing the flags
function CTF.FlagFlares()
    local status, err = pcall(
        function (vnt)
            trigger.action.signalFlare(CTF.RedFlagPosition, trigger.flareColor.Red, 0) -- zero azimuth
			trigger.action.signalFlare(CTF.BlueFlagPosition, trigger.flareColor.Green, 0)
			if (CTF.TripleFlare == true) then
				-- "Tripple flare"
				trigger.action.signalFlare(CTF.RedFlagPosition, trigger.flareColor.Red, 90)
				trigger.action.signalFlare(CTF.RedFlagPosition, trigger.flareColor.Red, 180)
				trigger.action.signalFlare(CTF.BlueFlagPosition, trigger.flareColor.Green, 90)
				trigger.action.signalFlare(CTF.BlueFlagPosition, trigger.flareColor.Green, 180)
			end
			
			-- Check flags
			if (trigger.misc.getUserFlag("8006") == 1) then
				if (CTF.TripleFlare == true) then
					CTF.TripleFlare = false
					trigger.action.outText("Triple flare OFF", 5)
				else
					CTF.TripleFlare = true
					trigger.action.outText("Triple flare ON", 5)
				end
				trigger.action.setUserFlag("8006", false)
			end
			if (trigger.misc.getUserFlag("8007") == 1) then
				if (CTF.ReturnOnCapture == true) then
					CTF.ReturnOnCapture = false
					trigger.action.outText("Return on capture OFF", 5)
				else
					CTF.ReturnOnCapture = true
					trigger.action.outText("Return on capture ON", 5)
				end
				trigger.action.setUserFlag("8007", false)
			end
			if (trigger.misc.getUserFlag("8008") == 1) then
				if (CTF.ReturnOnFire == true) then
					CTF.ReturnOnFire = false
					trigger.action.outText("Return on firing OFF", 5)
				else
					CTF.ReturnOnFire = true
					trigger.action.outText("Return on firing ON", 5)
				end
				trigger.action.setUserFlag("8008", false)
			end
            if (trigger.misc.getUserFlag("8009") == 1) then
                if (CTF.OwnFlagHomeForCapture == false) then
                    CTF.OwnFlagHomeForCapture = true
                    trigger.action.outText("Require own flag in own base to capture flag ON", 5)
                else
                    CTF.OwnFlagHomeForCapture = false
                    trigger.action.outText("Require own flag in own base to capture flag OFF", 5)
                end
				trigger.action.setUserFlag("8009", false)
            end
		end
        , vnt)
    if (not status) then env.error(string.format("Error while popping flare\n\n%s",err), CTF.displayerrordialog) end
    return timer.getTime() + 2
end

-- Handles all world events
CTF.eventhandler = {}
function CTF.eventhandler:onEvent(vnt)
	
	local status, err = pcall(
		function (vnt)
			assert(vnt ~= nil, "Event is nil!")
			--if (vnt.initiator == nil) then return nil end
			local _unit
			local sts, _unit = pcall(
				function (_int)
					return _int
				end
			, vnt.initiator)
			if (not sts) then 
				env.warning(string.format("No event initator %s", _unit), false)
				return nil
			end
			
			if (vnt.id == 8 or vnt.id == 6 or vnt.id == 12) then
				-- Unit dead or pilot ejected
				--env.info(string.format("%s %d %s %s", CTF.RedFlagHolder, vnt.id, _unit, Unit.getByName(CTF.RedFlagHolder)), true)
				if (CTF.RedFlagHolder ~= "HOME" and CTF.RedFlagHolder ~= "NOONE" and Unit.getByName(CTF.RedFlagHolder) == nil) then --(CTF.RedFlagHolderUnit == vnt.initiator) or CTF.RedFlagNilHolder == CTF.RedFlagHolder or (Unit.getByName(CTF.RedFlagHolder) ~= nil and CTF.RedFlagHolder ~= "NOONE") or (Unit.getByName(CTF.RedFlagHolder) ~= nil and CTF.RedFlagHolder ~= "HOME")) then    
                             
			            -- Red flag holder killed
			            trigger.action.outText(string.format("%s dropped the red flag", CTF.RedFlagHolder), 5)
						CTF.RedFlagNilHolder = ""
                        CTF.RedFlagHolder = "NOONE"
					
				elseif (CTF.BlueFlagHolder ~= "HOME" and CTF.BlueFlagHolder ~= "NOONE" and Unit.getByName(CTF.BlueFlagHolder) == nil) then --(CTF.BlueFlagHolderUnit == vnt.initiator or CTF.BlueFlagNilHolder == CTF.BlueFlagHolder or (Unit.getByName(CTF.BlueFlagHolder) ~= nil and CTF.BlueFlagHolder ~= "NOONE") or (Unit.getByName(CTF.BlueFlagHolder) ~= nil and CTF.BlueFlagHolder ~= "HOME")) then
                        -- Blue flag holder killed
			            trigger.action.outText(string.format("%s dropped the blue flag", CTF.BlueFlagHolder), 5)
						CTF.BlueFlagNilHolder = ""
                        CTF.BlueFlagHolder = "NOONE"
				end
			end
            if (CTF.ReturnOnFire == true) then
				if (vnt.id == 1 or vnt.id == 23) then
					-- Unit shot weapon
					if (Unit.getByName(CTF.RedFlagHolder) == _unit) then
						-- Red flag holder fired and loses flag
						trigger.action.outText(string.format("%s returned the red flag by firing.", Unit.getPlayerName(Unit.getByName(CTF.RedFlagHolder))), 5)
						CTF.RedFlagHolder = "HOME"
						CTF.RedFlagPosition = CTF.RedBase
						trigger.action.setUserFlag("8003", true) -- Play sound
					end
					if (Unit.getByName(CTF.BlueFlagHolder) == _unit) then
						-- Blue flag holder fired and loses flag
						trigger.action.outText(string.format("%s returned the blue flag by firing.", Unit.getPlayerName(Unit.getByName(CTF.BlueFlagHolder))), 5)
						CTF.BlueFlagHolder = "HOME"
						CTF.BlueFlagPosition = CTF.BlueBase
						trigger.action.setUserFlag("8003", true) -- Play sound
					end
                end
            end
		end
	
	, vnt)
	if (not status) then env.error(string.format("Error while handling event\n\n%s",err), CTF.displayerrordialog) end
end

-- Showes scores periodically
function CTF.ShowScore()
    local redfpos = "Error - ?Red flag unknown?"
    local bluefpos = "Errorn - ?Blue flag unknown?"
    if CTF.RedFlagHolder == "NOONE" then
        redfpos = "No one is in posession of the red flag."
    elseif CTF.RedFlagHolder == "HOME" then
        redfpos = "The red flag is in the red base."
    else
        redfpos = string.format("%s has the red flag.", Unit.getPlayerName(Unit.getByName(CTF.RedFlagHolder)))
    end
    if CTF.BlueFlagHolder == "NOONE" then
        bluefpos = "No one is in posession of the blue flag."
    elseif CTF.BlueFlagHolder == "HOME" then
        bluefpos = "The blue flag is in the blue base."
    else
        bluefpos = string.format("%s has the blue flag.", Unit.getPlayerName(Unit.getByName(CTF.BlueFlagHolder)))
    end
    trigger.action.outText(string.format("Score now\n\nRed team: %d\nBlue team: %d\n\n%s\n%s",CTF.RedScore, CTF.BlueScore, redfpos, bluefpos), 10)
    return timer.getTime() + 20
end

world.addEventHandler(CTF.eventhandler)
timer.scheduleFunction(CTF.FlagFlares, {}, timer.getTime() + 2)
timer.scheduleFunction(CTF.ShowScore, {}, timer.getTime() + 20)
timer.scheduleFunction(CTF.FlagCaptureLoop, {}, timer.getTime() + 1)

trigger.action.setUserFlag("8006", false)
trigger.action.setUserFlag("8007", false)
trigger.action.setUserFlag("8008", false)
trigger.action.setUserFlag("8009", false)
trigger.action.addOtherCommand("(On/Off) Triple flares.", "8006", 1)
trigger.action.addOtherCommand("(On/Off) Return flag when other side captures.", "8007", 1)
trigger.action.addOtherCommand("(On/Off) Return flag when firing.", "8008", 1)
trigger.action.addOtherCommand("(On/Off) Require own flag for capture", "8009", 1)