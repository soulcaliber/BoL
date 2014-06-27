--[[
	VPrediction 2.0
]]

class 'VPrediction' --{
function VPrediction:__init()
	
	self.version = 2
	self.debug = false

	print("<font color=\"#FF0000\">[VPrediction "..self.version.."]: Loaded successfully!!</font>")
	--[[Use waypoints from the last 10 seconds]]
	self.WaypointsTime = 10

	self.TargetsVisible = {}
	self.TargetsWaypoints = {}
	self.TargetsImmobile = {}
	self.TargetsDashing = {}
	self.TargetsSlowed = {}
	self.DontShoot = {}
	
	self.WayPointManager = WayPointManager()
	self.WayPointManager.AddCallback(function(NetworkID) self:OnNewWayPoints(NetworkID) end)
	
	AdvancedCallback:bind('OnGainVision', function(unit) self:OnGainVision(unit) end)
	AdvancedCallback:bind('OnGainBuff', function(unit, buff) self:OnGainBuff(unit, buff) end)
	AdvancedCallback:bind('OnDash', function(unit, dash) self:OnDash(unit, dash) end)

	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
	AddTickCallback(function() self:OnTick() end)
	AddDrawCallback(function() self:OnDraw() end)

	self.BlackList = 
	{
		{name = "aatroxq", duration = 0.75} --[[4 Dashes, OnDash fails]]
	}
	
	--[[Spells that don't allow movement (durations approx)]]
	self.spells = {
		{name = "katarinar", duration = 1}, --Katarinas R
		{name = "drain", duration = 1}, --Fiddle W
		{name = "crowstorm", duration = 1}, --Fiddle R
		{name = "consume", duration = 0.5}, --Nunu Q
		{name = "absolutezero", duration = 1}, --Nunu R
		{name = "rocketgrab", duration = 0.5}, --Blitzcrank Q
		{name = "staticfield", duration = 0.5}, --Blitzcrank R
		{name = "cassiopeiapetrifyinggaze", duration = 0.5}, --Cassio's R
		{name = "ezrealtrueshotbarrage", duration = 1}, --Ezreal's R
		{name = "galioidolofdurand", duration = 1}, --Ezreal's R
		{name = "gragasdrunkenrage", duration = 1}, --""Gragas W
		{name = "luxmalicecannon", duration = 1}, --Lux R
		{name = "reapthewhirlwind", duration = 1}, --Jannas R
		{name = "jinxw", duration = 0.5}, --jinxW
		{name = "jinxr", duration = 0.6}, --jinxR
		{name = "missfortunebullettime", duration = 1}, --MissFortuneR
		{name = "shenstandunited", duration = 1}, --ShenR
		{name = "threshe", duration = 0.4}, --ThreshE
		{name = "threshrpenta", duration = 0.75}, --ThreshR
		{name = "infiniteduress", duration = 1}, --Warwick R
		{name = "meditate", duration = 1} --yi W
	}

	return self
end

--R_WAYPOINT new definition
load(Base64Decode("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"))()
--

--[[Track when we lose or gain vision over an enemy]]
function VPrediction:OnGainVision(unit)
	if unit.type == myHero.type then
		self.TargetsVisible[unit.networkID] = GetGameTimer()
	end
end

function VPrediction:OnGainBuff(unit, buff)
	if unit.type == myHero.type and (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_KNOCKUP or buff.type == BUFF_SUPPRESS) then
		self.TargetsImmobile[unit.networkID] = GetGameTimer() + buff.duration
	elseif unit.type == myHero.type and (buff.type == BUFF_SLOW or buff.type == BUFF_CHARM or buff.type == BUFF_FEAR or buff.type == BUFF_TAUNT) then
		self.TargetsSlowed[unit.networkID] = GetGameTimer() + buff.duration
	end
end

function VPrediction:OnDash(unit, dash)
	if unit.type == myHero.type then
		dash.endPos = dash.target and dash.target or dash.endPos
		self.TargetsDashing[unit.networkID] = dash
	end
end

function VPrediction:OnProcessSpell(unit, spell)
	if unit and unit.type == myHero.type then
		for i, s in ipairs(self.spells) do
			if spell.name:lower() == s.name then
				self.TargetsImmobile[unit.networkID] = GetGameTimer() + s.duration
			end
		end
		for i, s in ipairs(self.BlackList) do
			if spell.name:lower() == s.name then
				self.DontShoot[unit.networkID] = GetGameTimer() + s.duration
			end
		end
	end
end

function VPrediction:OnNewWayPoints(NetworkID)
	local object = objManager:GetObjectByNetworkId(NetworkID)
	if object and object.valid and object.networkID and object.type == myHero.type then
		if self.TargetsWaypoints[NetworkID] == nil then
			self.TargetsWaypoints[NetworkID] = {}
		end
		local WaypointsToAdd = WayPointManager:GetWayPoints(object)
		if WaypointsToAdd and #WaypointsToAdd >= 1 then
			--[[Save only the last waypoint (where the player clicked)]]
			table.insert(self.TargetsWaypoints[NetworkID], {unitpos = WaypointsToAdd[1] , waypoint = WaypointsToAdd[#WaypointsToAdd], time = GetGameTimer(), n = #WaypointsToAdd})
		end
	end
end

function VPrediction:IsImmobile(unit, delay, radius, speed, from)
	if self.TargetsImmobile[unit.networkID] then
		local ExtraDelay = speed == math.huge and  0 or (GetDistance(from, unit) / speed)
		if (self.TargetsImmobile[unit.networkID] + (radius / unit.ms)) > (GetGameTimer() + delay + ExtraDelay) then
			return true, unit
		end
	end
	return false, unit
end

function VPrediction:isSlowed(unit, delay, speed, from)
	if self.TargetsSlowed[unit.networkID] then
		if self.TargetsSlowed[unit.networkID] > (GetGameTimer() + delay + GetDistance(unit, from) / speed) then
			return false
		end
	end
	return false
end

function VPrediction:IsDashing(unit, delay, radius, speed, from)
	local TargetDashing = false
	local CanHit = false
	local Position

	if self.TargetsDashing[unit.networkID] then
		local dash = self.TargetsDashing[unit.networkID]
		if dash.endT >= GetGameTimer() then
			TargetDashing = true
			local t1, p1, t2, p2, dist = VectorMovementCollision(dash.startPos, dash.endPos, dash.speed, from, speed, delay + GetGameTimer() - dash.startT)
			t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - GetGameTimer() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - GetGameTimer() - delay)) and t2 or nil 
			local t = t1 and t2 and math.min(t1,t2) or t1 or t2
			if t then
				Position = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
				CanHit = true
            else
				Position = Vector(dash.endPos.x, 0, dash.endPos.z)
				CanHit = (unit.ms * (delay + GetDistance(from, Position)/speed - (dash.endT - GetGameTimer()))) < radius
			end
		end
	end
	return TargetDashing, CanHit, Position
end

function VPrediction:GetWaypoints(NetworkID, from, to)
	local Result = {}
	to = to and to or GetGameTimer()
	if self.TargetsWaypoints[NetworkID] then
		for i, waypoint in ipairs(self.TargetsWaypoints[NetworkID]) do
			if from <= waypoint.time  and to >= waypoint.time then
				table.insert(Result, waypoint)
			end
		end
	end
	return Result, #Result
end

function VPrediction:CountWaypoints(NetworkID, from, to)
	local R, N = self:GetWaypoints(NetworkID, from, to)
	return N
end

function WayPointManager:GetPathLength(wayPointList, startIndex, endIndex)
    local tDist = 0
    for i = math.max(startIndex or 1, 1), math.min(#wayPointList, endIndex or math.huge) - 1 do
        tDist = tDist + GetDistance(wayPointList[i], wayPointList[i + 1])
    end
    return tDist
end

--[[Calculate the hero position based on the last waypoints]]
function VPrediction:CalculateTargetPosition(unit, delay, radius, speed, from)
	local WayPoints = WayPointManager:GetWayPoints(unit)
	local Position, CastPosition
	
	--[[From AllClass's VipPrediction]]
	if #WayPoints == 1 then
		return Vector(WayPoints[1].x, 0, WayPoints[1].y), Vector(WayPoints[1].x, 0, WayPoints[1].y)
	elseif WayPointManager:GetPathLength(WayPoints, 1, #WayPoints) > unit.ms * delay then
		
		local tA = 0
		for i = 1, #WayPoints - 1 do
			local A, B = WayPoints[i], WayPoints[i+1]
			local t1, p1, t2, p2, D = VectorMovementCollision(A, B, unit.ms, Vector(from.x, from.z), speed, delay)
			local tB = tA + D / unit.ms
            t1, t2 = (t1 and 0 <= t1 and t1 <= (tB - tA)) and t1 or nil, (t2 and 0 <= t2 and t2 <= (tB - tA)) and t2 or nil
            local t = t1 and t2 and math.min(t1, t2) or t1 or t2
            if t then
            	Position = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)

            	if tA * unit.ms >= radius or D >= radius then
            		CastPosition = Position + radius * Vector(A.x - Position.x, 0, A.y - Position.z):normalized()
            	else
            		CastPosition = Position
            	end
            	break
           	end

           	if i == #WayPoints - 1 and unit.type ~= myHero.type then
           		Position = Vector(B.x, 0, B.y)
           		CastPosition = Position
           	end

			tA = tB
		end
	end

	if self:isSlowed(unit, 0, math.huge, from) and not self:isSlowed(unit, delay, speed, from) then
		CastPosition = Position
	end
	
	return Position, CastPosition
end

function VPrediction:MaxAngle(unit, currentwaypoint, from)
	local WPtable, n = self:GetWaypoints(unit.networkID, from)
	local Max = 0
	local CV = (Vector(currentwaypoint.x, 0, currentwaypoint.y) - Vector(unit))
		for i, waypoint in ipairs(WPtable) do
				local angle = Vector(0, 0, 0):angleBetween(CV, Vector(waypoint.waypoint.x, 0, waypoint.waypoint.y) - Vector(waypoint.unitpos.x, 0, waypoint.unitpos.y))
				if angle > Max then
					Max = angle
				end
		end
	return Max
end

function VPrediction:WayPointAnalysis(unit, delay, radius, range, speed, from)
	local Position, CastPosition, HitChance
	local SavedWayPoints = self.TargetsWaypoints[unit.networkID] and self.TargetsWaypoints[unit.networkID] or {}
	local CurrentWayPoints = WayPointManager:GetWayPoints(unit)
	local VisibleSince = self.TargetsVisible[unit.networkID] and self.TargetsVisible[unit.networkID] or GetGameTimer()
	
	HitChance = 1
	Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from)
	
	if self:CountWaypoints(unit.networkID, GetGameTimer() - 0.1) >= 1 or self:CountWaypoints(unit.networkID, GetGameTimer() - 1) == 1 then
		HitChance = 2
	end
	
	if self:CountWaypoints(unit.networkID, GetGameTimer() - 0.75) >= 2 then
		local angle = self:MaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], GetGameTimer() - 0.75)
		if angle > 70 then
			HitChance = 1
		elseif angle < 30 and self:CountWaypoints(unit.networkID, GetGameTimer() - 0.75) > 3 then
			HitChance = 2
		end
	end
	
	if self:CountWaypoints(unit.networkID, GetGameTimer() - 2) == 0 then
		HitChance = 2
	end
	
	--[[Out of range]]
	if ((GetDistance(myHero.visionPos, Position) > range) and (GetDistance(myHero, CastPosition) > range)) or (GetDistance(myHero.visionPos, unit) > range + self:GetHitBox(unit)) then
		HitChance = 1
	end
	
	--[[Angle too wide]]
	if Vector(from):angleBetween(Vector(unit), Vector(CastPosition)) > 60 then
		HitChance = 1
	end
	
	if #CurrentWayPoints == 1 then
		HitChance = 2
		CastPosition = Vector(CurrentWayPoints[#CurrentWayPoints].x, 0, CurrentWayPoints[#CurrentWayPoints].y)
		Position = CastPosition
	end
	
	if not Position or not CastPosition then
		HitChance = 0

		CastPosition = Vector(CurrentWayPoints[#CurrentWayPoints].x, 0, CurrentWayPoints[#CurrentWayPoints].y)
		Position = CastPosition
	end

	if #SavedWayPoints == 0 and (GetGameTimer() - VisibleSince) > 3 then
		HitChance = 2
	end
	
	return CastPosition, HitChance, Position
end

function VPrediction:GetBestCastPosition(unit, delay, radius, range, speed, from)
	assert(unit, "VPrediction: Target can't be nil")
	range = range and range or math.huge
	radius = radius == 0 and 1 or (radius + self:GetHitBox(unit)) * 0.8
	speed = speed and speed or math.huge
	from = from and from or Vector(myHero)
	delay = delay + GetLatency() / 2000 + GetDistance(unit.visionPos, unit) / (unit.ms)
	if range ~= math.huge and unit.ms > 350 then
		range = range - ((unit.ms - 350))
	end
	
	local Position, CastPosition, HitChance
	local TargetDashing, CanHitDashing, DashPosition = self:IsDashing(unit, delay, radius, speed, from)
	local TargetImmobile, ImmobilePos = self:IsImmobile(unit, delay, radius, speed, from)
	

	
	if unit.type ~= myHero.type then
		--[[TODO: improve minion prediction]]
		Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from)
		HitChance = 2
	else
		if self.DontShoot[unit.networkID] and self.DontShoot[unit.networkID] > GetGameTimer() then
			Position, CastPosition = Vector(unit.x, unit.y, unit.z),  Vector(unit.x, unit.y, unit.z)
			HitChance = 0
		elseif TargetImmobile then
			Position, CastPosition = ImmobilePos, ImmobilePos
			HitChance = 4
		elseif TargetDashing then
			if CanHitDashing then
				HitChance = 5
			else
				HitChance = 0
			end 
			Position, CastPosition = DashPosition, DashPosition
		else
			CastPosition, HitChance, Position = self:WayPointAnalysis(unit, delay, radius, range, speed, from)
		end
	end

	if unit.team ~= myHero.team and not ValidTarget(unit) then
		--[[TODO: check zhonyas, GA, Lissandra ult, Kayle ult, trynda ult, zilean ult]]
		HitChance = 0
	end

	return CastPosition, HitChance, Position
end


function VPrediction:GetCircularCastPosition(unit, delay, radius, range, speed, from)
	return self:GetBestCastPosition(unit, delay, radius, range, speed, from)
end

function VPrediction:GetLineCastPosition(unit, delay, radius, range, speed, from)
	return self:GetBestCastPosition(unit, delay, radius, range, speed, from)
end

function VPrediction:GetPredictedPos(unit, delay, speed, from)
	return self:GetBestCastPosition(unit, delay, 1, math.huge, speed, from)
end

function VPrediction:OnTick()
	--[[Delete the old saved Waypoints]]
	for NID, TargetWaypoints in pairs(self.TargetsWaypoints) do
		local i = 1 
		while i <= #self.TargetsWaypoints[NID] do
			if self.TargetsWaypoints[NID][i]["time"] + self.WaypointsTime < GetGameTimer() then
				table.remove(self.TargetsWaypoints[NID], i)
			else
				i = i + 1
			end
		end
	end
end

--[[Drawing functions for debug: ]]
function VPrediction:DrawSavedWaypoints(object, time)
	local WayPoints = self:GetWaypoints(object.networkID, GetGameTimer() - time)
	for i, waypoint in ipairs(WayPoints) do
		DrawCircle3D(waypoint.waypoint.x, myHero.y, waypoint.waypoint.y, 100, 2, ARGB(255, 255, 255, 255))
		DrawText3D(tostring(i), waypoint.waypoint.x, myHero.y, waypoint.waypoint.y, 13, ARGB(255, 255, 255, 255), true)
		DrawCircle3D(waypoint.unitpos.x, myHero.y, waypoint.unitpos.y, 100, 2, ARGB(255, 255, 0, 0))
	end
end

function VPrediction:DrawHitBox(object)
	DrawCircle3D(object.x, object.y, object.z, self:GetHitBox(object), 1, ARGB(255, 255, 255, 255))
	DrawCircle3D(object.visionPos.x, object.visionPos.y, object.visionPos.z, self:GetHitBox(object), 1, ARGB(255, 0, 255, 0))
end

function VPrediction:OnDraw()
	if self.debug then
		local target = GetEnemyHeroes()[1]
		self:DrawSavedWaypoints(target, 1)
		self:DrawHitBox(target)
		local CastPosition,  HitChance,  Position = self:GetCircularCastPosition(target, 600/1000, 70, 1000)
		if HitChance >= 2 then
			DrawCircle3D(CastPosition.x, myHero.y, CastPosition.z, 150, 1, ARGB(255, 0, 255, 0))
		end
	end
end

function VPrediction:GetHitBox(object)
	local hitboxTable = { ['HeimerTGreen'] = 50.0, ['Darius'] = 80.0, ['ZyraGraspingPlant'] = 20.0, ['HeimerTRed'] = 50.0, ['ZyraThornPlant'] = 20.0, ['Nasus'] = 80.0, ['HeimerTBlue'] = 50.0, ['SightWard'] = 1, ['HeimerTYellow'] = 50.0, ['Kennen'] = 55.0, ['VisionWard'] = 1, ['ShacoBox'] = 10, ['HA_AP_Poro'] = 0, ['TempMovableChar'] = 48.0, ['TeemoMushroom'] = 50.0, ['OlafAxe'] = 50.0, ['OdinCenterRelic'] = 48.0, ['Blue_Minion_Healer'] = 48.0, ['AncientGolem'] = 100.0, ['AnnieTibbers'] = 80.0, ['OdinMinionGraveyardPortal'] = 1.0, ['OriannaBall'] = 48.0, ['LizardElder'] = 65.0, ['YoungLizard'] = 50.0, ['OdinMinionSpawnPortal'] = 1.0, ['MaokaiSproutling'] = 48.0, ['FizzShark'] = 0, ['Sejuani'] = 80.0, ['Sion'] = 80.0, ['OdinQuestIndicator'] = 1.0, ['Zac'] = 80.0, ['Red_Minion_Wizard'] = 48.0, ['DrMundo'] = 80.0, ['Blue_Minion_Wizard'] = 48.0, ['ShyvanaDragon'] = 80.0, ['HA_AP_OrderShrineTurret'] = 88.4, ['Heimerdinger'] = 55.0, ['Rumble'] = 80.0, ['Ziggs'] = 55.0, ['HA_AP_OrderTurret3'] = 88.4, ['HA_AP_OrderTurret2'] = 88.4, ['TT_Relic'] = 0, ['Veigar'] = 55.0, ['HA_AP_HealthRelic'] = 0, ['Teemo'] = 55.0, ['Amumu'] = 55.0, ['HA_AP_ChaosTurretShrine'] = 88.4, ['HA_AP_ChaosTurret'] = 88.4, ['HA_AP_ChaosTurretRubble'] = 88.4, ['Poppy'] = 55.0, ['Tristana'] = 55.0, ['HA_AP_PoroSpawner'] = 50.0, ['TT_NGolem'] = 80.0, ['HA_AP_ChaosTurretTutorial'] = 88.4, ['Volibear'] = 80.0, ['HA_AP_OrderTurretTutorial'] = 88.4, ['TT_NGolem2'] = 80.0, ['HA_AP_ChaosTurret3'] = 88.4, ['HA_AP_ChaosTurret2'] = 88.4, ['Shyvana'] = 50.0, ['HA_AP_OrderTurret'] = 88.4, ['Nautilus'] = 80.0, ['ARAMOrderTurretNexus'] = 88.4, ['TT_ChaosTurret2'] = 88.4, ['TT_ChaosTurret3'] = 88.4, ['TT_ChaosTurret1'] = 88.4, ['ChaosTurretGiant'] = 88.4, ['ARAMOrderTurretFront'] = 88.4, ['ChaosTurretWorm'] = 88.4, ['OdinChaosTurretShrine'] = 88.4, ['ChaosTurretNormal'] = 88.4, ['OrderTurretNormal2'] = 88.4, ['OdinOrderTurretShrine'] = 88.4, ['OrderTurretDragon'] = 88.4, ['OrderTurretNormal'] = 88.4, ['ARAMChaosTurretFront'] = 88.4, ['ARAMOrderTurretInhib'] = 88.4, ['ChaosTurretWorm2'] = 88.4, ['TT_OrderTurret1'] = 88.4, ['TT_OrderTurret2'] = 88.4, ['ARAMChaosTurretInhib'] = 88.4, ['TT_OrderTurret3'] = 88.4, ['ARAMChaosTurretNexus'] = 88.4, ['OrderTurretAngel'] = 88.4, ['Mordekaiser'] = 80.0, ['TT_Buffplat_R'] = 0, ['Lizard'] = 50.0, ['GolemOdin'] = 80.0, ['Renekton'] = 80.0, ['Maokai'] = 80.0, ['LuluLadybug'] = 50.0, ['Alistar'] = 80.0, ['Urgot'] = 80.0, ['LuluCupcake'] = 50.0, ['Gragas'] = 80.0, ['Skarner'] = 80.0, ['Yorick'] = 80.0, ['MalzaharVoidling'] = 10.0, ['LuluPig'] = 50.0, ['Blitzcrank'] = 80.0, ['Chogath'] = 80.0, ['Vi'] = 50, ['FizzBait'] = 0, ['Malphite'] = 80.0, ['EliseSpiderling'] = 1.0, ['Dragon'] = 100.0, ['LuluSquill'] = 50.0, ['Worm'] = 100.0, ['redDragon'] = 100.0, ['LuluKitty'] = 50.0, ['Galio'] = 80.0, ['Annie'] = 55.0, ['EliseSpider'] = 50.0, ['SyndraSphere'] = 48.0, ['LuluDragon'] = 50.0, ['Hecarim'] = 80.0, ['TT_Spiderboss'] = 200.0, ['Thresh'] = 55.0, ['ARAMChaosTurretShrine'] = 88.4, ['ARAMOrderTurretShrine'] = 88.4, ['Blue_Minion_MechMelee'] = 65.0, ['TT_NWolf'] = 65.0, ['Tutorial_Red_Minion_Wizard'] = 48.0, ['YorickRavenousGhoul'] = 1.0, ['SmallGolem'] = 80.0, ['OdinRedSuperminion'] = 55.0, ['Wraith'] = 50.0, ['Red_Minion_MechCannon'] = 65.0, ['Red_Minion_Melee'] = 48.0, ['OdinBlueSuperminion'] = 55.0, ['TT_NWolf2'] = 50.0, ['Tutorial_Red_Minion_Basic'] = 48.0, ['YorickSpectralGhoul'] = 1.0, ['Wolf'] = 50.0, ['Blue_Minion_MechCannon'] = 65.0, ['Golem'] = 80.0, ['Blue_Minion_Basic'] = 48.0, ['Blue_Minion_Melee'] = 48.0, ['Odin_Blue_Minion_caster'] = 48.0, ['TT_NWraith2'] = 50.0, ['Tutorial_Blue_Minion_Wizard'] = 48.0, ['GiantWolf'] = 65.0, ['Odin_Red_Minion_Caster'] = 48.0, ['Red_Minion_MechMelee'] = 65.0, ['LesserWraith'] = 50.0, ['Red_Minion_Basic'] = 48.0, ['Tutorial_Blue_Minion_Basic'] = 48.0, ['GhostWard'] = 1, ['TT_NWraith'] = 50.0, ['Red_Minion_MechRange'] = 65.0, ['YorickDecayedGhoul'] = 1.0, ['TT_Buffplat_L'] = 0, ['TT_ChaosTurret4'] = 88.4, ['TT_Buffplat_Chain'] = 0, ['TT_OrderTurret4'] = 88.4, ['OrderTurretShrine'] = 88.4, ['ChaosTurretShrine'] = 88.4, ['WriggleLantern'] = 1, ['ChaosTurretTutorial'] = 88.4, ['TwistedLizardElder'] = 65.0, ['RabidWolf'] = 65.0, ['OrderTurretTutorial'] = 88.4, ['OdinShieldRelic'] = 0, ['TwistedGolem'] = 80.0, ['TwistedSmallWolf'] = 50.0, ['TwistedGiantWolf'] = 65.0, ['TwistedTinyWraith'] = 50.0, ['TwistedBlueWraith'] = 50.0, ['TwistedYoungLizard'] = 50.0, ['Summoner_Rider_Order'] = 65.0, ['Summoner_Rider_Chaos'] = 65.0, ['Ghast'] = 60.0, ['blueDragon'] = 100.0, }
		return (hitboxTable[object.charName] ~= nil and hitboxTable[object.charName] ~= 0) and hitboxTable[object.charName]  or 65
end

--}