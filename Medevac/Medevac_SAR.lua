-- MEDEVAC Script for DCS, By RagnarDa 2013
			

medevac = {}

-- SETTINGS FOR MISSION DESIGNER vvvvvvvvvvvvvvvvvv

medevac.medevacunits = {"MEDEVAC #1", "MEDEVAC #2"} -- List of all the MEDEVAC _UNIT NAMES_ (the line where it says "Pilot" in the ME)!
medevac.bluemash = {"BlueMASH #1", "BlueMASH #2"} -- The unit that serves as MASH for the blue side
medevac.redmash = {"RedMASH #1", "RedMASH #2"} -- The unit that serves as MASH for the red side
medevac.maxbleedtime = 1800 -- Maximum time that the wounded will bleed in the transport before dying
medevac.bluesmokecolor = 4 -- Color of smokemarker for blue side, 0 is green, 1 is red, 2 is white, 3 is orange and 4 is blue
medevac.redsmokecolor = 1 -- Color of smokemarker for red side, 0 is green, 1 is red, 2 is white, 3 is orange and 4 is blue
medevac.requestdelay = 5 -- Time in seconds before the survivors will request Medevac
medevac.coordtype = 3 -- Use Lat/Long DDM (0), Lat/Long DMS (1), MGRS (2), Bullseye imperial (3) or Bullseye metric (4) for coordinates.
medevac.displaymapcoordhint = false -- Change to false to disable the hint about changing coordinates on the F10-map
medevac.displayerrordialog = false -- Set to true to display error dialog on fatal errors. Recommend set to false in live game.
medevac.displaymedunitslist = false -- Set to true to see what medevac units are in the mission at the start.
medevac.bluecrewsurvivepercent = 100 -- Percentage of blue crews that will make it out of their vehicles. 100 = all will survive.
medevac.redcrewsurvivepercent = 100 -- Percentage of red crews that will make it out of their vehicles. 100 = all will survive.
medevac.showbleedtimer = false -- Set to true to see a timer counting down the time left for the wounded to bleed out
medevac.sar_pilots = true -- Set to true to allow for Search & Rescue missions of downed pilots
medevac.immortalcrew = false -- Set to true to make wounded crew immortal
medevac.rpgsoldier = false -- Set to true to spawn one of the wounded as a RPG-carrying soldier
medevac.clonenewgroups = false -- Set to true to spawn in new units (clones) of the rescued unit once they're rescued back to the MASH

-- SETTINGS FOR MISSION DESIGNER ^^^^^^^^^^^^^^^^^^^*

-- Changelog v 4.2
-- - Verified compatibility with MiST 3.2+ and removed compatibility with SCT.

-- Changelog v 4.1
-- - Added so units will place new smoke if the medevac crashes (requested by Xillinx)

-- Changelog v 4 alexej21
-- - Added option for immortal wounded.
-- - Added option for spawning every third crew as an RPG soldier.

-- Changelog v 4
-- - Added option medevac.sar_pilots for those that want to turn off the search for downed pilot feature, which
-- is probably better done by other scripts.

-- Changelog v 3.2
-- - Added possibility for multiple MASH:es
-- - Added option to hide bleedout timer.

-- Changelog v 3.1
-- - Added check so that MASH is on right coalition.
-- - Removed option to use MiST-messaging as it is not working.
-- - Added option to change color of smoke for each side


-- Sanity checks of mission designer
assert(medevac.bluemash ~= nil, "\n\n** HEY MISSION-DESIGNER!**\n\nThere is no MASH for blue side!\n\nMake sure medevac.bluemash points to\na live units.\n")
for nr,x in pairs(medevac.bluemash) do 
	assert(Unit.getByName(x) ~= nil, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nThe blue MASH '%s' doesn't exist!\n\nMake sure medevac.bluemash contains the\nnames of live units.\n", x))
	assert((Group.getCoalition(Unit.getGroup(Unit.getByName(x))) == 2), string.format("\n\n** HEY MISSION-DESIGNER!**\n\nmedevac.bluemash has to be units on BLUE coalition only!\nUnit '%s' is not on correct side.", x))
end
assert(medevac.redmash ~= nil, "\n\n** HEY MISSION-DESIGNER! **\n\nThere is no MASH for red side!\n\nMake sure medevac.redmash points to\na live unit.\n")
for nr,x in pairs(medevac.redmash) do 
	assert(Unit.getByName(x) ~= nil, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nThe red MASH '%s' doesn't exist!\n\nMake sure medevac.redmash contains the\nnames of live units.\n", x))
	assert((Group.getCoalition(Unit.getGroup(Unit.getByName(x))) == 1), string.format("\n\n** HEY MISSION-DESIGNER!**\n\nmedevac.redmash has to be units on RED coalition only!\nUnit '%s' is not on correct side.", x))
end
assert(mist ~= nil, "\n\n** HEY MISSION-DESIGNER! **\n\nMiST has not been loaded!\n\nMake sure MiST 2.0 is running\n*before* running this script!\n")
--assert(sct ~= nil, "\n\n** HEY MISSION-DESIGNER! **\n\nSCT has not been loaded!\n\nMake sure SCT is running\n*before* running this script!\n")

function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

medevac.smokemarkers = {}
medevac.woundedgroups = {}
medevac.pickedupgroups = {}
medevac.deadunits = {}
medevac.menupaths = table.copy(medevac.medevacunits)



function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function tablecontains(Tbl,trgt)
	local contains = false
	for _,x in pairs(Tbl) do 
		if (x==trgt) then 
			contains=true 
		end
	end
	return contains
end

-- Get average amount of health of group compared to what it started with
function getGroupHealthPercentage(grp)
	local sts, rtrn = pcall(
		function (_grp)
			local units = Group.getUnits(_grp)
			local _unitcount = tablelength(units)
			local _totalnow = 0
			local _totalthen = 0
			for nr,x in pairs(units) do
				_totalnow = _totalnow + Unit.getLife(x)
				if (_totalnow <= 1.0) then _totalnow = 0 end
				_totalthen = _totalthen + Unit.getLife0(x)
			end
			local percentage = ((_totalnow/_totalthen) * 100)
			-- if (percentage ~= 100 and (gci.verbose > 0)) then env.info(string.format("%s group health: %d", Group.getName(grp), percentage), false) end
			return percentage
		end
	, grp)
	if (sts) then 
		return rtrn 
	else 
		env.warning(string.format("getGroupHealthPercentage() failed! Returning 0. %s", rtrn), false)
		return 0
	end
end

function measuredistance(v1, v2)
	local distance = 0
	local v1x = v1.x
	local v2x = v2.x
	local v1z = v1.z
	local v2z = v2.z
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
	return distance
end

function SetWaypoints(_groupName, _waypoints)
	local _points = {}
	for nr,x in pairs(_waypoints) do 
		_points[nr] = x
	end
	Mission = { 
			id = 'Mission', 
			params = { 
				route = { 
					points = _points 
				}, 
			} 
		}
	local _controller = Group.getByName(_groupName):getController();
	--Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
	_controller:setTask(Mission)
end

function BleedTimer(_argument, _time)
	--env.info("Bleed timer.", false)
	local _status, _timetoreset = pcall(
		function (_argument)
			local _medevacunit = _argument[1]
			local _pickuptime = _argument[2]
			local _oldgroup = _argument[3]
			local _rescuegroup = _argument[4]
			local _medevacname = _argument[5]
			if (_medevacunit == nil) then
				env.info("Helicopter is nil.",false)
				return nil
			end
			local sts, rtrn = pcall(
				function (_medevacunit)
					if (Unit.getLife(_medevacunit) <= 1.0) then	
						return true
					end
				end
			, _medevacunit)
			if (rtrn or not sts) then 
				env.info("Helicopter is dead.", false)
				return nil
			end
				
	
			--local _woundtime = _argument[3]
			--local _mash = StaticObject.getByName("MASH")
			--assert(not MASH == nil, "There is no MASH!")
			
			local _mashes = medevac.bluemash
			if (Group.getCoalition(Unit.getGroup(_medevacunit)) == 1) then
				_mashes = medevac.redmash
			end
			local _medevacid = Group.getID(Unit.getGroup(_medevacunit))
			local _timeleft = math.floor(0 + (_pickuptime - timer.getTime()))
			if (_timeleft < 1) then
				-- trigger.action.outTextForGroup(_medevacid, string.format("The wounded has bled out.", _timeleft), 20)
				local _txt = string.format("%s: The wounded has died of his wounds.", _rescuegroup)
			
				medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 30)
				return nil
			end
			for nr,x in pairs(_mashes) do 
				local _mash = Unit.getByName(x)
		
				local _mashpos = _mash:getPosition().p
				local _status, _helipoint = pcall(
				function (_medevacunitarg)
					return _medevacunitarg:getPosition().p
				end
				,_medevacunit)
				if (not _status) then env.error(string.format("Error while _helipoint\n\n%s",_helipoint), medevac.displayerrordialog) end
				local _status, _distance = pcall(
					function (_distargs)
						local _rescuepoint = _distargs[1]
						local _evacpoint = _distargs[2]
						return measuredistance(_rescuepoint, _evacpoint)
					end
				,{_mashpos, _helipoint})
				if (not _status) then env.error(string.format("Error while measuring distance\n\n%s",_distance), medevac.displayerrordialog) end
				local _velv = _medevacunit:getVelocity()
				local _medspeed = mist.vec.mag(_velv)--string.format('%12.2f', mist.vec.mag(_velv))

				if (_medspeed < 1 and _distance < 200 and _medevacunit:inAir() == false) then
					--trigger.action.outTextForGroup(_medevacid, string.format("The wounded has been taken to the\nmedical clinic. Good job!", "Good job!"), 30)
					local _txt = string.format("%s: The wounded has been taken to the\nmedical clinic. Good job!", _rescuegroup)
			
					medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 10)
					if (medevac.clonenewgroups) then
						--sct.cloneInZone(_oldgroup, "SpawnZone", true, 100)
						-- trigger.action.outTextForGroup(_medevacid, string.format("The wounded has been taken to the\nmedical clinic. Good job!\n\nReinforcment have arrived.", "Good job!"), 30)
						local _txt = string.format("%s: The wounded has been taken to the\nmedical clinic. Good job!\n\nReinforcment have arrived.", _rescuegroup)
			
						medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 10)
			
						mist.cloneGroup(_oldgroup, true)
					end
					return nil
				end
			end
			-- trigger.action.outTextForGroup(_medevacid, string.format("Bring them back to the MASH ASAP!\n\nThe wounded will bleed out in: %u seconds.", _timeleft), 2)
			local _howcritical = "This is hurting a bit. Please get us home."
			if (_timeleft < 1000) then
				_howcritical = "Don't fly around aimlessly, we have wounded here!"
			end
			if (_timeleft < 800) then
				_howcritical = "Oh my! This hurts!"
			end
			if (_timeleft < 600) then
				_howcritical = "Hey! We got a wounded here that needs medical attention ASAP."
			end
			if (_timeleft < 400) then
				_howcritical = "This doesn't look good. Please step on it!"
			end
			if (_timeleft < 200) then
				_howcritical = "He has lost a lot of blood! We have to get him to the hospital NOW!"
			end
			if (_timeleft < 50) then
				_howcritical = "We're losing him!"
			end
			if (_timeleft < 30) then
				_howcritical = "It's just so much blood!"
			end
			if (_timeleft < 10) then
				_howcritical = "..."
			end
			
			local _txt = string.format("%s: %s\n\nThe wounded will bleed out in: %u seconds.", _rescuegroup, _howcritical, _timeleft)
			if (medevac.showbleedtimer == false) then
				_txt = string.format("%s: %s", _rescuegroup, _howcritical)
			end
			medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 2)
			return timer.getTime() + 1
		end
   , _argument)
	if (not _status) then env.error(string.format("Error while BleedTime\n\n%s",_timetoreset), medevac.displayerrordialog) end
	return _timetoreset
end

function LandEvent(_argument, _time)
	local _status, _err = pcall(
	function (_argument)
	local _medevacunit = _argument[1]
	local _rescuegroup = _argument[2]
	local _oldgroup = _argument[3]
	local _medevacname = _argument[4]
	local _status, _err = pcall(
		function (_medevacunit, _rescuegroup)
			if (getGroupHealthPercentage(Group.getByName(_rescuegroup)) < 0.1) then
				if (tablecontains(medevac.pickedupgroups, _rescuegroup)) then
					env.info("Group has been picked up by another helicopter.", false)
					medevac.DisplayMessage(string.format("%s has been picked up by someone else.", _rescuegroup), _medevacname, _rescuegroup, 10)
				else
					env.info("Group to rescue is dead.", false)
					removeintable(medevac.woundedgroups,_rescuegroup)
					medevac.DisplayMessage(string.format("%s is dead.", _rescuegroup), _medevacname, _rescuegroup, 10)
				end
				return -1
			end
			return Group.getUnits(Group.getByName(_rescuegroup))[1]:getPosition().p
		end
	, _medevacunit, _rescuegroup)
	if (not _status or _err == -1) then
		removeintable(medevac.woundedgroups,_rescuegroup)
		env.info(string.format("Rescue group is (probably) dead.\n%s", _err), false)
		return nil
	else
		_rescuepoint = _err
	end
	local _status, _err = pcall(
		function (_medevacunit)
			if (Unit.getLife(_medevacunit) <= 1.0) then
				env.info("Helicopter is dead.", false)
				env.info("Rescheduling smokeevent.", false)
				local _medevacunit = _argument[1]
				local _rescuegroup = _argument[2]
				local _oldgroup = _argument[3]
				local _medevacname = _argument[4]
				local _rescuepoint = _argument[5]
				
				timer.scheduleFunction(SmokeEvent, {_rescuepoint, _medevacname, _rescuegroup, _oldgroup}, timer.getTime() + 10) 
				return -1
			end
		end
	, _medevacunit)
	if (not _status or _err == -1) then
		env.info(string.format("Helicopter is (probably) dead.\n%s",_err), false)
		return nil
	end
	
	local _medevacid = Group.getID(Unit.getGroup(_medevacunit))
	local _evacpoint = {}
	

	
	

	
	local _status, _evacpoint = pcall(
		function (_medevacunitarg)
			return _medevacunitarg:getPosition().p
		end
   ,_medevacunit)
	if (not _status) then env.error(string.format("Error while _evacpoint\n\n%s",_evacpoint), medevac.displayerrordialog) end
	
	local _status, _distance = pcall(
		function (_distargs)
			local _rescuepoint = _distargs[1]
			local _evacpoint = _distargs[2]
			return measuredistance(_rescuepoint, _evacpoint)
		end
   ,{_rescuepoint, _evacpoint})
	if (not _status) then env.error(string.format("Error while measuring distance\n\n%s",_distance), medevac.displayerrordialog) end
	
	-- local _alt = land.getHeight(_evacpoint)
	-- local _agl = _evacpoint.y - _alt
	-- trigger.action.outTextForGroup(_medevacid, string.format("Altitude now: %f", _agl), 10)
	
	local _velv = _medevacunit:getVelocity()
	local _medspeed = mist.vec.mag(_velv)--string.format('%12.2f', mist.vec.mag(_velv))
	--trigger.action.outTextForGroup(_medevacid, string.format("Speed: %f", _medspeed),10)
	local _status, _err = pcall(
		function (_args)
		_medspeed = _args[1]
		_distance = _args[2]
		_medevacunit = _args[3]
		_medevacid = _args[4]
		_rescuegroup = _args[5]
		_oldgroup = _args[6]
		_medevacname = _args[7]
		if (_medspeed < 1 and _distance < 200 and _medevacunit:inAir() == false) then
			local _txt = "Units picked up!\n\nBring them back to MASH ASAP!"
			table.insert(medevac.pickedupgroups, _rescuegroup)
			removeintable(medevac.woundedgroups,_rescuegroup)
			-- trigger.action.outTextForGroup(_medevacid, string.format("Units picked up!\n\nBring them back to MASH ASAP!", _agl), 10)
			medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 20)
			Group.destroy(Group.getByName(_rescuegroup))
			timer.scheduleFunction(BleedTimer, {_medevacunit, math.random(0, medevac.maxbleedtime) + timer.getTime(), _oldgroup, _rescuegroup, _medevacname}, timer.getTime() + 1) 
			return -1
		end
	end
   ,{_medspeed, _distance, _medevacunit, _medevacid, _rescuegroup, _oldgroup, _medevacname})
	if (not _status) then env.error(string.format("Error while picking up\n\n%s",_err), medevac.displayerrordialog) end
	if (_err == -1) then return nil end
	
	if (_distance < 600 and _distance > 500) then
		--local _moveblend = 0 - (1/(_distance/200))
		
		
		local _moveto = getpointbetween(Group.getUnits(_medevacunit:getGroup())[1]:getPosition().p, Group.getByName(_rescuegroup):getUnits()[1]:getPosition().p, 0.2)
		
		
		--local _moveto = getpointbetween(_rescuepoint, _evacpoint, 0.2)
		Mission = { 
			id = 'Mission', 
			params = { 
				route = { 
					points = { 
						[1] = {
								action = 0,
								x = Group.getByName(_rescuegroup):getUnits()[1]:getPosition().p.x, 
								y = Group.getByName(_rescuegroup):getUnits()[1]:getPosition().p.z, 
								speed = 25,
								ETA = 100,
								ETA_locked = false,
								name = "Starting point", 
								task = nil 
						},
						[2] = {
								action = 0,
								x = _moveto.x, 
								y = _moveto.z, 
								speed = 25,
								ETA = 100,
								ETA_locked = false,
								name = "Pick-up", 
								task = nil 
						},  
					} 
				}, 
			} 
		}
		local _controller = Group.getByName(_rescuegroup):getController();
		Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
		_controller:setTask(Mission)
		-- Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
	end
	return timer.getTime() + 2
	end
	,_argument)
	if (not _status) then env.error(string.format("Error while LandEvent\n\n%s",_err), medevac.displayerrordialog) end
	return _err
end

function SmokeEvent(_argument, _time)
local _status, _err = pcall(
		function (_argument)
   local _rescuepoint = _argument[1]
   local _medevacname = _argument[2]
   local _medevacunit = Unit.getByName(_medevacname)
   local _rescuegroup = _argument[3]
   local _oldgroup = _argument[4]
    local _status, _err = pcall(
		function (_medevacunitarg, _rescuegroup, _medevacname)
			if (Unit.getLife(_medevacunit) <= 1.0) then
				env.info("Helicopter is dead.", false)
				return -1
			end
		
			if (getGroupHealthPercentage(Group.getByName(_rescuegroup)) < 0.1) then
				env.info("Group to rescue is dead.", false)
				medevac.DisplayMessage(string.format("%s is dead.", _rescuegroup), _medevacname, _rescuegroup, 10)
				removeintable(medevac.woundedgroups,_rescuegroup)
				return -1
			end
		end
	, _medevacunitarg, _rescuegroup, _medevacname)
	if (_status ~= true or _err == -1) then env.info(string.format("Helicopter or group to rescue is dead.\n%s",_err), false) return nil end
	
	
   local _medevacid = Group.getID(Unit.getGroup(_medevacunit))
   
   local _status, _evacpoint = pcall(
		function (_medevacunitarg)
			return _medevacunitarg:getPosition().p
		end
   ,_medevacunit)
	if (not _status) then env.error(string.format("Error while _evacpoint\n\n%s",_evacpoint), medevac.displayerrordialog) end
   -- local _evacpoint = _medevacunit:getPosition().p
   local _status, _distance = pcall(
		function (_distargs)
			local _rescuepoint = _distargs[1]
			local _evacpoint = _distargs[2]
			return measuredistance(_rescuepoint, _evacpoint)
		end
   ,{_rescuepoint, _evacpoint})
	if (not _status) then env.error(string.format("Error while measuring distance\n\n%s",_distance), medevac.displayerrordialog) end
   -- local _distance = measuredistance(_rescuepoint, _evacpoint)
   -- trigger.action.outTextForGroup(_medevacid, string.format("Distance now: %f", _distance), 10)
   
   if (_distance < 3000) then
   		-- Helicopter is within 3km
		local _status, _err = pcall(
		function (_args)
			_medevacunit = _args[1]
			_rescuepoint = _args[2]
			_oldgroup = _args[3]
			_rescuegroup = _args[4]
			_medevacname = _args[5]
			-- trigger.action.outTextForGroup(_medevacid, "Land by the smoke.", 10)
			local _txt = string.format("%s: We see you! Land by the smoke.", _rescuegroup)
			medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 300)
			
			local smokenear = false
			for _,x in pairs(medevac.smokemarkers) do 
				local _smokepoint = x[1]
				local _smoketime = x[2]
				local _smokedistance = measuredistance(_rescuepoint, _smokepoint)
				
				--trigger.action.outTextForGroup(_medevacid, _txt, 10)
				
				if (_smokedistance < 400 and ((_smoketime + 300) > timer.getTime() )) then 
					local _txt = string.format("%s: We are %u meters from the smoke! Do you see us?", _rescuegroup, math.floor(_smokedistance / 10) * 10, ((_smoketime + 300) - timer.getTime() ))
					medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 300)
					smokenear = true
				end
			end
			local alt = land.getHeight(_rescuepoint)
			if (smokenear == false) then 
				local _woundcoal = Group.getCoalition(Group.getByName(_rescuegroup))
				local _smokecolor = medevac.redsmokecolor
				if (_woundcoal == 2) then
					_smokecolor = medevac.bluesmokecolor
				end
				trigger.action.smoke(_rescuepoint, _smokecolor) 
				table.insert(medevac.smokemarkers, {_rescuepoint, timer.getTime()})
			end
			timer.scheduleFunction(LandEvent, {_medevacunit, _rescuegroup, _oldgroup, _medevacname}, timer.getTime() + 2) 
		end
		,{_medevacunit, _rescuepoint, _oldgroup, _rescuegroup, _medevacname})
		if (not _status) then env.error(string.format("Error while planting smoke:\n\n%s",_err), medevac.displayerrordialog) end
		--trigger.action.smoke({x = _rescuepoint.x + 5, y = _rescuepoint.y, z = _rescupoint.z}, 1)
		return nil
   end
   
   return timer.getTime() + 10
   end
	,_argument)
	if (not _status) then env.error(string.format("Error while SmokeEvent\n\n%s",_err), medevac.displayerrordialog) end
	return _err
end

-- Finds a point betweem two points according to a given blend (0.5 = right between, 0.3 = a third from point1)
function getpointbetween(point1, point2, blend)
	return {
		x = point1.x + blend * (point2.x - point1.x),
		y = point1.y + blend * (point2.y - point1.y),
		z = point1.z + blend * (point2.z - point1.z)
	}
end

-- Removes target from a array/table and returns true if the item was removed
function removeintable(Tbl,trgt)
	local removed = false
	for nr,x in pairs(Tbl) do 
		if (x==trgt) then 
			table.remove(Tbl,nr)
			removed=true 
		end
	end
	return removed
end

-- Unittest removeintable
local unittesttbl = {1,2,3}
assert(removeintable(unittesttbl,2) == true, "Unittest 1 of removeintable failed!")
assert(unittesttbl[1] == 1 and unittesttbl[2] == 3, "Unittest 2 of removeintable failed!")

-- Displays all active MEDEVACS/SAR
function medevac.displayactive(_unit)
	local _msg = "Active MEDEVAC/SAR:"
	local _unitcoal = Group.getCoalition(Unit.getGroup(Unit.getByName(_unit)))
	for nr,x in pairs(medevac.woundedgroups) do 
		local sts, _grp = pcall(
			function (x)
				return Group.getByName(x)
			end
			, x)
		if (sts and _grp ~= nil) then
			local _woundcoal = Group.getCoalition(_grp)
			if (_woundcoal == _unitcoal) then
				_unittable = {Group.getUnits(_grp)[1]:getName()} -- Get name of first unit
				local _coordinatestext = "ERROR!"
				if (medevac.coordtype == 0) then -- Lat/Long DMTM
					_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 0}))
				end
				if (medevac.coordtype == 1) then -- Lat/Long DMS
					_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 1}))
				end
				if (medevac.coordtype == 2) then -- MGRS
					_coordinatestext = string.format("%s", mist.getMGRSString({units = _unittable, acc = 3}))
				end
				if (medevac.coordtype == 3) then -- Bullseye Imperial
					_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
				end
				if (medevac.coordtype == 4) then -- Bullseye Metric
					_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0, metric = 1}))
				end
				_msg = string.format("%s\n%s at %s", _msg, x, _coordinatestext)
			end
		end
	end
	medevac.DisplayMessage(_msg, _unit, string.format("Activemedevacs %s", _unit), 20)
end


-- Handles all world events
medevac.eventhandler = {}
function medevac.eventhandler:onEvent(vnt)
	local status, err = pcall(
		function (vnt)
			
			
			assert(vnt ~= nil, "Event is nil!")
			
			-- Non-working code:
			if (vnt.id == 19) then
				-- Unit is born
				env.info(string.format("Player enter unit: %s", vnt.initiator:getName()), false)
				
				if (tablecontains(medevac.medevacunits, vnt.initiator:getName())) then
					-- Unit is a Medevac unit, add command
					missionCommands.addCommandForGroup(
					Group.getID(vnt.initiator:getGroup()),
					"Active MEDEVAC/SAR",
					nil,
					medevac.displayactive
					, vnt.initiator:getName())
					env.info(string.format("Added radioitem for group: %s", vnt.initiator:getName()), false)
				end
			end
			-- ^^^^^^^ NOT WORKING ^^^^^^
			
			
			if (vnt.id == 9 and medevac.sar_pilots == true) then
				-- Pilot dead
				local _grp = Unit.getGroup(vnt.initiator)
				local _groupname = _grp:getName()
				local _unittable = {vnt.initiator:getName()}--string.format("[g]%s", _groupname)
				local _woundcoal = Group.getCoalition(_grp)
				local _coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
				
				trigger.action.outTextForCoalition(_woundcoal, string.format("MAYDAY MAYDAY! Airman down %s. No chute.", _coordinatestext), 20)
			end
			
			if ((vnt.id == 8 and vnt.initiator ~= nil) or (vnt.id == 6 and medevac.sar_pilots == true)) then
				-- Unit dead (or pilot ejected)
				local _ispilot = false
				env.info(string.format("Event unit dead/pilot ejected", nil), false)
				
				-- Check if event has been fired more than once
				if (tablecontains(medevac.deadunits, vnt.initiator)) then 
					env.warning(string.format("Event already fired for this unit. Exiting.", nil), false)
					return nil
				end
				table.insert(medevac.deadunits,vnt.initiator)
				
				if (vnt.id == 6) then 
					_ispilot = true 
					local _grp = Unit.getGroup(vnt.initiator)
					local _groupname = _grp:getName()
					local _unittable = {vnt.initiator:getName()}--string.format("[g]%s", _groupname)
					local _woundcoal = Group.getCoalition(_grp)
					local _coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
				
					trigger.action.outTextForCoalition(_woundcoal, string.format("MAYDAY MAYDAY! Airman down %s. Chute spotted.", _coordinatestext), 20)
				end
				
				local _unit = vnt.initiator
				if (vnt.initiator == nil) then return nil end
				local _grp
				local sts, _grp = pcall(
					function (_int)
						return Group.getName(Unit.getGroup(_int))
					end
				, vnt.initiator)
				if (not sts) then 
					env.warning(string.format("No event initator", ""), false)
					return nil
				end
				
				local _woundcoal = Group.getCoalition(Group.getByName(_grp))
				local _crsurviveperc = medevac.redcrewsurvivepercent
				local _rndsurv = math.random(-1, 99)
				if (_woundcoal == 2) then
					_crsurviveperc = medevac.bluecrewsurvivepercent
				end
				if (_crsurviveperc < _rndsurv and _ispilot == false) then
					env.info(string.format("Crew from %s didn't make it. %u/%u", _grp, _rndsurv, _crsurviveperc), false)
					return nil
				end
				
				if (Object.hasAttribute(_unit, "Ground vehicles") or _ispilot) then
					
					local _pos = Object.getPoint(_unit)
					local _coord1, _coord2, _dist = coord.LOtoLL(_pos)
					local _tarpos = _pos
					local _idroot = math.random(1000, 10000)
					local _n = 1
					local _groupname = string.format("%s wounded crew #%u", _grp, _n)
					if (_ispilot) then _groupname = string.format("%s downed pilot #%u", _grp, _n) end
					while (_n < 100) do
						if (tablecontains(medevac.woundedgroups,_groupname) or Group.getByName(_groupname) ~= nil) then
							_n = _n + 1
							_groupname = string.format("%s wounded crew #%u", _grp, _n)
							if (_ispilot) then _groupname = string.format("%s downed pilot #%u", _grp, _n) end
						else
							table.insert(medevac.woundedgroups,_groupname)
							_n = 110
						end
					end
					--local _groupname = string.format("Wounded infantry #%f", _idroot)
	
					
					
					local _country = 0
					local _infantry = "Infantry AK"
					local _thirdinfantry = "Infantry AK"
					if (medevac.rpgsoldier) then _thirdinfantry = "Soldier RPG" end
					if (_woundcoal == 2) then 
						_country = 2 
						_infantry = "Soldier M4"
						_thirdinfantry = "Soldier M4"
						if (medevac.rpgsoldier) then _thirdinfantry = "Soldier RPG" end
					end
					
					if (_ispilot) then
						--_infantry = "pilot_parashut"
						coalition.addGroup(_country, Group.Category.GROUND, {
								["visible"] = false,
                                ["taskSelected"] = true,
                                ["route"] = 
                                {
                                    ["spans"] = 
                                    {
                                        [1] = 
                                        {
                                            [1] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [1]
                                            [2] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [2]
                                        }, -- end of [1]
                                    }, -- end of ["spans"]
                                    ["points"] = 
                                    {
                                        [1] = 
                                        {
                                            ["alt"] = 18,
                                            ["type"] = "Turning Point",
                                            ["ETA"] = 0,
                                            ["alt_type"] = "BARO",
                                            ["formation_template"] = "",
                                            ["y"] = _tarpos.z,
                                            ["x"] = _tarpos.x,
                                            ["ETA_locked"] = true,
                                            ["speed"] = 5.5555555555556,
                                            ["action"] = "Off Road",
                                            ["task"] = 
                                            {
                                                ["id"] = "ComboTask",
                                                ["params"] = 
                                                {
                                                    ["tasks"] = 
                                                    {
                                                        [1] = 
                                                        {
                                                            ["number"] = 1,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["enabled"] = true,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 0,
                                                                        ["name"] = 0,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [1]
                                                        [2] = 
                                                        {
                                                            ["enabled"] = true,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["number"] = 2,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 2,
                                                                        ["name"] = 9,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [2]
                                                    }, -- end of ["tasks"]
                                                }, -- end of ["params"]
                                            }, -- end of ["task"]
                                            ["speed_locked"] = true,
                                        }, -- end of [1]
                                    }, -- end of ["points"]
                                }, -- end of ["route"]
                                ["groupId"] = _idroot,
                                ["tasks"] = 
                                {
                                }, -- end of ["tasks"]
                                ["hidden"] = false,
                                ["units"] = 
                                {
                                    [1] = 
                                    {
                                        ["y"] = _tarpos.z + 8,
                                        ["type"] = _infantry,
                                        ["name"] = string.format("%s pilot", _groupname),
                                        ["unitId"] = _idroot + 1,
                                        ["heading"] = 3,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 4.6,
                                    }, -- end of [1]
                                }, -- end of ["units"]
                                ["y"] = _tarpos.z,
                                ["x"] = _tarpos.x,
                                ["name"] = _groupname,
                                ["start_time"] = 0,
                                ["task"] = "Ground Nothing",
                            })
					else
					coalition.addGroup(_country, Group.Category.GROUND, {
								["visible"] = false,
                                ["taskSelected"] = true,
                                ["route"] = 
                                {
                                    ["spans"] = 
                                    {
                                        [1] = 
                                        {
                                            [1] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [1]
                                            [2] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [2]
                                        }, -- end of [1]
                                    }, -- end of ["spans"]
                                    ["points"] = 
                                    {
                                        [1] = 
                                        {
                                            ["alt"] = 18,
                                            ["type"] = "Turning Point",
                                            ["ETA"] = 0,
                                            ["alt_type"] = "BARO",
                                            ["formation_template"] = "",
                                            ["y"] = _tarpos.z,
                                            ["x"] = _tarpos.x,
                                            ["ETA_locked"] = true,
                                            ["speed"] = 5.5555555555556,
                                            ["action"] = "Off Road",
                                            ["task"] = 
                                            {
                                                ["id"] = "ComboTask",
                                                ["params"] = 
                                                {
                                                    ["tasks"] = 
                                                    {
                                                        [1] = 
                                                        {
                                                            ["number"] = 1,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["enabled"] = true,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 0,
                                                                        ["name"] = 0,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [1]
                                                        [2] = 
                                                        {
                                                            ["enabled"] = true,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["number"] = 2,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 2,
                                                                        ["name"] = 9,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [2]
                                                    }, -- end of ["tasks"]
                                                }, -- end of ["params"]
                                            }, -- end of ["task"]
                                            ["speed_locked"] = true,
                                        }, -- end of [1]
                                    }, -- end of ["points"]
                                }, -- end of ["route"]
                                ["groupId"] = _idroot,
                                ["tasks"] = 
                                {
                                }, -- end of ["tasks"]
                                ["hidden"] = false,
                                ["units"] = 
                                {
                                    [1] = 
                                    {
                                        ["y"] = _tarpos.z + 8,
                                        ["type"] = _infantry,
                                        ["name"] = string.format("%s #1", _groupname),
                                        ["unitId"] = _idroot + 1,
                                        ["heading"] = 3,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 4.6,
                                    }, -- end of [1]
                                    [2] = 
                                    {
                                        ["y"] = _tarpos.z + 6.2,
                                        ["type"] = _infantry,
                                        ["name"] = string.format("%s #2", _groupname),
                                        ["unitId"] = _idroot + 2,
                                        ["heading"] = 2,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 6.2,
                                    }, -- end of [2]
                                    [3] = 
                                    {
                                        ["y"] = _tarpos.z + 4.6,
                                        ["type"] = _thirdinfantry,
                                        ["name"] = string.format("%s #3", _groupname),
                                        ["unitId"] = _idroot + 3,
                                        ["heading"] = 2,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 8,
                                    }, -- end of [3]
                                }, -- end of ["units"]
                                ["y"] = _tarpos.z,
                                ["x"] = _tarpos.x,
                                ["name"] = _groupname,
                                ["start_time"] = 0,
                                ["task"] = "Ground Nothing",
                            })
					end
					
					-- Immortal code for alexej21
					local _SetImmortal = { 
						id = 'SetImmortal', 
						params = { 
							value = true
						} 
					}
					local _controller = Group.getByName(_groupname):getController()
					if (medevac.immortalcrew) then Controller.setCommand(_controller, _SetImmortal) end
					
					local _leadername = string.format("%s #1", _groupname)
					if (_ispilot) then _leadername = string.format("%s pilot", _groupname) end
					local _leaderpos = Unit.getByName(_leadername):getPosition().p
					
					--local _unittable = mist.makeUnitTable({string.format("[g]%s",_groupname)})
					local _unittable = {_leadername}--string.format("[g]%s", _groupname)
					--assert(type(_unittable)=="table", "Error while generating unittable.")
					
					local _medevactext = "MEDEVAC REQUESTED!" 
					if (_ispilot) then _medevactext = "SAR REQUESTED!" end
					
					
					local _mgrs = coord.LLtoMGRS(_coord1, _coord2)
					local _coordinatestext = string.format("%s %s %s %s", _mgrs.UTMZone, _mgrs.MGRSDigraph, _mgrs.Easting, _mgrs.Northing)
					
					
					if (medevac.coordtype == 0) then -- Lat/Long DMTM
						_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 0}))
					end
					if (medevac.coordtype == 1) then -- Lat/Long DMS
						_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 1}))
					end
					if (medevac.coordtype == 2) then -- MGRS
						_coordinatestext = string.format("%s", mist.getMGRSString({units = _unittable, acc = 3}))
					end
					if (medevac.coordtype == 3) then -- Bullseye Imperial
						_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
					end
					if (medevac.coordtype == 4) then -- Bullseye Metric
						_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0, metric = 1}))
					end
					
					_medevactext = string.format("%s requests medevac at %s", _groupname, _coordinatestext)
					if (_ispilot) then _medevactext = string.format("%s requests SAR at %s", _groupname, _coordinatestext) end
					
					-- Loop through all the medevac units
					for nr,x in pairs(medevac.medevacunits) do
						local status, err = pcall(
							function (_args)
								x = _args[1]
								_woundcoal = _args[2]
								_medevactext = _args[3]
								_leaderpos = _args[4]
								_groupname = _args[5]
								_grp = _args[6]
								if (Unit.getByName(x) ~= nil and Unit.isActive(Unit.getByName(x))) then
									local _medevacgrp = Unit.getGroup(Unit.getByName(x))
									local _evacoal = Group.getCoalition(_medevacgrp)
						
						
									-- Check coalition side
									if (_evacoal == _woundcoal) then
										-- Display a delayed message
										timer.scheduleFunction(delayedhelpevent, {x, _medevactext, _groupname}, timer.getTime() + medevac.requestdelay) 
						
										-- Schedule timer to check when to pop smoke
										timer.scheduleFunction(SmokeEvent, {_leaderpos, x, _groupname, _grp}, timer.getTime() + 10) 
									end
								else
									env.warning(string.format("Medevac unit %s not active", x), false)
								end
								
							end
						, {x, _woundcoal, _medevactext, _leaderpos, _groupname, _grp})
	
						if (not status) then env.warning(string.format("Error while checking with medevac-units:\n\n%s",err), false) end
					end
					
				end
			end
		end
	, vnt)
	if (not status) then env.error(string.format("Error while handling event\n\n%s",err), medevac.displayerrordialog) end
end

-- Displays a request for medivac
function delayedhelpevent(_args, _time)
	local status, err = pcall(
		function (_args)	
			local _medleadname = _args[1]
			local _medevactext = _args[2]
			local _survivorgroup = _args[3]
			if getGroupHealthPercentage(Group.getByName(_survivorgroup)) > 0.1 then
				
				local _medevacid = Group.getID(Unit.getGroup(Unit.getByName(_medleadname)))
				
				medevac.DisplayMessage(_medevactext, _medleadname, _survivorgroup, 300) 
				-- local msg = {}
				-- msg.text = _medevactext
				-- msg.displayTime = 300
				-- msg.msgFor = {units = {_medleadname}}
				--msg.msgFor = {units = {Object.getName(Group.getUnits(Group.getByName(_medgrname))[1])}}
				--msg.msgFor = {coa = {'all'}}
				-- mist.message.add(msg)
				--trigger.action.outTextForGroup(_medevacid, _medleadname, 120)
			end
		end
	, _args)
	
	if (not status) then env.error(string.format("Error while handling message\n\n%s",err), medevac.displayerrordialog) end
	return nil
end

medevac.textdisplaymode = 1 -- Always use non-MiST-system

-- Displays messages to the pilot
function medevac.DisplayMessage(_message, _unit, _nameofmessage, _t)
	local status, err = pcall(
	function (_message, _unit, _nameofmessage, _t)	
	if (medevac.textdisplaymode == 0) then
		-- Display stacked messages using MiST
		local msg = {}
		msg.text = _message
		msg.displayTime = 300
		if (_t ~= nil) then
			msg.displayTime = _t
		end
		msg.msgFor = {units = {_unit}}
		msg.name = _nameofmessage
		mist.message.add(msg)
	end 
	if (medevac.textdisplaymode == 1) then
		-- Display single messages using regular method
		local _medevacid = Group.getID(Unit.getGroup(Unit.getByName(_unit)))
		local _msgtime = _t
		if (_t == nil) then
			_msgtime = 120
		end
		trigger.action.outTextForGroup(_medevacid, _message, _msgtime)
	end
	end
	, _message, _unit, _nameofmessage, _t)
	if (not status) then env.error(string.format("Error while displaying message\n\n%s",err), medevac.displayerrordialog) end
	return nil
end

if (medevac.displaymapcoordhint) then 
	timer.scheduleFunction(
		function()
			local status, err = pcall(
			function ()	
			local msg = {}
			msg.text =  "Tip: To change the coordinate system of the F10-map, press Left Alt + Y"
			msg.displayTime = 10
			
			msg.msgFor = {units = medevac.medevacunits}
			
			mist.message.add(msg)
			end
			, nil)
			if (not status) then env.error(string.format("Error while displaying coord-hint\n\n%s",err), medevac.displayerrordialog) end
			return nil
		end
	, nil, timer.getTime() + 10) 
end

world.addEventHandler(medevac.eventhandler)
env.info("Medevac event handler added", false)

-- Adds menuitem to all medevac units that are active
function AddMenuItem()
	local msg = {}

	-- Loop through all Medevac units
	msg.text =  "MEDEVAC-SCRIPT RUNNING FOR:\n"
	local _unitsmissing = false
	for nr,x in pairs(medevac.medevacunits) do 
		local asterix = " "
		if (Unit.getByName(x) == nil) then 
			-- Unit not active
			asterix = "* " 
			_unitmissing = true
			medevac.menupaths[nr] = x
			
		else
			-- Unit active
			
			if (medevac.menupaths[nr] ~= x) then missionCommands.removeItemForGroup(Group.getID(Unit.getByName(x):getGroup()), medevac.menupaths[nr]) end
			medevac.menupaths[nr] = missionCommands.addCommandForGroup(
				Group.getID(Unit.getByName(x):getGroup()),
				"Active MEDEVAC/SAR",
				nil,
				medevac.displayactive, 
				x)
			
		end
		
		msg.text = string.format("%s%s%s", msg.text, x, asterix)
	end
	if (_unitmissing) then msg.text = string.format("%s\n* = Missing unit", msg.text) end
	msg.displayTime = 2
				
	msg.msgFor = {coa = {'all'}}

	-- DEBUG message		
	if (medevac.displaymedunitslist) then
		mist.message.add(msg)
	end
	return 5
end

-- Schedule timer to add radio item
timer.scheduleFunction(AddMenuItem, {}, timer.getTime() + 5) 