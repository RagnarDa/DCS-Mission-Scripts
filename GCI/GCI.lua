-- GCI-script by RagnarDa 2013/2014

-- Instructions:

-- 1. Open your mission in the Mission Editor

-- 2. Click "Set rules for trigger" in the left pane

-- 3. Click the leftmost New for a new trigger.

-- 4. Click the middle New and change it to Time more, and set it to 2 sec

-- 5. Click the rightmost New and change it to Do script file and click open and select Mistv3_x.lua

-- 6. Repeat 4-6 but set time to 4 sec and select GCIx.lua instead.

-- 7. Close the window

-- 8. Add atleast one unit that you want to use as radar. Make sure the first unit in the group is the search radar.

-- 9. Name the radar-group something with the word "EWR" in it, ie. "Red Northern EWR"

-- 10. You can optionally add configurations to the name like this:
--	   NOTE! There have to be a space before AND after the letters.
-- 	   	- Detection range: default 120000m, like EWR 1L13 and 55G6 (and possibly AWACS?)
--			" x " = 30000m (Roland)
--			" y " = 80000m (Sborka)
--     		" z " = 90000m (HAWK)
--			" xx " = 160000 (Patriot)
--			" v " = 5000m (Visual, no ground filtering, 2m height offset)
--		- Height offset (the height of the radar dish) default 5m (AWACS, EWR 1L13)
--			" q " = 12m (EWR 55G6, Patriot...)
--			" s " = 20m (ships)
--		Examples:
--			"Patriot-site EWR xx q "
--			"Carrier EWR xx s "
--			"Front-line commander EWR v "

-- 11. If you want to use dynamically spawned AI interceptors:
--		a) Add a group and configure its loadout.
--		b) Check the "LATE ACTIVATION" checkbox.
--		c) Rename the group to something including the word "IPrototype", ie "F-4 Batumi IPrototype"
--		d) Optionally configure the intercept profile using these settings:
--		   NOTE! There have to be a space before AND after the letters.
--			- Speed setting: default 370m/s (M1.1)
--				" z " = 262m/s (M0.77)
--				" x " = 680m/s (M2.0)
--				" y " = 880m/s (M2.6)
--			- Altitude setting: default 6000m (USAF medium altitude)
--				" n " = Nap-of-the-earth (very low, 100m radar altitude)
--				" ll " = Low-low (1000m)
--				" hl " = High-low (2000m)
--				" lm " = Low-medium (4000m)
--				" hm " = High-medium (8000m)
--				" lh " = Low-high (10000m)
--				" hh " = High-high (15000m)
--			- Search radar setting enroute to intercept setting: default OFF
--				" q " = Use search radar enroute to intercept.
--			- Attack radar setting: default ON
--				" s " = Don't use radar while attacking (silent attack)
--			- Engagement range setting: default 35000m (for AIM-7, R-27 equipped fighters)
--				" wvrb " = 2000m WVR bad visibility.
--				" wvrg " = 5000m WVR good visibility.
--				" bvrs " = 12000m Very short-range BVR (ie R-13 or AIM-9 equipped fighters, like MiG-21)
--				" bvre " = 20000m Early radar guided (ie R-24 equipped fighter, like MiG-23)
--				" bvra " = 50000m Active medium range radar guided (ie AIM-120, R-77)
--				" bvrl " = 90000m Active long range radar guided (ie AIM-54, R-33)
--			- Combat radius setting: default 250km, ie from Vaziani to Kobuleti.
--				" sscr " = 50km Short-range, ie base-defence only
--				" mscr " = 150km Medium short-range, ie from Sukhumi to Kobuleti
--				" mlcr " = 500km Medium long-range, ie from Novorossiysk to Nalchik
--				" vlcr " = 1000km Entire map
--			- Examples:
--				"MiG-23 IPrototype Low-High-Low z n bvre "
--				"P-51 IPrototype z wvrg sscr "
--				"F-14 IPrototype x lh q bvrl mlcr "

-- 11. If you want to include player-controlled interceptors:
--		a) Add a group and configure its loadout.
--		b) Make sure you select skill-setting "Client" or "Player".
--		c) Rename the group to something including the word "Interceptor", ie "Player #1 Interceptor"
--		d) Optionally configure the intercept profile using the settings for dynamically spawned interceptors above.

-- 12. If you want to include divertable aircrafts:
--		a) Add a group and configure it.
--		b) Make sure the last waypoint is landing at a friendly airbase.
--		c) On the first waypoint, click ADVANCED (WAYPOINT ACTIONS)
--		d) Click in the lower right corner of the screen.
--		e) Select TYPE=Set Option and ACTION=ROE.
--		f) Click OPEN FIRE and select WEAPON HOLD. 
--		g) Optionally set it to Invisible so the AI wont engage it.
--		h) Rename the group to something including the word "Divertable", ie "Incoming Bomber Divertable"








if (gci == nil) then gci = {} end
if (gci.blueinterceptorsquadrons == nil) then gci.blueinterceptorsquadrons = {} end
if (gci.redinterceptorsquadrons == nil) then gci.redinterceptorsquadrons = {} end
if (gci.blueewrs == nil) then gci.blueewrs = {} end
if (gci.redewrs == nil) then gci.redewrs = {} end
if (gci.verbose == nil) then gci.verbose = 1 end

-- Initialize all global variables
gci.allairunits = {}
gci.blueairunits = {}
gci.redairunits = {}
gci.allairunitscount = 0
gci.blueairunitscount = 0
gci.redairunitscount = 0
gci.interceptedgroups = {}
gci.busyinterceptors = {}
gci.interceptionpoints = {}
gci.interceptorfinished = {}
gci.targetassignments = {}
gci.attackinginterceptors = {}
gci.assignedinterceptors = {}
gci.GpId = 17000
gci.UnitId = 17000
gci.DynAddIndex = 1
gci.addToDBs = {} 
gci.divertables = {}

-- Iterate through all alive units and find all the "Air"-category units.
local _alive = mist.DBs.aliveUnits
local _unit
for _,v in pairs(_alive) do
	local _unit = v.unit
	if Unit.hasAttribute(_unit, "Air") then
		table.insert(gci.allairunits, _unit)
		gci.allairunitscount = gci.allairunitscount + 1
		if (Unit.getCoalition(_unit) == coalition.side.BLUE) then
			table.insert(gci.blueairunits, Unit.getName(_unit))
			gci.blueairunitscount = gci.blueairunitscount + 1
		else
			if (Unit.getCoalition(_unit) == coalition.side.RED) then
				table.insert(gci.redairunits, Unit.getName(_unit))
				gci.redairunitscount = gci.redairunitscount + 1
			end
		end
	end
end

function tablelength(T)
  local count = 0
  if T == nil then return 0 end
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

function dotprodV3(a, b)
	local ret = 0
	ret = ret + a.x * b.x
	ret = ret + a.y * b.y
	ret = ret + a.z * b.z
	return ret
end

function normV3(v)
	return math.sqrt(
		math.pow(v.x, 2) +
		math.pow(v.y, 2) +
		math.pow(v.z, 2)
	)
end

-- Returns all living units in a group, and if it fails, it returns a empty array
function getAliveUnits(grp)
	local sts, rtrn = pcall(
		function (_grp)
			local units = Group.getUnits(grp)
			local _alive = {}
			for nr,x in pairs(units) do
				if (Unit.getLife(x) > 1.0) then table.insert(_alive,x) end
			end
			return _alive
		end
	, grp)
	if (sts) then 
		return rtrn 
	else 
		env.warning("getAliveUnits() failed! Returning empty array.", false)
		return {} 
	end
end
-- Unittest getAliveUnits
assert(tablelength(getAliveUnits(Unit.getGroup(gci.allairunits[1])))>0, "Unittest of getAliveUnits/tablelength failed!")


function getClosingVelocity(pos, vvector)
	return dotprodV3(vvector, pos)/normV3(pos)
end

function radargroundclutterfilter(radar, target)
	local _radarunit = Unit.getByName(radar.name)
	local _radarpos = _radarunit:getPosition().p
	local _filteragl = radar.filteragl
	local _filterclvl = radar.filterclosingvelocity
	local _tarpos = target:getPosition().p
	local _relpos = mist.vec.sub(_radarpos, _tarpos)
	local _tarvel = target:getVelocity()
	local _closingvel = getClosingVelocity(_relpos, _tarvel)
	if (gci.verbose > 1) then trigger.action.outText(string.format("Unit %s closing %s @ %f m/s, dp1: %f, dp2: %f, norm: %f speed: %f", Unit.getName(target), Unit.getName(_radarunit), _closingvel, dotprodV3(_tarvel,_relpos), mist.vec.dp(_tarvel,_relpos), normV3(_relpos), string.format('%12.2f', mist.vec.mag(_tarvel))), 20) end
	local _targetagl = _tarpos.y - land.getHeight({x = _tarpos.x, y = _tarpos.z})
	if (_targetagl <= _filteragl and math.abs(_closingvel) <= _filterclvl) then
		-- target is filtered out
		return true
	end
	return false
end

-- Function to measure distance between one point and another
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


-- Radarsweep looks for targets to intercept
function gci.radarsweep()
	local status, err = pcall(gci.doradarsweep)
	if (status) then
		-- Succesful sweep
	else
		env.error(string.format("Error while doing radarsweep!\n\n%s", err), true)
	end
end

-- Ok, this code is stolen from MiST :/
-- The reason is I wanted it exactly as it was, only I needed to be able to specify the name of cloned groups
-- which the original function didn't let me do.
-- So, sorry Grimes and Speed.
-- /RagnarDa
gci.dynAdd = function(newGroup) -- same as coalition.add function in SSE. checks the passed data to see if its valid. 
--Will generate groupId, groupName, unitId, and unitName if needed
--
	
	
	--env.info('dynAdd')
	local cntry = newGroup.country
	local groupType = newGroup.category
	local newCountry = ''
	
	-- validate data
	for countryName, countryId in pairs(country.id) do
		if type(cntry) == 'string' then
			if tostring(countryName) == string.upper(cntry) then
				newCountry = countryName
			end
		elseif type(cntry) == 'number' then
			if countryId == cntry then
				newCountry = countryName
			end
		end
	end
	
	if newCountry == '' then
		return false
	end
	
	local newCat = ''
	for catName, catId in pairs(Unit.Category) do
		if type(groupType) == 'string' then
			if tostring(catName) == string.upper(groupType) then
				newCat = catName
			end
		elseif type(groupType) == 'number' then
			if catId == groupType then
				newCat = catName
			end
		end
		
		if catName == 'GROUND_UNIT' and (string.upper(groupType) == 'VEHICLE' or string.upper(groupType) == 'GROUND') then
			newCat = 'GROUND_UNIT'
		elseif catName == 'AIRPLANE' and string.upper(groupType) == 'PLANE' then
			newCat = 'AIRPLANE'
		end
	end
	
	local typeName 
	if newCat == 'GROUND_UNIT' then
		typeName = ' gnd '
	elseif newCat == 'AIRPLANE' then
		typeName = ' air '
	elseif newCat == 'HELICOPTER' then
		typeName = ' hel '
	elseif newCat == 'SHIP' then
		typeName = ' shp '
	elseif newCat == 'BUILDING' then
		typeName = ' bld '
	end
	
	if newGroup.clone or not newGroup.groupId then
		gci.DynAddIndex = gci.DynAddIndex + 1
		gci.GpId = gci.GpId + 1 
		newGroup.groupId = gci.GpId
	end
	if newGroup.groupName or newGroup.name then
		if newGroup.groupName then
			newGroup['name'] = newGroup.groupName
		elseif newGroup.name then
			newGroup['name'] = newGroup.name
		end
	end
	
	-- This is the part that I needed to change. Originally "if newGroup.clone or not newGroup.name then"
	-- /RagnarDa
	if not newGroup.name then
		newGroup['name'] = tostring(tostring(cntry) .. tostring(typeName) .. gci.DynAddIndex)
	end
	
	for unitIndex, unitData in pairs(newGroup.units) do

		local originalName = newGroup.units[unitIndex].unitName or newGroup.units[unitIndex].name
		if newGroup.clone or not unitData.unitId then
			gci.UnitId = gci.UnitId + 1	
			newGroup.units[unitIndex]['unitId'] = gci.UnitId
		end
		if newGroup.units[unitIndex].unitName or newGroup.units[unitIndex].name then
			if newGroup.units[unitIndex].unitName then
				newGroup.units[unitIndex].name = newGroup.units[unitIndex].unitName
			elseif newGroup.units[unitIndex].name then
				newGroup.units[unitIndex].name = newGroup.units[unitIndex].name
			end
		end
		

		if newGroup.clone or not unitData.name then
			newGroup.units[unitIndex].name = tostring(newGroup.name .. ' unit' .. unitIndex)
		end
		
		if not unitData.skill then 
			newGroup.units[unitIndex].skill = 'Random'
		end
		
		if not unitData.alt then
			if newCat == 'AIRPLANE' then
				newGroup.units[unitIndex].alt = 2000
				newGroup.units[unitIndex].alt_type = 'RADIO'
				newGroup.units[unitIndex].speed = 150
			elseif newCat == 'HELICOPTER' then
				newGroup.units[unitIndex].alt = 500
				newGroup.units[unitIndex].alt_type = 'RADIO'
				newGroup.units[unitIndex].speed = 60
			else
				--[[env.info('check height')
				newGroup.units[unitIndex].alt = land.getHeight({x = newGroup.units[unitIndex].x, y = newGroup.units[unitIndex].y})
				newGroup.units[unitIndex].alt_type = 'BARO']]
			end
		

		end
				
		if newCat == 'AIRPLANE' or newCat == 'HELICOPTER' then
			if (newGroup.units[unitIndex].alt_type ~= 'RADIO' or newGroup.units[unitIndex].alt_type ~= 'BARO') or not newGroup.units[unitIndex].alt_type then
				newGroup.units[unitIndex].alt_type = 'RADIO'
			end
			if not unitData.speed then
				if newCat == 'AIRPLANE' then
					newGroup.units[unitIndex].speed = 150
				elseif newCat == 'HELICOPTER' then
					newGroup.units[unitIndex].speed = 60
				end
			end
			if not unitData.payload then
				newGroup.units[unitIndex].payload = mist.getPayload(originalName)
			end
		end
		
	end
	if newGroup.route and not newGroup.route.points then
		if not newGroup.route.points and newGroup.route[1] then
			local copyRoute = newGroup.route
			newGroup.route = {}
			newGroup.route.points = copyRoute
		end
	end
	newGroup.country = newCountry
	
	gci.addToDBs[#gci.addToDBs + 1] = mist.utils.deepCopy(newGroup)
	
	
	-- sanitize table
	newGroup.groupName = nil
	newGroup.clone = nil
	newGroup.category = nil
	newGroup.country = nil
	
	newGroup.tasks = {}
	newGroup.visible = false
	
	for unitIndex, unitData in pairs(newGroup.units) do
		newGroup.units[unitIndex].unitName = nil
	end
	
	--env.info('added')
	coalition.addGroup(country.id[newCountry], Unit.Category[newCat], newGroup)
	
	
	return newGroup.name
	
	end

-- Plans a new interception
function gci.planintercept(trackedunit, _squadrons)
	if (gci.verbose > 0) then env.info("Sanity-checking") end
	assert(type(_squadrons)=="table", "Sanity-check: squadron is not a table.")
	--assert(tablelength(_squadrons) > 0, "Trying to do a interception mission, but there are no squadrons.")
	if (tablelength(_squadrons) < 1) then 
		env.warning("There are no squadrons available, aborting.", false)
		return
	end
	--assert(tablelength(getAliveUnits(Unit.getGroup(trackedunit)))>0, "Sanity check. Group is not alive?")

	if (gci.verbose > 0) then env.info(string.format("Plan new intercept for target %s", Unit.getName(trackedunit), false)) end
	table.insert(gci.interceptedgroups, Unit.getGroup(trackedunit))
	local _sortedflights = gci.sortinterceptorflights(_squadrons, trackedunit, gci.assignedinterceptors)
	if (tablelength(_sortedflights)>0) then
		local _iflight = _sortedflights[1]
		assert(tablelength(_sortedflights) > 0, "Flight sorting seems to have failed.")
		local status, err = pcall(gci.dointercept,trackedunit, _iflight)
		if (status) then
			if (tablelength(getAliveUnits(Group.getByName(_iflight[2]))) > 0) then
				-- Succesfully planned intercept, put in assignment-list
				env.info(string.format("Succesfully planned intercept of %s by %s", Unit.getName(trackedunit) ,_iflight[2]), false)
				table.insert(gci.assignedinterceptors, _iflight[2])
				table.insert(gci.targetassignments, {iflight = string.format("%s",_iflight[2]), squadron = _iflight[4], assignedtarget = Unit.getGroup(trackedunit), startingpos = getAliveUnits(Group.getByName(_iflight[2]))[1]:getPosition().p})
			else
				env.info("Intecept plan failed, possibly failed spawning flight.",false)
			end
			
		else
			env.error(string.format("Error while doing intercept!\n\n%s", err), true)
		end
	end
end

-- Reroute a active intercept
function gci.rerouteintercept(trackedunit, intrcptr)
	local sts, erro = pcall(
		function (trackedunit, intrcptr)
			if (gci.verbose > 0) then env.info("Rerouteintercept().", false) end
			local _grp = Group.getByName(intrcptr.iflight)
			if (tablelength(getAliveUnits(_grp))<1) then return end
			if (gci.verbose > 0) then env.info(string.format("Group: %s", Group.getName(_grp))) end
			local _airborne = false
			local _checked = false
			local _nrairborne = 0
			local _nrairborne = 0
			for kl,individ in pairs(getAliveUnits(_grp)) do
				if (Unit.inAir(individ)) then _nrairborne = _nrairborne + 1 end
				_checked = true
			end
			local _distancetotarget = measuredistance(getAliveUnits(_grp)[1]:getPosition().p, trackedunit:getPosition().p)
			if (gci.verbose > 0) then env.info(string.format("Distance: %f Engagmentrange: %f", _distancetotarget, intrcptr.squadron.engagementrange), false) end
			if ((_nrairborne == tablelength(getAliveUnits(_grp))) and _checked and (_distancetotarget > intrcptr.squadron.engagementrange)) then
				local status, err = pcall(gci.dointercept,trackedunit, {0, intrcptr.iflight, 9999999999, intrcptr.squadron, intrcptr.startingpos})
				if (not status) then
					env.error(string.format("Error while re-routing intercept!\n\n%s", err), true)
				end
			end
		end
	, trackedunit, intrcptr)
	if (not sts) then
		env.error(string.format("Error while re-routing intercept!\n\n%s", err), true)
	end
end


function gci.doradarsweep()

	
	gci.scanning = true
	gci.trackedbyred = {}
	gci.trackedbyredS = ""
	gci.trackedbyblue = {}
	gci.trackedbyblueS = ""
	assert(type(gci.redewrs)=="table", "gci.redewrs corrupted, not a table!")
	assert(type(gci.blueewrs)=="table", "gci.blueewrs corrupted, not a table!")
	gci.assignedinterceptors = {}
	-- Check each red radar
	for _,o in pairs(gci.redewrs) do	
		
		assert(type(o)=="table", "Not a table!")
		if (Unit.getByName(o.name) ~= nil) then 
		local _ewrunit = Unit.getByName(o.name)
		if (Unit.getLife(_ewrunit) > 1.0) then 
			-- radar OK, check targets
			local _los = mist.getUnitsLOS({Unit.getName(_ewrunit)}, o.altoffset, mist.makeUnitTable({"[blue]"}), 0, o.radius)
			assert(type(_los)=="table", "mist.getUnitsLOS failed!")
			if (tablelength(_los)>0) then
				assert(type(_los[1].vis)=="table", "No visible targets")
				for q,x in pairs(_los[1].vis) do
					if (not radargroundclutterfilter(o, x)) then
						-- unit is not filtered out as ground-clutter
						table.insert(gci.trackedbyred, x)
						gci.trackedbyredS = string.format("%s %s", gci.trackedbyredS, Unit.getName(x))
					end
				end
				if (gci.verbose > 1) then trigger.action.outText(string.format("Units tracked by RED: %s\n\n\nUnits tracked by BLUE: %s", gci.trackedbyredS, gci.trackedbyblueS), 10) end
				for w,trackedunit in pairs(gci.trackedbyred) do
					if (tablecontains(gci.interceptedgroups, Unit.getGroup(trackedunit))) then
						-- Unit already intercepted, reroute assigned interceptors
						for h,intrcptr in pairs(gci.targetassignments) do
							-- Loop through all interceptorgroups targetassignments to find a match
							if (intrcptr.assignedtarget == Unit.getGroup(trackedunit) and not tablecontains(gci.attackinginterceptors, intrcptr.iflight)) then
								-- Found a match, reroute interceptor if everyone is in the air
								
								--local status, err = pcall(function (_iflight) return getAliveUnits(_iflight) end, intrcptr.iflight)
								if (gci.verbose > 0) then env.info(string.format("reassigning group #%f", h), false) end
								if (intrcptr.iflight == nil) then
									env.warning(string.format("Can't get units in group # %f", h), false)
								end
									if (getGroupHealthPercentage(Group.getByName(intrcptr.iflight)) < 55) then
										if (getGroupHealthPercentage(Group.getByName(intrcptr.iflight)) > 1) then
											if (gci.verbose > 0) then env.info(string.format("Unit health too low. Interceptor group health: %d, fuel: %f, ammo: %d sending new", getGroupHealthPercentage(Group.getByName(intrcptr.iflight)), Unit.getFuel(getAliveUnits(Group.getByName(intrcptr.iflight))[1]), tablelength(Unit.getAmmo(getAliveUnits(Group.getByName(intrcptr.iflight))[1]))), false) end
										else
											if (gci.verbose > 0) then env.info("Group dead",false) end
										end
										removeintable(gci.targetassignments, intrcptr)
										removeintable(gci.interceptedgroups, Unit.getGroup(trackedunit))
										gci.planintercept(trackedunit, gci.redinterceptorsquadrons)
									else
										if (intrcptr.iflight ~= nil and getAliveUnits(Group.getByName(intrcptr.iflight))[1] ~= nil) then
											if (Unit.getFuel(getAliveUnits(Group.getByName(intrcptr.iflight))[1]) < 0.3 or tablelength(Unit.getAmmo(getAliveUnits(Group.getByName(intrcptr.iflight))[1])) < 1) then
												if (gci.verbose > 0) then env.info(string.format("Fuel/Ammo too low. Interceptor group health: %d, fuel: %f, ammo: %d sending new", getGroupHealthPercentage(Group.getByName(intrcptr.iflight)), Unit.getFuel(getAliveUnits(Group.getByName(intrcptr.iflight))[1]), tablelength(Unit.getAmmo(getAliveUnits(Group.getByName(intrcptr.iflight))[1]))), false) end
												removeintable(gci.targetassignments, intrcptr)
												removeintable(gci.interceptedgroups, Unit.getGroup(trackedunit))
												gci.planintercept(trackedunit, gci.blueinterceptorsquadrons)
											else
												if (gci.verbose > 0) then env.info("Clear to reroute.", false) end
												gci.rerouteintercept(trackedunit, intrcptr)
											end
										end
									end
								
							end
						end
					else
						gci.planintercept(trackedunit, gci.redinterceptorsquadrons)
					end
				end
			end
		end
		end
	end
	
	-- check each blue radar
	for _,o in pairs(gci.blueewrs) do	
		assert(type(o)=="table", "Not a table!")
		if (Unit.getByName(o.name) ~= nil) then 
		local _ewrunit = Unit.getByName(o.name)
		if (Unit.getLife(_ewrunit) > 1.0) then 
			-- radar OK, check targets
			local _los = mist.getUnitsLOS({Unit.getName(_ewrunit)}, o.altoffset, mist.makeUnitTable({"[red]"}), 0, o.radius)
			assert(type(_los)=="table", "mist.getUnitsLOS failed!")
			if (tablelength(_los)>0) then
				assert(type(_los[1].vis)=="table", "No visible targets")
				for q,x in pairs(_los[1].vis) do	
					if (not radargroundclutterfilter(o, x)) then
						-- unit is not filtered out as ground-clutter
						table.insert(gci.trackedbyblue, x)
						gci.trackedbyblueS = string.format("%s %s", gci.trackedbyblueS, Unit.getName(x))
					end
				end
				if (gci.verbose > 1) then trigger.action.outText(string.format("Units tracked by RED: %s\n\n\nUnits tracked by BLUE: %s", gci.trackedbyredS, gci.trackedbyblueS), 10) end
				for w,trackedunit in pairs(gci.trackedbyblue) do
					if (tablecontains(gci.interceptedgroups, Unit.getGroup(trackedunit))) then
						-- Unit already intercepted, reroute assigned interceptors
						for h,intrcptr in pairs(gci.targetassignments) do
							-- Loop through all interceptorgroups targetassignments to find a match
							if (intrcptr.assignedtarget == Unit.getGroup(trackedunit) and not tablecontains(gci.attackinginterceptors, intrcptr.iflight)) then
								-- Found a match, reroute interceptor if everyone is in the air
								
								--local status, err = pcall(function (_iflight) return getAliveUnits(_iflight) end, intrcptr.iflight)
								if (gci.verbose > 0) then env.info(string.format("reassigning group #%f", h), false) end
								if (intrcptr.iflight == nil) then
									env.warning(string.format("Can't get units in group # %f", h), false)
								end
								if (getGroupHealthPercentage(Group.getByName(intrcptr.iflight)) < 55) then
										if (getGroupHealthPercentage(Group.getByName(intrcptr.iflight)) > 1) then
											if (gci.verbose > 0) then env.info(string.format("Unit health too low. Interceptor group health: %d, fuel: %f, ammo: %d sending new", getGroupHealthPercentage(Group.getByName(intrcptr.iflight)), Unit.getFuel(getAliveUnits(Group.getByName(intrcptr.iflight))[1]), tablelength(Unit.getAmmo(getAliveUnits(Group.getByName(intrcptr.iflight))[1]))), false) end
										else
											if (gci.verbose > 0) then env.info("Group dead",false) end
										end
									removeintable(gci.targetassignments, intrcptr)
									removeintable(gci.interceptedgroups, Unit.getGroup(trackedunit))
									gci.planintercept(trackedunit, gci.blueinterceptorsquadrons)
								else
								if (intrcptr.iflight ~= nil and getAliveUnits(Group.getByName(intrcptr.iflight))[1] ~= nil) then
									if (Unit.getFuel(getAliveUnits(Group.getByName(intrcptr.iflight))[1]) < 0.3 or tablelength(Unit.getAmmo(getAliveUnits(Group.getByName(intrcptr.iflight))[1])) < 1) then
										if (gci.verbose > 0) then env.info(string.format("Interceptor group fuel: %f, ammo: %d sending new", getGroupHealthPercentage(Group.getByName(intrcptr.iflight)), Unit.getFuel(getAliveUnits(Group.getByName(intrcptr.iflight))[1]), tablelength(Unit.getAmmo(getAliveUnits(Group.getByName(intrcptr.iflight))[1]))), false) end
									
										removeintable(gci.targetassignments, intrcptr)
										removeintable(gci.interceptedgroups, Unit.getGroup(trackedunit))
										gci.planintercept(trackedunit, gci.blueinterceptorsquadrons)
									else
										if (gci.verbose > 0) then env.info("Clear to reroute.", false) end
										gci.rerouteintercept(trackedunit, intrcptr)
									end
									end
								end
							end
						end
					else
						gci.planintercept(trackedunit, gci.blueinterceptorsquadrons)
					end
				end
			end
		end
		end
	end
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
			if (percentage ~= 100 and (gci.verbose > 0)) then env.info(string.format("%s group health: %d", Group.getName(grp), percentage), false) end
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
-- Unittest getGroupHelthPercentage
assert(getGroupHealthPercentage(Unit.getGroup(gci.allairunits[1]))==100, "Unittest of getGroupHealthPercentage/tablelength failed!")


function gci.sortinterceptorflights(_squadrons, target, ignorelist)
	local sts, rtrn = pcall(
		function (_squadrons, target, ignorelist)
			local _sortedlist
			local _flights = {}
			if (gci.verbose > 0) then env.info(string.format("Busy flights: %s", mist.utils.tableShow(gci.busyinterceptors)), false) end
			for p,squad in pairs(_squadrons) do
				if (gci.verbose > 0) then env.info(string.format("Looking at squadron #%d",p), false) end
				local _distancetotarget = 0
				local _interceptorspeed = squad.interceptspeed
				local _interceptorcombradius = squad.combatradius
				local _velv = target:getVelocity()
				-- assert(type(squad.flights)=="table", string.format("Squadron %d doesnt have any flights!", p))
				for u,flight in pairs(squad.flights) do
					if (gci.verbose > 0) then env.info(string.format("Looking at flight #%d %s %s",u, flight[2], flight[1]), false) end
					local _isactive = false
					local _interceptorgroup
					if (string.find(string.lower(flight[2]), "iprototype")) then 
						-- Its a dynamically spawn group
						if (tablelength(getAliveUnits(Group.getByName(flight[1])))<1) then
							-- It hasn't been spawned in yet, therefore use prototype group
							_interceptorgroup = Group.getByName(flight[2])
						else
							-- It has been spawned in, so use the clone
							_interceptorgroup = Group.getByName(flight[1])
							_isactive = true
						end
					else
						-- Its not a dynamically spawn group, use it as normal
						_interceptorgroup = Group.getByName(flight[1])
						_isactive = trigger.misc.getUserFlag(flight[2])
					end
					if (_isactive ~= true and tablecontains(gci.busyinterceptors, _interceptorgroup) == false and not tablecontains(ignorelist, _interceptorgroup)) then
						-- Unit has not been activated yet
						if (gci.verbose > 0) then env.info(string.format("Flight %d-%d is available (%s)",p,u, flight[1]), false) end
						local _flightgroup = _interceptorgroup
						
						if (gci.verbose > 0) then env.info(string.format("Flight %d-%d is a group",p,u), false) end
						if (getGroupHealthPercentage(_flightgroup)>90) then
							-- Group is mostly OK
					
							local _flightlead = getAliveUnits(_flightgroup)[1]--getAliveUnits(_flightgroup)[1]
							
							if (gci.verbose > 0) then env.info(string.format("Flight %d-%d has a lead",p,u), false) end
							local _thisdistance = measuredistance(_flightlead:getPosition().p,target:getPosition().p)

							local _ipoint = gci.calculteInterceptionPoint(target:getPosition().p, _velv, _flightlead:getPosition().p, _interceptorspeed, 100)
							if (_ipoint ~= nil) then
								local _distancetointercept = measuredistance(_flightlead:getPosition().p,{x = _ipoint.x, z = _ipoint.y})
								local _distancefromintecepttotarget = measuredistance(target:getPosition().p,{x = _ipoint.x, z = _ipoint.y})
							
								if _distancetotarget == 0 then 
									-- set distance for all fligths in squadron
									_distancetotarget = measuredistance(_flightlead:getPosition().p,target:getPosition().p)
								else
									if ((_thisdistance > _distancetotarget + 5000) or (_thisdistance < _distancetotarget - 5000)) then _distancetotarget = _thisdistance end
								end
								if (gci.verbose > 0) then env.info(string.format("Inserting flight #%d - distance: %d",u, _distancetotarget), false) end
								if (_distancetointercept < _interceptorcombradius) then
									-- Within range to intercept
									if (_distancetointercept < _distancetotarget) then _distancetotarget = _distancetointercept end
									if (_distancefromintecepttotarget < _distancetotarget) then _distancetotarget = _distancefromintecepttotarget end
								
									table.insert(_flights, {_distancetotarget, flight[1], flight[2], squad})
								end
							end
						end
					end
				end
			end


	
	if (type(_flights)=="table") then
		-- we have available flights, now lets sort them
		table.sort(_flights, 
			function(x,y)
				return x[1] < y[1] 
			end
		)
		--- [HACK] ^^^ this part is flawed, it puts the flights in the wrong order
		
		if (gci.verbose > 0) then env.info(mist.utils.tableShow(_flights), false) end
	end
	
	return _flights
	end
	,_squadrons, target, ignorelist)
	if (sts) then 
		return rtrn 
	else 
		env.error(string.format("sortinterceptorflights() failed! %s", rtrn), true)
		return 0
	end
end

function gci.calculteInterceptionPoint(targetPos, targetVelVec, interceptorPos, interceptorSpeed, timeOffset)
	local sts, rtrn = pcall(
		function (targetPos, targetVelVec, interceptorPos, interceptorSpeed, timeOffset)
	local ox = targetPos.x - interceptorPos.x
	local oy = targetPos.z - interceptorPos.z
	
	local h1 = targetVelVec.x * targetVelVec.x + targetVelVec.z * targetVelVec.z - interceptorSpeed * interceptorSpeed
	if (h1 == 0) then
		h1 = 0.001
	end
	
	local minusPHalf = 0 -(ox * targetVelVec.x + oy * targetVelVec.z) / h1
	
	local discriminant = minusPHalf * minusPHalf - (ox * ox + oy * oy) / h1
	if (discriminant < 0) then
		return nil
	end
	
	local root = math.sqrt(discriminant)
	
	local t1 = minusPHalf + root
	local t2 = minusPHalf - root
	
	local tMin = math.min(t1, t2)
	local tMax = math.max(t1, t2)
	
	local t
	if (tMin > 0) then
		t = tMin
	else
		t = tMax
	end
	
	if (t < 0) then
		return nil
	end
	
	t = t + timeOffset
	
	local interceptpoint = {x = targetPos.x + t * targetVelVec.x, y = targetPos.z + t * targetVelVec.z}
	return interceptpoint
		end
		,targetPos, targetVelVec, interceptorPos, interceptorSpeed, timeOffset)
		if (sts) then 
		return rtrn 
	else 
		env.error(string.format("sortinterceptorflights() failed! %s", rtrn), true)
		return 0
	end
end

-- Finds a point betweem two points according to a given blend (0.5 = right between, 0.3 = a third from point1)
function gci.getpointbetween(point1, point2, blend)
	return {
		x = point1.x + blend * (point2.x - point1.x),
		y = point1.y + blend * (point2.y - point1.y),
		z = point1.z + blend * (point2.z - point1.z)
	}
end

-- Handles all world events
gci.eventhandler = {}
function gci.eventhandler:onEvent(vnt)
	local status, err = pcall(
		function (vnt)
			-- if (gci.verbose) then env.info(mist.utils.tableShow(vnt),true) end
			gci.trace(vnt)
			assert(vnt ~= nil, "Event is nil!")
			if (vnt.id == 5 or vnt.id == 4) then
				-- Flight crashed or landed
				local grp = Unit.getGroup(vnt.initiator)
				if (gci.verbose > 0) then env.info(string.format("Group %s is dead/has landed", Group.getName(grp)), false) end
				if (tablecontains(gci.busyinterceptors, grp)) then 
					if (gci.verbose > 0) then env.info(string.format("Interceptorgroup %s is dead/has landed", Group.getName(grp)), false) end
					for h,intrcptr in pairs(gci.targetassignments) do
						-- Loop through all interceptorgroups targetassignments to find a match
						-- HACK!
						if (intrcptr.iflight == Group.getName(grp)) then
							-- Found a match, reroute interceptor if everyone is in the air
							if (gci.verbose) then env.info(string.format("Interceptorgroup %s is finished", Group.getName(grp)), false) end
							table.insert(gci.interceptorfinished, grp)
							removeintable(gci.interceptedgroups, intrcptr.assignedtarget)
							removeintable(gci.attackinginterceptors, Group.getName(grp))
							if (grp ~= nil) then
								if (vnt.id == 4 or tablelength(getAliveUnits(grp))<1) then
									-- Group empty, schedule deletion
									mist.scheduleFunction (function(grp)
										local stuss, erronrs = pcall(function (grp)
												Group.destroy(grp) -- Destroy group
											end
											,grp)
										if (not stuss) then env.error(string.format("Error while setting scheduled deletion!\n\n%s", erronrs), false) end
									end, {grp}, timer.getTime () + 120 )
								end
							end
						end
						-- ^^ Should commented out this section as it doubles functionality in RadarSweep() ???
					end
					
				end
			end
			if (vnt.id == 13 or vnt.id == 15) then
				env.info("BIRTH!")
				-- Unit borned
				local _groupName = Unit.getGroup(vnt.initiator):getName()
			if string.find(string.lower(_groupName), "interceptor") then -- Finds group with Interceptor in name
		env.info(string.format("Non-dynamic Interceptor-group %s found",_groupName), false)
		
		-- Get speed setting
		local _ispeed = 370 -- Default M1.1
		if string.find(string.lower(_groupName), " z ") then _ispeed = 262 end -- M0.77
		if string.find(string.lower(_groupName), " x ") then _ispeed = 680 end -- M2
		if string.find(string.lower(_groupName), " y ") then _ispeed = 880 end -- M2.6
		
		-- Get altitude setting
		-- medium altitude is between 3000m and 9000m (USAF standard)
		local _ialt = 6000 -- Default medium altitude (20000ft)
		local _ialttype = "BARO" -- Default medium altitude barometric height
		if string.find(string.lower(_groupName), " n ") then -- Nap-of-the-earth (very low)
			_ialt = 100
			_ialttype = "RADIO"
		end
		if string.find(string.lower(_groupName), " ll ") then -- Low-low
			_ialt = 1000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hl ") then -- High-low
			_ialt = 2000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " lm ") then -- Low-medium
			_ialt = 4000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hm ") then -- High-medium
			_ialt = 8000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " lh ") then -- Low-High
			_ialt = 10000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hh ") then -- High-High
			_ialt = 15000
			_ialttype = "BARO"
		end
		
		-- Get radar setting search radar (this will also enable engaging targets while enroute)
		local _searchradar = false -- Default false
		if string.find(string.lower(_groupName), " q ") then _searchradar = true end
		
		-- Get radar setting attack radar
		local _attackradar = true -- Default true
		if string.find(string.lower(_groupName), " s ") then _attackradar = false end
		
		-- Get engagement range setting
		local _engagementrange = 35000 -- Default attack-range (for AIM-7, R-27 equipped fighters)
		if string.find(string.lower(_groupName), " wvrb ") then _engagementrange = 2000 end -- WVR bad visibility
		if string.find(string.lower(_groupName), " wvrg ") then _engagementrange = 5000 end -- WVR good visibility
		if string.find(string.lower(_groupName), " bvrs ") then _engagementrange = 12000 end -- Very short-range BVR (ie R-13 or AIM-9 equipped, like MiG-21)
		if string.find(string.lower(_groupName), " bvre ") then _engagementrange = 20000 end -- Early radar guided (ie R-24 equipped fighters, like MiG-23)
		if string.find(string.lower(_groupName), " bvra ") then _engagementrange = 50000 end -- Active medium range radar guided (ie AIM-120, R-77)
		if string.find(string.lower(_groupName), " bvrl ") then _engagementrange = 90000 end -- Active long range radar guided (ie AIM-54, R-33)
		
		-- Get combat radius setting
		local _combatradius = 250000 -- Default combat-radius (ie from Vaziani to Kobuleti)
		if string.find(string.lower(_groupName), " sscr ") then _combatradius = 50000 end -- Short-range, ie base-defence only
		if string.find(string.lower(_groupName), " mscr ") then _engagementrange = 15000 end -- Medium short-range, ie from Sukhumi to Kobuleti
		if string.find(string.lower(_groupName), " mlcr ") then _engagementrange = 500000 end -- Medium long-range, ie from Novorossiysk to Nalchik
		if string.find(string.lower(_groupName), " vlcr ") then _engagementrange = 1000000 end -- Entire map
		
		local newsquadron = {
		airdromeId = 0, -- Homebase for the interceptorsquadron
		interceptspeed = _ispeed, -- Intecept targets at this speed in meter/second
		interceptalt = _ialt, -- Fly at this altitued while intercepting
		interceptalt_type = _ialttype,  -- Use this type of altitude when intercepting, "RADIO" or "BARO"
		egressspeed = 170, -- Fly in this speed when cruising/looking for targets/returning home
		egressalt = _ialt, -- Fly at this altitude
		egressalt_type = _ialttype,
		usesearchradar = _searchradar, -- Use radar when flying to interception-point
		useattackradar = _attackradar, -- Use radar when attacking target
		engagementrange = _engagementrange, -- Attack targets at this range in meters
		combatradius = _combatradius, -- Maximum range from starting point that the interceptor will fly
		
		flights = -- List of groups and flags to activate interceptor flights
		{
			{_groupName, "9999999"},
		}
		}
		local _interceptorgroup = Group.getByName(_groupName)
		local _interceptorunit = getAliveUnits(_interceptorgroup)[1]
		if (_interceptorgroup:getCoalition() == coalition.side.BLUE) then
			table.insert(gci.blueinterceptorsquadrons, newsquadron)
		else
			table.insert(gci.redinterceptorsquadrons, newsquadron)
		end

		--env.info(mist.utils.tableShow(_groupdata),true)
		--local _newgroupname = gci.dynAdd(_groupdata)
		--env.info(string.format("New group name: %s", _newgroupname), true)
		--local _clone = mist.cloneGroup(_groupName, true)
		
		--env.info(string.format("Group cloned: %s", _clone["name"]),true)
	end
	end
			-- if (vnt.id == 6) then
				-- -- Pilot ejected
				-- if (gci.verbose > 0) then env.info(string.format("Pilot %s ejected", Object.getName(vnt.initiator))) end
				-- local _unit = vnt.initiator
				-- local grp = Unit.getGroup(vnt.initiator)
				-- local coalit = Group.getCoalition(grp)
				-- if (coalit == BLUE) then
					-- -- Blue pilot ejected
					-- -- get coordinates
					-- -- local llcord = coord.LOtoLL(Object.getPoint(vnt.initiator))
					
					-- local tabCommand = {
						-- id = "TransmitMessage",
						-- params = {
							-- subtitle = "Mayday mayday! Airmen down! Chute spotted!", --, lloc,
							-- duration = 3,
							-- loop = false,
							-- file = "radio.ogg",
						-- }
					-- }
					
					-- Controller.setCommand(grp, tabCommand)
					-- -- trigger.action.radioTransmission("radio.ogg", Object.getPoint(vnt.initiator), radio.modulation.AM, false, 124000000, 1000000)
				-- end
			-- end
			-- if (vnt.id == 9) then
				-- -- Pilot dead
				-- if (gci.verbose > 0) then env.info(string.format("Pilot %s dead", Object.getName(vnt.initiator))) end
				-- local _unit = vnt.initiator
				-- local grp = Unit.getGroup(vnt.initiator)
				-- local coalit = Group.getCoalition(grp)
				-- if (coalit == BLUE) then
					-- -- Blue pilot dead
					-- -- get coordinates
					-- -- local llcord = coord.LOtoLL(Object.getPoint(vnt.initiator))
					
					-- local tabCommand = {
						-- id = "TransmitMessage",
						-- params = {
							-- subtitle = "Mayday mayday! Airmen down! No chute.", --, lloc,
							-- duration = 3,
							-- loop = false,
							-- file = "radio.ogg",
						-- }
					-- }
					
					-- Controller.setCommand(grp, tabCommand)
					-- -- trigger.action.radioTransmission("radio.ogg", Object.getPoint(vnt.initiator), radio.modulation.AM, false, 124000000, 1000000)
				-- end
			-- end
		end
	, vnt)
	if (not status) then env.error(string.format("Error while handling event\n\n%s",err), true) end
end

-- Trace function
function gci.trace(s)
	if (gci.verbose > 2) then
	if (type(s)=="table") then s = mist.utils.tableShow(s) end
	if lfs and io then
		local fdir = lfs.writedir() .. [[Logs\]] .. "GCI_Trace.log"
		local f = io.open(fdir, 'w')
		f:write(s)
		f:close()
	else
		local errmsg = 'Error: insufficient libraries to run gci.trace(), you must disable the sanitization of the io and lfs libraries in ./Scripts/MissionScripting.lua'
		env.warning(errmsg)
		--trigger.action.outText(errmsg, 10)
	end
	end
end

function gci.dointercept(target, iflight, startpos)
		local sts, rtrn = pcall(
		function (target, iflight, startpos)
		if (gci.verbose > 0) then env.info(string.format("Dointercept for: %s trigger:%s", iflight[2], iflight[3]), false) end
		if (gci.verbose > 0) then env.info(string.format("Dointercept target: %s group: %s", Unit.getName(target), Group.getName(Unit.getGroup(target))),false) end
		local _targetGroupId = Group.getID(Unit.getGroup(target));

		local _targetunit = target
		local _targetunitpos = _targetunit:getPosition();
		local _targetunitposp = _targetunitpos.p;
		local _targetheading = mist.getHeading(_targetunit)
		local _velv = _targetunit:getVelocity()
		local _targetspeed = string.format('%12.2f', mist.vec.mag(_velv))
		local _interceptorgroup
		if (string.find(string.lower(iflight[3]), "iprototype")) then 
			-- Its a dynamically spawn group
			if (tablelength(getAliveUnits(Group.getByName(iflight[2])))<1) then
				-- It hasn't been spawned in yet, therefore use prototype group
				_interceptorgroup = Group.getByName(iflight[3])
				removeintable(gci.interceptorfinished, iflight[2])
			else
				-- It has been spawned in, so use the clone
				_interceptorgroup = Group.getByName(iflight[2])
			end
		else
			-- Its not a dynamically spawn group, use it as normal
			_interceptorgroup = Group.getByName(iflight[2])
		end
		local _interceptorunit = getAliveUnits(_interceptorgroup)[1]
		local _interceptorunitpos = _interceptorunit:getPosition();
		local _interceptorunitposp = _interceptorunitpos.p;
		local _interceptorstart = startpos or _interceptorunitposp
		local _interceptorhomebase = iflight[4].airdromeId
		local _interceptorspeed = iflight[4].interceptspeed
		local _interceptoralt = iflight[4].interceptalt
		local _interceptoralt_type = iflight[4].interceptalt_type
		local _interceptorcruisespeed = iflight[4].egressspeed
		local _interceptorcruiesalt = iflight[4].egressalt
		local _interceptorcruiesalt_type = iflight[4].egressalt_type
		local _interceptorusesearchradar = iflight[4].usesearchradar
		local _interceptoruseattackradar = iflight[4].useattackradar
		local _interceptrange = iflight[4].engagementrange
		local _interceptcombradius = iflight[4].combatradius

		local _ipoints = {}
		if (Unit.inAir(_interceptorunit)) then
			-- Unit is already in the air so dont have to compensate for taxi/takeoff
			_ipoints = {gci.calculteInterceptionPoint(_targetunitpos.p, _velv, _interceptorunitposp, _interceptorspeed, 10)}
		else
			-- get three interceptpoints and get the closest one
			_ipoints = {
				gci.calculteInterceptionPoint(_targetunitpos.p, _velv, _interceptorunitposp, _interceptorspeed, 100),
				gci.calculteInterceptionPoint(_targetunitpos.p, _velv, _interceptorunitposp, _interceptorspeed, 200),
				gci.calculteInterceptionPoint(_targetunitpos.p, _velv, _interceptorunitposp, _interceptorspeed, 300)
				}
		
			-- sort them according to distance to point
			table.sort(_ipoints, 
				function(a,b)
					xdist = measuredistance({x = a.x, z = a.y}, _interceptorunitposp)
					ydist = measuredistance({x = b.x, z = b.y}, _interceptorunitposp)
					assert(xdist ~= nil, "X distance is nil!")
					assert(ydist ~= nil, "Y distance is nil!")
					return  xdist < ydist
				end
			)
			if (_ipoints[1] ~= nil and gci.verbose > 0) then env.info(string.format("Ideal interception point:x %f y %f", _ipoints[1].x, _ipoints[1].y)) end
			
		end
		if (_ipoints[1] == nil) then
			env.warning("Couldnt get a interceptionpoint so setting own position")
			table.insert(_ipoints, {x = _interceptorunitposp.x, y = _interceptorunitposp.z})
		end
		if (measuredistance({x = _ipoints[1].x, z = _ipoints[1].y}, _interceptorstart) > _interceptcombradius) then
			env.info("Intercept point is beyond combat radius. Aborting mission.")
			table.insert(_ipoints, {x = _interceptorunitposp.x, y = _interceptorunitposp.z})
		end
		local _distanceipoint = measuredistance({x = _ipoints[1].x, z = _ipoints[1].y}, _interceptorunitposp)
		local _ipoint
		if (_distanceipoint < _interceptrange) then
			-- Attack target directly after take-off
			_ipoint = _interceptorunitposp --gci.getpointbetween(_interceptorunitposp, {x = _ipoints[1].x, y = 0, z = _ipoints[1].y}, 0.33)
			-- HACK! Attack almost directly
			env.info("Attack directly")
			--local _cutshortfraction = ((_distanceipoint - _interceptrange) / _distanceipoint) / 10
			--_ipoint = gci.getpointbetween(_interceptorunitposp, {x = _ipoints[1].x, y = 0, z = _ipoints[1].y}, _cutshortfraction)
		
		else
			-- Set towards intercept point and start attack at engagementrange
			local _cutshortfraction = (_distanceipoint - _interceptrange) / _distanceipoint
			_ipoint = gci.getpointbetween(_interceptorunitposp, {x = _ipoints[1].x, y = 0, z = _ipoints[1].y}, _cutshortfraction)
		end
		-- trigger.action.smoke({x = _ipoint.x, y = _targetunitpos.p.y, z = _ipoint.y}, trigger.smokeColor.Blue)
		
		if (gci.verbose > 0) then env.info(string.format("interceptorunitposp: x: %f y: %f z: %f \n targetpos x: %f | y: %f | z: %f \n ipoint x: %f  - y: %f - z: %f", _interceptorunitposp.x, _interceptorunitposp.y, _interceptorunitposp.z, _targetunitposp.x, _targetunitposp.y, _targetunitposp.z, _ipoint.x, _ipoint.y, _ipoint.z)) end
		local dointercept = true
		local addedpoint = false
		local pointtoremove = {"NOTHING"}
		local secondarytargets = {}
		for q,point in pairs(gci.interceptionpoints) do
			--env.info(mist.utils.tableShow(point), false) 
			local pos = point.position
			local plndinterceptors = point.plannedinterceptors
			local plndtargets = point.plannedtargets
			local plndrange = point.range
			local dist = measuredistance(_ipoint, pos)
			if (gci.verbose > 0) then env.info(string.format("Distance to IPOINT: %f", dist)) end
			if (dist <= plndrange) then
				local interceptornr = 0
				local targetnr = 0
				for z,intrcptr in pairs(plndinterceptors) do
					local sts, rtrn = pcall(function(_intrcptr) return getAliveUnits(_intrcptr) end, intrcptr)
					if (sts and not tablecontains(gci.interceptorfinished, intrcptr)) then 
						if (getGroupHealthPercentage(intrcptr) > 55) then
							interceptornr = interceptornr + tablelength(rtrn) 
						end
					end
				end
				if (gci.verbose > 0) then env.info(string.format("Interceptors: %f", interceptornr)) end
				for y,trgt in pairs(plndtargets) do
					local sts, rtrn = pcall(function(_trgt) return getAliveUnits(_trgt) end, trgt)
					if (sts) then 
						targetnr = targetnr + tablelength(rtrn) 
						table.insert(secondarytargets, trgt)
					end
				end
				if (not tablecontains(plndtargets, Unit.getGroup(target))) then targetnr = targetnr + tablelength(getAliveUnits(Unit.getGroup(target))) end
				if (gci.verbose > 0) then env.info(string.format("Targets: %f", targetnr)) end
				if (interceptornr >= targetnr) then
					-- there are already enough fighters going there, dont plan more
					if (gci.verbose > 0) then env.info("Intercept skipped.", false) end
					dointercept = false
					addedpoint = true
				else
					-- this flight should support the interceptors already going
					if (not tablecontains(gci.interceptionpoints[q].plannedinterceptors, _interceptorgroup)) then
						table.insert(gci.interceptionpoints[q].plannedinterceptors, _interceptorgroup)
					end
					if (not tablecontains(gci.interceptionpoints[q].plannedtargets, Unit.getGroup(target))) then
						table.insert(gci.interceptionpoints[q].plannedtargets, Unit.getGroup(target))
					end
					addedpoint = true
				end
			else
				-- Remove old interceptionpoints
				if (tablecontains(plndinterceptors, _interceptorgroup)) then 
					removeintable(gci.interceptionpoints[q].plannedinterceptors, _interceptorgroup)
					if (tablelength(gci.interceptionpoints[q].plannedinterceptors) < 1) then
						pointtoremove = gci.interceptionpoints[q]
					end
				end
			end
		end
		--gci.trace(gci.interceptionpoints)
		if (pointtoremove ~= {"NOTHING"}) then removeintable(gci.interceptionpoints, pointtoremove) end
		if (addedpoint==false) then table.insert(gci.interceptionpoints, {position = _ipoint, plannedinterceptors = {_interceptorgroup}, range = _interceptrange, plannedtargets = {Unit.getGroup(target)}}) end
		if (gci.verbose > 0) then env.info("Finished looking at interceptionpoints",false) end
		
		local _engagetask = {
			id = 'AttackGroup', 
			params = { 
				groupId = _targetGroupId
			} 
		} 
 
		local _enrouteengagetask ={ 
			id = 'EngageTargets', 
			params = { 
				maxDist = _interceptrange, 
				targetTypes = { 
					[1] = "Bombers", 
					[2] = "Strategic bombers",
					[3] = "Planes", 
					[4] = "Air"
				}, 
				priority = 1 
			} 
		}
		local _wrappedaction = {}
		if (gci.verbose > 1) then 
		_wrappedaction = { 
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = string.format("trigger.action.outText(\"Interceptor group %s is attacking target.\", 10)", iflight[2])
					} 
				}
			}
		}
		else
		_wrappedaction = {
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = ""
					} 
				}
			}
		}
		end
 
		local _wrappedaction2 = {
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = ""
					} 
				}
			}
		}
		local _useradartext = ""
		if (_interceptoruseattackradar) then 
			_wrappedaction2 = { 
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = string.format("Group.getByName(\"%s\"):getController().setOption(Group.getByName(\"%s\"):getController(), 3, 3)", iflight[2], iflight[2])
					} 
				}
			}
			}
			_useradartext = "Use radar."
		
		else 
			_wrappedaction2 = { 
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = ""
					} 
				}
			}
			}
		end
		
		local _wrappedaction3 = {
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = string.format("table.insert(gci.attackinginterceptors, \"%s\")", iflight[2])
					} 
				}
			}
		}
		
		local _makeavailable = {
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = string.format("removeintable(gci.attackinginterceptors, \"%s\")", iflight[2])
					} 
				}
			}
		}
		
		_wpswitch = { 
			id = 'WrappedAction', 
			params = { 
				action = { 
					id = 'Script', 
					params = { 
						command = string.format("if (tablelength(getAliveUnits(Group.getByName(\"%s\"))) < 1) then Group.getByName(\"%s\"):getController().setCommand(Group.getByName(\"%s\"):getController(), {id = 'SwitchWaypoint', params = {fromWaypointIndex = 3, goToWaypointIndex = 4,}}) end",Group.getName(Unit.getGroup(target)), iflight[2], iflight[2])
					} 
				}
			}
		}
		
		local tarvec = {x = _targetunitposp.x - _interceptorunitposp.x, y = _targetunitposp.y - _interceptorunitposp.y, z = _targetunitposp.z - _interceptorunitposp.z}
		local tardir = math.deg(mist.utils.getDir(tarvec, _interceptorunitposp))
		local _unittable = {getAliveUnits(_interceptorgroup)[1]:getName()}
		--local _targetinfo = string.format("Your target should be at bearing %s. You are clear to engage. %s", iflight[2], mist.getBRString({units = _unittable, ref = _ipoint, alt = math.floor(_targetunitposp.z/100)*100, metric = 1}),_useradartext)
		local _informplayer = {
			id = 'WrappedAction',
			params = {
				action = {
					id = 'Script',
					params = {
						command = string.format("trigger.action.outTextForGroup(Group.getID(Group.getByName(\"%s\")), \"Your target should be at bearing %d altitude %d. You are cleared to engage. %s\", 60)", iflight[2], tardir, math.floor(_targetunitposp.y/100)*100,_useradartext)
					}
				}
			}
		}
		
		local _orbittask = {id = 'Orbit', params = {pattern = "Circle"}}

		local _controlledtask = {
			id = 'ControlledTask',
			params = {
				task = _orbittask,
				stopCondition = {
					duration = 120
				}
			}
		}
		local _newcombotask = {}
		local _newtask = { 
						[1] = _informplayer,
						[2] = _wrappedaction,
						[3] = _wrappedaction2,
						[4] = _wrappedaction3,
						[5] = _engagetask,
						[6] = _enrouteengagetask,
						[7] = _controlledtask,
						--[8] = _wpswitch,
						}
		local _enroutetask = { 
						[1] = _engagetask,
						[2] = _enrouteengagetask
						}
		local _egresstask = {
						[1] = _wrappedaction,
						[2] = _wrappedaction2,
						[3] = _makeavailable,
						[4] = _engagetask,
						[5] = _enrouteengagetask,
						[6] = _controlledtask
				}
		local _lastcount = 0
		for f,_targetg in pairs(secondarytargets) do
			if (tablelength(getAliveUnits(_targetg))>0) then
				local _secondarynewengage = {
					id = 'AttackGroup', 
					params = { 
						groupId = Group.getID(_targetg)
					} 
				} 
				_newtask[f+7] = _secondarynewengage
			end
		end
		local _newcombotask = { 
				id = 'ComboTask', 
				params = { 
					tasks = _newtask
				} 
		}
		local _enroutecombotask = {
				id = 'ComboTask',
				params = {
					tasks = _enroutetask
				}
		}
		local _egressecombotask = {
				id = 'ComboTask',
				params = {
					tasks = _egresstask
				}
		}
		--if (gci.verbose > 0) then 
		--			env.info(mist.utils.oneLineSerialize(_newcombotask), false) 
		--			env.info(mist.utils.oneLineSerialize(_newtask), false)
		--		end
				--gci.trace(_newcombotask)
				--mist.debug.writeData (function(arg) return arg end, {_newcombotask}, "newcombotask.dmp")
		local _combotask = {}
		if (_interceptoruseattackradar) then
			_combotask = { 
				id = 'ComboTask', 
				params = { 
					tasks = { 
						[1] = _wrappedaction,
						[2] = _wrappedaction2,
						[3] = _wrappedaction3,
						[4] = _engagetask, 
						[5] = _enrouteengagetask,
						[6] = _controlledtask
					} 
				} 
			} 
		else
			_combotask = { 
				id = 'ComboTask', 
				params = { 
					tasks = { 
						[1] = _wrappedaction,
						[2] = _wrappedaction3,
						[3] = _engagetask, 
						[4] = _enrouteengagetask,
						[5] = _controlledtask
					} 
				} 
			} 
		end
		local _approachtask = nil
		if (_interceptorusesearchradar == true) then _approachtask = _enroutecombotask end
		local _mission = { 
			id = 'Mission', 
			params = { 
				route = { 
					points = { 
      
						[1] = { 
							type = "Turning Point", 
							airdromeId = nil, 
							helipadId = nil, 
							action = "Fly Over Point", 
							x = _ipoint.x,
							y = _ipoint.z,
							alt = _interceptoralt, 
							alt_type = _interceptoralt_type, 
							speed = _interceptorspeed, 
							speed_locked = true, 
							ETA = 100, 
							ETA_locked = false, 
							name = "Approach", 
							task = _approachtask
						},
						[2] = { 
							type = "Turning Point", 
							airdromeId = nil, 
							helipadId = nil, 
							action = "Fly Over Point", 
							x = _ipoint.x,-- + math.random(4000) - math.random(4000), --Don't remember why I added this in?
							y = _ipoint.z,-- + math.random(4000) - math.random(4000),
							alt = _interceptorcruiesalt, 
							alt_type = _interceptorcruisealt_type, 
							speed = _interceptorcruisespeed, 
							speed_locked = true, 
							ETA = 100, 
							ETA_locked = false, 
							name = "Attack", 
							task = _newcombotask
						},
						-- [3] = { 
							-- type = "Turning Point", 
							-- airdromeId = nil, 
							-- helipadId = nil, 
							-- action = "Fly Over Point", 
							-- x = _targetunitposp.x,-- + math.random(4000) - math.random(4000), --Don't remember why I added this in?
							-- y = _targetunitposp.z,-- + math.random(4000) - math.random(4000),
							-- alt = _targetunitposp.y, 
							-- alt_type = "BARO", 
							-- speed = _interceptorcruisespeed, 
							-- speed_locked = true, 
							-- ETA = 100, 
							-- ETA_locked = false, 
							-- name = "Rendevouz", 
							-- task = _newcombotask
						-- },						
						[3] = { 
							type = "Land", 
							airdromeId = _interceptorhomebase, 
							helipadId = nil, 
							action = nil, 
							x = _interceptorstart.x,
							y = _interceptorstart.z,
							alt = _interceptorcruiesalt, 
							alt_type = _interceptorcruisealt_type, 
							speed = _interceptorcruisespeed, 
							speed_locked = true, 
							ETA = 100, 
							ETA_locked = false, 
							name = "Land", 
							task = _egressecombotask
						} 
					} 
				}
			} 
		}
		if getAliveUnits(_interceptorgroup)[1]:getPlayerName() ~= nil then
			env.info("This is a human flight.",false)
		end
		--trigger.action.outTextForGroup(Group.getID(_interceptorgroup), "You have been assigned a target. Standby for directions.", 5)
					
		if (dointercept) then
			-- Activate unit
			--env.info(iflight[3],true)
			if (string.find(string.lower(iflight[3]), "iprototype")) then 
				if (tablelength(getAliveUnits(iflight[2]))<1) then
					-- Spawn in in unit
					local _groupdata = mist.getGroupData(iflight[3])
					_groupdata.clone = 'order66'
					_groupdata.country = mist.DBs.groupsByName[iflight[3]].country
					_groupdata.category = mist.DBs.groupsByName[iflight[3]].category
					_groupdata.route = mist.getGroupRoute(iflight[3], 'task')
					_groupdata.name = iflight[2]
					_groupdata.groupName = iflight[2]
					--env.info(mist.utils.tableShow(_groupdata),true)
					local _newgroupname = gci.dynAdd(_groupdata)
					env.info(string.format("Spawned new group name: %s", _newgroupname), false)
					_interceptorgroup = Group.getByName(_newgroupname)
				end
			else
				trigger.action.setUserFlag(iflight[3], true)
			end
			
			
			mist.scheduleFunction (function(_interceptorgroup,_interceptorusesearchradar,_mission, _targetunitposp)
				local stus, erronr = pcall(function (_interceptorgroup,_interceptorusesearchradar,_mission, _targetunitposp)
				if (tablelength(getAliveUnits(_interceptorgroup))<1) then
					env.warning("Group no longer exists. Aborting setting task.",false)
					return
				end
				-- Set radar and mission
				local _controller = _interceptorgroup:getController();
				if (_interceptorusesearchradar == false) then
					Controller.setOption(_controller, 3, 0) 
				else
					Controller.setOption(_controller, 3, 3) 
				end
				Controller.setOption(_controller, 6, true)
				if (gci.verbose > 0) then 
					--env.info(mist.utils.tableShow(_mission), false) 
				end
				--if (_dist > _interceptrange and _dist > (_interceptorspeed * 10.1)) then -- Don't reassign if within 10 seconds from intercept point.
					_controller:setTask(_mission)
				--end
				-- env.error("Now?", true)
				 
				if (not tablecontains(gci.busyinterceptors, _interceptorgroup)) then table.insert(gci.busyinterceptors, _interceptorgroup) end
				end
				,_interceptorgroup,_interceptorusesearchradar,_mission, _targetunitposp)
				if (not stus) then env.error(string.format("Error while setting scheduled missiontask!\n\n%s", erronr), true) end
			
			end, {_interceptorgroup, _interceptorusesearchradar, _mission, _targetunitposp}, timer.getTime () + 1 ) 
		end
	if getAliveUnits(_interceptorgroup)[1]:getPlayerName() ~= nil then
					
					env.info(string.format("Diverting player flying %s", Object.getTypeName(getAliveUnits(_interceptorgroup)[1])), false)
					local _dist = measuredistance(_ipoint, _interceptorunitposp)
					local _diststr = string.format("%dkm",math.floor(_dist/1000)) -- Kilometers
					local _ialtstr = string.format("%d",_interceptoralt) -- Meters
					local _taltstr = string.format("%d",math.floor(_targetunitposp.y/100)*100) -- Meters (100m rounding)
					local _ispeed = string.format("%dkm/h",_interceptorspeed * 3.6) -- Kilometers per hour
					if (Object.getTypeName(getAliveUnits(_interceptorgroup)[1]) == "F-15C" or Object.getTypeName(getAliveUnits(_interceptorgroup)[1]) == "A-10A" or Object.getTypeName(getAliveUnits(_interceptorgroup)[1]) == "A-10C") then
						-- Use knots/feet/nm for American aircrafts
						_diststr = string.format("%dnm",math.floor(_dist*0.000539956803),_dist) -- Nautical miles
						_ialtstr = string.format("%d",math.floor((_interceptoralt*3.2808399)/1000)*1000) -- Feet (1000 feet rounding)
						if (_interceptoralt == 100) then
							-- Nap-of-the-earth
							_ialtstr = "300"
						end
						_taltstr = string.format("%d",math.floor((_targetunitposp.y*3.2808399)/300)*300) -- Feet (300f rounding)
						_ispeed = string.format("%dkts", math.floor(_interceptorspeed * 1.94384449)) -- Knots
					end
					--trigger.action.outTextForGroup(Group.getID(_interceptorgroup), "You have been assigned a target. Standby for directions.", 10)
					local vec = {x = _ipoint.x - _interceptorunitposp.x, y = _ipoint.y - _interceptorunitposp.y, z = _ipoint.z - _interceptorunitposp.z}
					local dir = mist.utils.getDir(vec, _interceptorunitposp)
					local tarvec = {x = _targetunitposp.x - _interceptorunitposp.x, y = _targetunitposp.y - _interceptorunitposp.y, z = _targetunitposp.z - _interceptorunitposp.z}
					local tardir = math.deg(mist.utils.getDir(tarvec, _interceptorunitposp))
					local _engagetext = "You are cleared to engage."
					if (tablecontains(gci.divertables, Group.getName(Unit.getGroup(_targetunit)))) then _engagetext = "Weapons hold. Try to divert the target." end
					local _targetinfo = string.format("\nYour target should be at heading %d altitude %s. %s %s", tardir+mist.getNorthCorrection(_interceptorunitposp), _taltstr,_engagetext,_useradartext)
					if (_dist > _interceptrange) then _targetinfo = "" end
					local _BRAATEXT = string.format("Fly heading %d for %s at speed %s and altitude %s%s", math.deg(dir+mist.getNorthCorrection(_interceptorunitposp)),_diststr, _ispeed, _ialtstr, _targetinfo)
					
					if getAliveUnits(_interceptorgroup)[1]:inAir() == false then _BRAATEXT = string.format("Take off and fly heading %d at speed %s and altitude %s", math.deg(dir+mist.getNorthCorrection(_interceptorunitposp)), _ispeed, _ialtstr) end
					local _infoforplayer = _BRAATEXT
					--if (_dist < _interceptrange) then _infoforplayer = _targetinfo end--string.format("Your target should be at bearing %d altitude %d. You are clear to engage. %s", tardir, math.floor(_targetunitposp.y/100)*100,_useradartext) end 
					--local _BRAATEXT = string.format("Fly heading %s speed %d", mist.getBRString({units = _unittable, ref = _ipoint, alt = _interceptoralt, metric = 1}),_interceptorspeed)
					
					trigger.action.outTextForGroup(Group.getID(_interceptorgroup), _infoforplayer, 60)
					--missionCommands.addCommandForGroup(Group.getID(_interceptorgroup), "Repeat last transmission", nil, function(_infoforplayer, _interceptorgroup) trigger.action.outTextForGroup(Group.getID(_interceptorgroup), _infoforplayer, 60) end, _interceptorgroup, _infoforplayer)
					env.info("Done diverting player", false)
				 end
	function psetmissiontask(target, iflight, func)
		local status, err = pcall(func, target, iflight)
		if (not status) then env.error(string.format("Error while setting missiontask!\n\n%s", err), true) end
	end
	


	
		env.info("DoIntecept() finished", false)
	end
	, target, iflight, startpos)
	if (sts) then 
		return rtrn 
	else 
		env.error(string.format("DoIntercept() failed! %s", rtrn), true)
		return 0
	end
end

function gci.divertable(params)
	local _groupName = params[1]
	--env.info(_groupName,true)
	local sts, rtrn = pcall(
	function (_groupName)
	
	--env.info(_groupName,true)
	if (_groupName == nil or _groupName == "") then
		env.warning("Group is nil!", false)
		return -1
	end
	local _enemyunits = {}
	local _flightlead = getAliveUnits(Group.getByName(_groupName))[1]
	if (#getAliveUnits(Group.getByName(_groupName)) < 1) then
		env.warning("Group is dead?", false)
		return -1
	end
	if (Group.getCoalition(Group.getByName(_groupName)) == coalition.side.BLUE) then
		_enemyunits = mist.getUnitsLOS({Unit.getName(_flightlead)}, 0, mist.makeUnitTable({"[red]"}), 0, 400)
	else
		_enemyunits = mist.getUnitsLOS({Unit.getName(_flightlead)}, 0, mist.makeUnitTable({"[blue]"}), 0, 400)
	end
	
	
	
	if (#_enemyunits > math.random(0,1)) then
	--local _wps = gci.getRemainingWaypoints(_group)
		local _allwps = mist.getGroupPoints(_groupName)
		local _lastwp = _allwps[(#_allwps)]
		--v.info(string.format("%s\n\n%s", mist.utils.tableShow(_allwps), mist.utils.tableShow(_lastwp)), true)
		local Mission = { 
				id = 'Mission', 
				params = { 
					route = { 
						points = {
							[1] = { 
								type = "Land", 
								airdromeId = nil, 
								helipadId = nil, 
								action = nil, 
								x = _lastwp.x,
								y = _lastwp.y,
								alt = _flightlead:getPosition().p.y, 
								alt_type = "BARO", 
								speed = 111,
								speed_locked = true, 
								ETA = 100, 
								ETA_locked = false, 
								name = "Land"
							}
						}
					}, 
				} 
			}
		Group.getByName(_groupName):getController():setTask(Mission) -- Flee!!
		return -1
	end
	--env.info("Divertable ping!",false)
	return timer.getTime() + 30
	end
	, _groupName)
	if (sts) then 
		return rtrn 
	else 
		env.error(string.format("Divertable failed! %s", rtrn), true)
	end
end

-- This will loop through all units and add groups with "IPrototype" or "Divertable" in their name (code stolen from IADS)
for _groupName, _groupData in pairs(mist.DBs.groupsByName) do -- checks all groups in mission	
	local sts, rtrn = pcall(
	function (_groupName, _groupData)
	if string.find(string.lower(_groupName), "iprototype") then -- Finds group with Interceptor-prototype in name
		env.info(string.format("Dynamic Interceptor-group %s found",_groupName), false)
		
		-- Get speed setting
		local _ispeed = 370 -- Default M1.1
		if string.find(string.lower(_groupName), " z ") then _ispeed = 262 end -- M0.77
		if string.find(string.lower(_groupName), " x ") then _ispeed = 680 end -- M2
		if string.find(string.lower(_groupName), " y ") then _ispeed = 880 end -- M2.6
		
		-- Get altitude setting
		-- medium altitude is between 3000m and 9000m (USAF standard)
		local _ialt = 6000 -- Default medium altitude (20000ft)
		local _ialttype = "BARO" -- Default medium altitude barometric height
		if string.find(string.lower(_groupName), " n ") then -- Nap-of-the-earth (very low)
			_ialt = 100
			_ialttype = "RADIO"
		end
		if string.find(string.lower(_groupName), " ll ") then -- Low-low
			_ialt = 1000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hl ") then -- High-low
			_ialt = 2000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " lm ") then -- Low-medium
			_ialt = 4000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hm ") then -- High-medium
			_ialt = 8000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " lh ") then -- Low-High
			_ialt = 10000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hh ") then -- High-High
			_ialt = 15000
			_ialttype = "BARO"
		end
		
		-- Get radar setting search radar (this will also enable engaging targets while enroute)
		local _searchradar = false -- Default false
		if string.find(string.lower(_groupName), " q ") then _searchradar = true end
		
		-- Get radar setting attack radar
		local _attackradar = true -- Default true
		if string.find(string.lower(_groupName), " s ") then _attackradar = false end
		
		-- Get engagement range setting
		local _engagementrange = 35000 -- Default attack-range (for AIM-7, R-27 equipped fighters)
		if string.find(string.lower(_groupName), " wvrb ") then _engagementrange = 2000 end -- WVR bad visibility
		if string.find(string.lower(_groupName), " wvrg ") then _engagementrange = 5000 end -- WVR good visibility
		if string.find(string.lower(_groupName), " bvrs ") then _engagementrange = 12000 end -- Very short-range BVR (ie R-13 or AIM-9 equipped, like MiG-21)
		if string.find(string.lower(_groupName), " bvre ") then _engagementrange = 20000 end -- Early radar guided (ie R-24 equipped fighters, like MiG-23)
		if string.find(string.lower(_groupName), " bvra ") then _engagementrange = 50000 end -- Active medium range radar guided (ie AIM-120, R-77)
		if string.find(string.lower(_groupName), " bvrl ") then _engagementrange = 90000 end -- Active long range radar guided (ie AIM-54, R-33)
		
		-- Get combat radius setting
		local _combatradius = 250000 -- Default combat-radius (ie from Vaziani to Kobuleti)
		if string.find(string.lower(_groupName), " sscr ") then _combatradius = 50000 end -- Short-range, ie base-defence only
		if string.find(string.lower(_groupName), " mscr ") then _engagementrange = 15000 end -- Medium short-range, ie from Sukhumi to Kobuleti
		if string.find(string.lower(_groupName), " mlcr ") then _engagementrange = 500000 end -- Medium long-range, ie from Novorossiysk to Nalchik
		if string.find(string.lower(_groupName), " vlcr ") then _engagementrange = 1000000 end -- Entire map
		
		local newsquadron = {
		airdromeId = 0, -- Homebase for the interceptorsquadron
		interceptspeed = _ispeed, -- Intecept targets at this speed in meter/second
		interceptalt = _ialt, -- Fly at this altitued while intercepting
		interceptalt_type = _ialttype,  -- Use this type of altitude when intercepting, "RADIO" or "BARO"
		egressspeed = 170, -- Fly in this speed when cruising/looking for targets/returning home
		egressalt = _ialt, -- Fly at this altitude
		egressalt_type = _ialttype,
		usesearchradar = _searchradar, -- Use radar when flying to interception-point
		useattackradar = _attackradar, -- Use radar when attacking target
		engagementrange = _engagementrange, -- Attack targets at this range in meters
		combatradius = _combatradius, -- Maximum range from starting point that the interceptor will fly
		
		flights = -- List of groups and flags to activate interceptor flights
		{
			{string.format("%s Dyn Interceptor flight #1", _groupName), _groupName},
			{string.format("%s Dyn Interceptor flight #2", _groupName), _groupName},
			{string.format("%s Dyn Interceptor flight #3", _groupName), _groupName},
			{string.format("%s Dyn Interceptor flight #4", _groupName), _groupName},
			{string.format("%s Dyn Interceptor flight #5", _groupName), _groupName},
			{string.format("%s Dyn Interceptor flight #6", _groupName), _groupName}
		}
		}
		local _interceptorgroup = Group.getByName(_groupName)
		local _interceptorunit = getAliveUnits(_interceptorgroup)[1]
		if (Unit.getCoalition(_interceptorunit) == coalition.side.BLUE) then
			table.insert(gci.blueinterceptorsquadrons, newsquadron)
		else
			table.insert(gci.redinterceptorsquadrons, newsquadron)
		end
		
		local _groupdata = mist.getGroupData(_groupName)
		_groupdata.clone = 'order66'
		_groupdata.country = mist.DBs.groupsByName[_groupName].country
		_groupdata.category = mist.DBs.groupsByName[_groupName].category
		_groupdata.route = mist.getGroupRoute(_groupName, 'task')
		_groupdata.name = "Dyn Interceptor flight test"
		_groupdata.groupName = "Dyn Interceptor flight test"
		--env.info(mist.utils.tableShow(_groupdata),true)
		--local _newgroupname = gci.dynAdd(_groupdata)
		--env.info(string.format("New group name: %s", _newgroupname), true)
		--local _clone = mist.cloneGroup(_groupName, true)
		
		--env.info(string.format("Group cloned: %s", _clone["name"]),true)
	end
	if string.find(string.lower(_groupName), "divertable") then -- Finds group with Divertable in name
		timer.scheduleFunction(gci.divertable, {_groupName}, timer.getTime() + 10)
		table.insert(gci.divertables,_groupName)
	end
	if string.find(string.lower(_groupName), "ewr") then -- Finds group with EWR in name
		
		-- Get detection range setting
		local _radius = 120000 -- Default EWR 1L13 and 55G6 (and AWACS?)
		local _filteragl = 50 -- Default to filter out below 50 meters
		local _filtercv = 25 -- Default velicity filter
		local _offset = 5 -- Default 5m offset (AWACS...)
		if string.find(string.lower(_groupName), " x ") then _radius = 30000 end -- Roland
		if string.find(string.lower(_groupName), " y ") then _radius = 80000 end -- Sborka
		if string.find(string.lower(_groupName), " z ") then _radius = 90000 end -- HAWK
		if string.find(string.lower(_groupName), " xx ") then _radius = 160000 end -- Patriot
		if string.find(string.lower(_groupName), " v ") then 
			_radius = 5000 
			_filteragl = 0
			_filtercv = 0
			_offset = 2
		end -- Visual
		
		-- Get height offset
		if string.find(string.lower(_groupName), " q ") then _offset = 12 end -- Ground radar mast
		if string.find(string.lower(_groupName), " s ") then _offset = 20 end -- Ship
		
		local _lead = getAliveUnits(Group.getByName(_groupName))[1]
		local _newewr = {
				name = Unit.getName(_lead), -- name of radar as set in MissionEditor
				radius = _radius, -- radarcoverage radius in meters
				altoffset = _offset, -- meter height above unit of the radar (higher radar antenna, higher number)
				filteragl = _filteragl, -- filter out units below this altitude in meter above ground level
				filterclosingvelocity = _filtercv -- filter out closing/leaving the radar slower than this in meter/second
			}
		if (Unit.getCoalition(_lead) == coalition.side.BLUE) then
			table.insert(gci.blueewrs, _newewr)
		else
			table.insert(gci.redewrs, _newewr)
		end
		env.info(string.format("%s added to EWRs", _groupName), false)
	end
	if string.find(string.lower(_groupName), "interceptor") then -- Finds group with Interceptor in name
		env.info(string.format("Non-dynamic Interceptor-group %s found",_groupName), false)
		
		-- Get speed setting
		local _ispeed = 370 -- Default M1.1
		if string.find(string.lower(_groupName), " z ") then _ispeed = 262 end -- M0.77
		if string.find(string.lower(_groupName), " x ") then _ispeed = 680 end -- M2
		if string.find(string.lower(_groupName), " y ") then _ispeed = 880 end -- M2.6
		
		-- Get altitude setting
		-- medium altitude is between 3000m and 9000m (USAF standard)
		local _ialt = 6000 -- Default medium altitude (20000ft)
		local _ialttype = "BARO" -- Default medium altitude barometric height
		if string.find(string.lower(_groupName), " n ") then -- Nap-of-the-earth (very low)
			_ialt = 100
			_ialttype = "RADIO"
		end
		if string.find(string.lower(_groupName), " ll ") then -- Low-low
			_ialt = 1000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hl ") then -- High-low
			_ialt = 2000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " lm ") then -- Low-medium
			_ialt = 4000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hm ") then -- High-medium
			_ialt = 8000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " lh ") then -- Low-High
			_ialt = 10000
			_ialttype = "BARO"
		end
		if string.find(string.lower(_groupName), " hh ") then -- High-High
			_ialt = 15000
			_ialttype = "BARO"
		end
		
		-- Get radar setting search radar (this will also enable engaging targets while enroute)
		local _searchradar = false -- Default false
		if string.find(string.lower(_groupName), " q ") then _searchradar = true end
		
		-- Get radar setting attack radar
		local _attackradar = true -- Default true
		if string.find(string.lower(_groupName), " s ") then _attackradar = false end
		
		-- Get engagement range setting
		local _engagementrange = 35000 -- Default attack-range (for AIM-7, R-27 equipped fighters)
		if string.find(string.lower(_groupName), " wvrb ") then _engagementrange = 2000 end -- WVR bad visibility
		if string.find(string.lower(_groupName), " wvrg ") then _engagementrange = 5000 end -- WVR good visibility
		if string.find(string.lower(_groupName), " bvrs ") then _engagementrange = 12000 end -- Very short-range BVR (ie R-13 or AIM-9 equipped, like MiG-21)
		if string.find(string.lower(_groupName), " bvre ") then _engagementrange = 20000 end -- Early radar guided (ie R-24 equipped fighters, like MiG-23)
		if string.find(string.lower(_groupName), " bvra ") then _engagementrange = 50000 end -- Active medium range radar guided (ie AIM-120, R-77)
		if string.find(string.lower(_groupName), " bvrl ") then _engagementrange = 90000 end -- Active long range radar guided (ie AIM-54, R-33)
		
		-- Get combat radius setting
		local _combatradius = 250000 -- Default combat-radius (ie from Vaziani to Kobuleti)
		if string.find(string.lower(_groupName), " sscr ") then _combatradius = 50000 end -- Short-range, ie base-defence only
		if string.find(string.lower(_groupName), " mscr ") then _engagementrange = 15000 end -- Medium short-range, ie from Sukhumi to Kobuleti
		if string.find(string.lower(_groupName), " mlcr ") then _engagementrange = 500000 end -- Medium long-range, ie from Novorossiysk to Nalchik
		if string.find(string.lower(_groupName), " vlcr ") then _engagementrange = 1000000 end -- Entire map
		
		local newsquadron = {
		airdromeId = 0, -- Homebase for the interceptorsquadron
		interceptspeed = _ispeed, -- Intecept targets at this speed in meter/second
		interceptalt = _ialt, -- Fly at this altitued while intercepting
		interceptalt_type = _ialttype,  -- Use this type of altitude when intercepting, "RADIO" or "BARO"
		egressspeed = 170, -- Fly in this speed when cruising/looking for targets/returning home
		egressalt = _ialt, -- Fly at this altitude
		egressalt_type = _ialttype,
		usesearchradar = _searchradar, -- Use radar when flying to interception-point
		useattackradar = _attackradar, -- Use radar when attacking target
		engagementrange = _engagementrange, -- Attack targets at this range in meters
		combatradius = _combatradius, -- Maximum range from starting point that the interceptor will fly
		
		flights = -- List of groups and flags to activate interceptor flights
		{
			{_groupName, "9999999"},
		}
		}
		local _interceptorgroup = Group.getByName(_groupName)
		if (table.getn(getAliveUnits(_interceptorgroup)) > 0) then
			if (_interceptorgroup:getCoalition() == coalition.side.BLUE) then
				table.insert(gci.blueinterceptorsquadrons, newsquadron)
			else
				table.insert(gci.redinterceptorsquadrons, newsquadron)
			end
		end
		--env.info(mist.utils.tableShow(_groupdata),true)
		--local _newgroupname = gci.dynAdd(_groupdata)
		--env.info(string.format("New group name: %s", _newgroupname), true)
		--local _clone = mist.cloneGroup(_groupName, true)
		
		--env.info(string.format("Group cloned: %s", _clone["name"]),true)
	end
	end
	, _groupName, _groupData)
	if (sts) then 
		 
	else 
		env.error(string.format("Iterating through units failed! %s", rtrn), true)
	end
end
							
							



-- Add eventhandler:
world.addEventHandler(gci.eventhandler)

mist.scheduleFunction (gci.radarsweep , {}, timer.getTime () + 10, 10) -- Radarsweep every 10 seconds

if (gci.verbose > 1) then 
	trigger.action.outText(string.format("GCI finished setup\n\nBlue air-units: %d \n\nRed air-units: %d \n\nTotal: %d",gci.blueairunitscount,gci.redairunitscount,gci.allairunitscount), 10) 
end

