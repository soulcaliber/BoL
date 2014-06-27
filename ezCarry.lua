class "ezFreePrediction"

function ezFreePrediction:__init()
	self.version = 1.0
	self.heroDirDB = {}
	
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		
		if hero.team ~= player.team then
			self.heroDirDB[hero.name] = {lastVec = Vector(0,0,0), dir = Vector(0,0,0), lastAngle = 0, index = i}
		end
	end	
	
	AddTickCallback(function() self:OnTick() end)
end

function ezFreePrediction:OnTick()
	self:UpdateHeroDirection()	
end

function ezFreePrediction:GetVersion()
	return self.version
end

function ezFreePrediction:UpdateHeroDirection ()
	
	for heroName, heroObj in pairs(self.heroDirDB) do
		local hero = heroManager:GetHero(heroObj.index)
		local currentVec = Vector(hero)
		local dir = (currentVec - heroObj.lastVec)
		
		if dir ~= Vector(0,0,0) then
			dir = dir:normalized()
		end
		
		heroObj.lastAngle = heroObj.dir:dotP( dir )
		heroObj.dir = dir
		heroObj.lastVec = currentVec
	end
end

function ezFreePrediction:GetCollisionTime (targetPos, targetDir, targetSpeed, sourcePos, projSpeed )
	local velocity = targetDir * targetSpeed
	
	local velocityX = velocity.x
	local velocityY = velocity.z
	
	local relStart = targetPos - sourcePos
	
	local relStartX = relStart.x
	local relStartY = relStart.z

	local a = velocityX * velocityX + velocityY * velocityY - projSpeed * projSpeed
	local b = 2 * velocityX * relStartX + 2 * velocityY * relStartY
	local c = relStartX * relStartX + relStartY * relStartY
	
	local disc = b * b - 4 * a * c
	
	if disc >= 0 then
		local t1 = -( b + math.sqrt( disc )) / (2 * a )
		local t2 = -( b - math.sqrt( disc )) / (2 * a )
		
		
		if t1 and t2 and t1 > 0 and t2 > 0 then
			if t1 > t2 then
				return t2
			else
				return t1
			end
		elseif t1 and t1 > 0 then
			return t1
		elseif t2 and t2 > 0 then
			return t2
		end
	end
	
	return nil
end

function ezFreePrediction:GetPrediction (windupTime, projectileSpeed, target)
	
	local heroObj = self.heroDirDB[target.name]
	
	if heroObj.dir ~= Vector(0,0,0) then
	
	if heroObj.lastAngle and heroObj.lastAngle < .8 then
		return nil
	end
	
	
	local windupPos = Vector(target) + heroObj.dir * (target.ms * windupTime/1000)
	local timeElapsed = self:GetCollisionTime(windupPos, heroObj.dir, target.ms, myHero, projectileSpeed )
	
	if timeElapsed == nil then
		return nil
	end

	return Vector(target) + heroObj.dir * target.ms * (timeElapsed + windupTime/1000)
	
	end
	
	return Vector(target)
end
---------------------------------------------------------
class 'ezBuffTracker'

function ezBuffTracker:__init()
	self.version = 1.0
	self.heroData = {}
	
	for i=1, heroManager.iCount do
		local hero = heroManager:getHero(i)	
		
		self.heroData[hero.name] = {buffs = {}}
	end	
	
	AdvancedCallback:bind('OnGainBuff', function(unit, buff) self:OnGainBuff(unit, buff) end)
    AdvancedCallback:bind('OnLoseBuff', function(unit, buff) self:OnLoseBuff(unit, buff) end)
    AdvancedCallback:bind('OnUpdateBuff', function(unit, buff) self:OnUpdateBuff(unit, buff) end)
end

function ezBuffTracker:GetVersion()
	return self.version
end

function ezBuffTracker:getHeroBuffs (hero)
	return self.heroData[hero.name] and self.heroData[hero.name].buffs or nil
end

function ezBuffTracker:isBuffCC (buff)
	return (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_KNOCKUP or buff.type == BUFF_SUPPRESS)
end

function ezBuffTracker:isBuffCC_Cleanse (buff)
	return (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_CHARM or buff.type == BUFF_FEAR or buff.type == BUFF_TAUNT )
end

function ezBuffTracker:isBuffCC_QSS (buff)
	return (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_CHARM or buff.type == BUFF_FEAR or buff.type == BUFF_TAUNT or buff.type == BUFF_SUPPRESS )
end

function ezBuffTracker:targetHasBuff (target, buffName, duration)
	if buffName == nil then
		return false
	end

	if self.heroData[target.name] then
		local buff = self.heroData[target.name].buffs[buffName]
		
		if buff then
			if duration then
				return GetTick() + duration < buff.endTime
			else
				return GetTick() < buff.endTime
			end
		else
			return false
		end		
	else
		print("Error: Target " .. target.name .. " not found in hero database (ezBuffTracker)")
		return nil
	end
end

function ezBuffTracker:targetHasBuffEx (target, buffName, duration)
	if buffName == nil then
		return false
	end

	if self.heroData[target.name] then
	
		for name, buff in pairs(self.heroData[target.name].buffs) do	
			
		if name:find(buffName) then
		
			if duration and GetTick() + duration < buff.endTime then
				return true
			elseif GetTick() < buff.endTime then
				return true
			end
		end
		
		end
		
		return false				
	else
		print("Error: Target " .. target.name .. " not found in hero database (ezBuffTracker)")
		return nil
	end
end

function ezBuffTracker:OnGainBuff(hero, buff)
	if hero.type == 'obj_AI_Hero' then
		if self.heroData[hero.name] then	
			self.heroData[hero.name].buffs[buff.name] = { buff = buff, startTime = GetTick(), endTime = GetTick() + buff.duration*1000 }
			--print("Gain: " .. buff.name)
		end
	end
end

function ezBuffTracker:OnUpdateBuff(hero, buff)
	if hero.type == 'obj_AI_Hero' then
		if self.heroData[hero.name] then	
			self.heroData[hero.name].buffs[buff.name] = { buff = buff, startTime = GetTick(), endTime = GetTick() + buff.duration*1000 }
			
			--print("Update: " .. buff.name .. " " .. buff.stack)
		end
	end
end

function ezBuffTracker:OnLoseBuff(hero, buff)
	if hero.type == 'obj_AI_Hero' then
		if self.heroData[hero.name] then	
			self.heroData[hero.name].buffs[buff.name] = nil
			--print("Lose: " .. buff.name)
		end
	end
end

----------------AUTO Download------------------------------

function DownloadScript (scriptName, scriptVersion, url, scriptPath)
	local UPDATE_TMP_FILE = LIB_PATH.. scriptName .. "Tmp.txt"
	
	DownloadFile(url, UPDATE_TMP_FILE, 
		function ()
		
		file = io.open(UPDATE_TMP_FILE, "rb")
		if file ~= nil then
        downloadContent = file:read("*all")
        file:close()
        os.remove(UPDATE_TMP_FILE)
		end
		
	
	if downloadContent then
		
		file = io.open(scriptPath, "w")
        
		if file then
            file:write(downloadContent)
            file:flush()
            file:close()
            print("Successfully updated " .. scriptName .. " to Version " .. scriptVersion)
			print("Please press F9 to reload script.")
        else
            print("Error updating!")
        end
		
	end
	
		
	end)	
end

if FileExist(LIB_PATH.."ezCollision.lua") == false then
	local url = "https://bitbucket.org/Xgs/bol/raw/master/Common/ezCollision.lua"
	local version = "Current"
	
	print("ezCollision not found! Downloading ezCollision...")
	DelayAction(function()
		DownloadScript ("ezCollision", version, url, LIB_PATH.."ezCollision.lua")
		end,1)
	return
end

if FileExist(LIB_PATH.."ezLibrary.lua") == false then
	local url = "https://bitbucket.org/Xgs/bol/raw/master/Common/ezLibrary.lua"
	local version = "Current"
			
	print("ezLibrary not found! Downloading ezLibrary...")
	DelayAction(function()
		DownloadScript ("ezLibrary", version, url, LIB_PATH.."ezLibrary.lua")
		end,1)
	return
end

if FileExist(LIB_PATH.."VPrediction.lua") == false then
	local url = "https://bitbucket.org/Xgs/bol/raw/master/Common/VPrediction.lua"
	local version = "Current"
			
	print("VPrediction not found! Downloading VPrediction...")
	DelayAction(function()
		DownloadScript ("VPrediction", version, url, LIB_PATH.."VPrediction.lua")
		end,1)
	return
end

----------------AUTO Download------------------------------

require "ezCollision"
require "ezLibrary"
--require "ezBuffTracker"

if VIP_USER then
require "VPrediction"
end

--require "Collision"

local sVersion = 2.72

local castSpellKey = 32
local castHarassKey = string.byte("C")
local castLastHitKey = string.byte("V")

local incomingSpells = {}

local spellKeyStr = { [_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R" } 

local me = {detectAutoTime = 0, nextBasicTime = 0, lastWindup = 0, windupTime = function () return 250 end, lastAACommand = 0, nextAnimationTime = 0, holdPos = false, lastCommandTime = 0}
local heroDB = {}
local currentTargetName = nil
local wayPointManager = nil

local ezBuffTracker = ezBuffTracker()

local ezLibrary = ezLibrary()
local champions = ezLibrary:GetChampionInfo()

local myChampion = champions[myHero.charName]

local collisionManager = ezCollision()
local items = champions["Items"]
local summonerSpells = champions["Summoners"]

local skillShots = {[myHero.charName .. "AutoAttack"] = { name = "AutoAttack", spellName = myHero.charName .. "AutoAttack", isTargeted = true, range = myHero.range} }

local markedMinion = {}
local enemyMinions = {}

local VP = nil
local ezFreePred = nil

----------------AUTO Update------------------------------

function ReadLastUpdateTime ()

	local updateTimeFile = LIB_PATH.."ezUpdateTime"
	
	file = io.open(updateTimeFile, "rb")
	if file ~= nil then
    content = file:read("*all")
    file:close()
	
	return tonumber(content)
	end
	
	return 0
end

function WriteLastUpdateTime ()
	local updateTimeFile = LIB_PATH.."ezUpdateTime"
	
	file = io.open(updateTimeFile, "w")
     
	if file then
        file:write(os.time())
        file:flush()
        file:close()
    end
end

function CheckForUpdates ()
	
	local lastUpdateTime = ReadLastUpdateTime()
			
	if true then
	--if os.time()-lastUpdateTime > 86400 and os.time() > lastUpdateTime then --a day has passed
		
	local URL = "https://bitbucket.org/Xgs/bol/raw/master/Versions.txt"
	local UPDATE_TMP_FILE = LIB_PATH.."TmpVersions.txt"
	
	DownloadFile(URL, UPDATE_TMP_FILE, 
	function ()
		file = io.open(UPDATE_TMP_FILE, "rb")
		if file ~= nil then
        versionTextContent = file:read("*all")
        file:close()
        os.remove(UPDATE_TMP_FILE)
		end
	
	if versionTextContent then
		local url = "https://bitbucket.org/Xgs/bol/raw/master/Common/ezLibrary.lua"
		local version = ezLibrary:GetVersion()
		Update(versionTextContent, "ezLibrary", version, url, LIB_PATH.."ezLibrary.lua")
				
		url = "https://bitbucket.org/Xgs/bol/raw/master/Common/ezCollision.lua"
		version = collisionManager:GetVersion()
		Update(versionTextContent, "ezCollision", version, url, LIB_PATH.."ezCollision.lua")
			
		url = "https://bitbucket.org/Xgs/bol/raw/master/ezCarry.lua"
		Update(versionTextContent, "ezCarry", sVersion, url, SCRIPT_PATH.."ezCarry.lua")
	end
		
	end)
	
	WriteLastUpdateTime()
	
	end	
end
	
function Update(versionText, scriptName, scriptVersion, url, scriptPath)
	local content = versionText
	
	--print("Checking updates for " .. scriptName .. "...")
	
    if content then		
        tmp, sstart = string.find(content, "\"" .. scriptName .. "\" : \"")
        if sstart then
            send, tmp = string.find(content, "\"", sstart+1)
        end
		
        if send then
            Version = tonumber(string.sub(content, sstart+1, send-1))
        end
		
		if (Version ~= nil) and (Version > scriptVersion) then 
		
		print("Found update for " .. scriptName .. ", downloading...")
		DelayAction(DownloadScript,2,{scriptName, Version, url, scriptPath})
		
			
        elseif (Version ~= nil) and (Version <= scriptVersion) then
            --print("No updates found. Latest Version: " .. Version)
        end
    end
end

----------------AUTO Update------------------------------


local ezSkillShot = nil

if champions[myHero.charName] and champions[myHero.charName].skillshots then		
	for _, skill in pairs(champions[myHero.charName].skillshots) do
		if skill.spellKey then
		
		skillShots[skill.name] = skill
		end
	end
end

if skillShots == nil then return end	

function UpdateHeroDirection ()

	for i=1, heroManager.iCount do
	local hero = heroManager:getHero(i)	
	local heroObj = GetHeroByName(hero.name)
	
	--[[
	if hero.team == player.team then
		if heroObj == nil then
			heroDB[hero.name] = hero
		end
	end
	--]]
	
	if hero.team == TEAM_ENEMY then
		if heroObj == nil then
			heroDB[hero.name] = hero
			heroDB[hero.name].lastPosVec = Vector(hero.x,hero.y,hero.z)
			heroDB[hero.name].moveSpeed = hero.ms
			heroDB[hero.name].averageDist = 0
			heroDB[hero.name].averageDirTime = 0
			heroDB[hero.name].lastChangedPos = Vector(hero.x,hero.y,hero.z)
			heroDB[hero.name].cc = {}
			heroDB[hero.name].dash = {}
			heroDB[hero.name].closestEnemy = {}
			heroDB[hero.name].closestEnemyDistance = 0
		else
			if ValidTarget(hero) then
			local currentVec = Vector(hero.x,hero.y,hero.z)

			heroObj.directionVec = (currentVec - heroObj.lastPosVec):normalized()

			if (currentVec - heroObj.lastPosVec) == Vector(0,0,0) then
				heroObj.directionVec = Vector(0,0,0)
			end
			
			if heroObj.directionVec ~= Vector(0,0,0) --and hero.name == myHero.name
				and heroObj.waypoints and #heroObj.waypoints > 1 then
			
			local vecDiff = Vector(heroObj.waypoints[2].x, 0, heroObj.waypoints[2].y) - Vector(heroObj.waypoints[1].x, 0, heroObj.waypoints[1].y)
			local dir = vecDiff:normalized()
			
				if heroObj.lastChangedDir == nil or heroObj.lastChangedDir:dotP( dir ) < .80 then
				
				if heroObj.lastChangedDir ~= nil and heroObj.lastChangedDirTime ~= nil then
				heroObj.averageDist = (1-1/3) * heroObj.averageDist + (1/3) * GetDistance(heroObj.lastChangedPos, currentVec)
				heroObj.averageDirTime = (1-1/3) * heroObj.averageDirTime + (1/3) * (GetTick() - heroObj.lastChangedDirTime)		
				--print("Average Dist: " .. heroObj.averageDist .. ", Average Time: " .. heroObj.averageDirTime)
				heroObj.lastChangedDirCompare = heroObj.lastChangedDir:dotP( dir )
				end
				
				
				heroObj.lastChangedPos = currentVec
				heroObj.lastChangedDir = dir
				heroObj.lastChangedDirTime = GetTick()
				end
				
			elseif heroObj.directionVec == Vector(0,0,0) then
				heroObj.lastChangedDirTime = GetTick()
			end
			
			--running away time
			local nextLocation = currentVec + heroObj.directionVec * hero.ms
			local distDiff = GetDistance(nextLocation, myHero) - GetDistance(currentVec, myHero)
			
					
			if distDiff/hero.ms  < .3 then
				heroObj.lastRunAwayTime = GetTick()
			end
			
			
			heroObj.lastPosVec = currentVec
			heroObj.moveSpeed = hero.ms
			heroObj.lastUpdateTime = GetTick()
			heroObj.lastUpdatePos = currentVec
			heroObj.waypoints = wayPointManager:GetWayPoints(hero)			
			heroObj.closestEnemy, heroObj.closestEnemyDistance = GetClosestEnemyChampion(hero)
			
			if heroObj.waypoints and #heroObj.waypoints > 1 then
			local vecDiff = Vector(heroObj.waypoints[2].x, heroObj.lastPosVec.y, heroObj.waypoints[2].y) - heroObj.lastPosVec
			local heroDir = vecDiff:normalized()
	
			heroObj.waypointDir = heroDir
			end
			
			
			
			else
			
			if heroObj.lastUpdateTime then
			local timeElapsed = GetTick() - heroObj.lastUpdateTime
			heroObj.lastPosVec = heroObj.lastUpdatePos + heroObj.directionVec * (heroObj.moveSpeed * timeElapsed/1000)
			
			end
			
			heroObj.isDead = hero.dead
			
			end
			
			
		end
	end
		
	end
end

function GetClosestEnemyChampion(hero)
	local minDistance = math.huge
	local rHero = nil
	
	for i=1, heroManager.iCount do
		local tHero = heroManager:getHero(i)
		local dist = GetDistance(hero,tHero)
		
		if dist < minDistance and hero.team ~= tHero.team
			and ValidTarget(tHero) then
			rHero = tHero
			minDistance = dist
		end
	end
	
	return rHero, minDistance
end

function GetPathLength(wayPointList, startIndex, endIndex)
    local tDist = 0
    for i = math.max(startIndex or 1, 1), math.min(#wayPointList, endIndex or math.huge) - 1 do
        tDist = tDist + GetDistance(wayPointList[i], wayPointList[i + 1])
    end
    return tDist
end

function OnDraw()
	for skillname, skillShot in pairs(skillShots) do
	
	local currentTarget = GetTarget()
	local trueRange = GetTrueRange(skillShot)
	
	--[[
	if skillShot.params.DrawCastRange and ezSkillShot[myHero.charName .. "Settings"].CheckInRange and currentTarget and currentTarget.type == 'obj_AI_Hero' then
		local timeWhenHit = (skillShot.projectileSpeed and (skillShot.range + GetDistance(myHero, myHero.minBBox))/(skillShot.projectileSpeed/1000) or 0) + (skillShot.spellDelay or 0)
		DrawCircle(myHero.x, myHero.y,myHero.z, trueRange - currentTarget.ms * timeWhenHit/1000, 0x19A712)
	end
	--]]
	
	if skillShot.params.DrawRange then
		DrawCircle(myHero.x, myHero.y,myHero.z, trueRange, 0x19A712)
		
		if skillShot.name == "AutoAttack" then
		DrawCircle(myHero.x, myHero.y,myHero.z, ezSkillShot[myHero.charName .. "Settings"].OrbwalkHoldZone, 0xFFFFFF)
		end
	end
	
		
	
	end
	
	if ezSkillShot[myHero.charName .. "Settings"].DrawSelected and ezSkillShot[myHero.charName .. "Settings"].currentTarget then
		local c = ezSkillShot[myHero.charName .. "Settings"].currentTarget
		
		for j=0, 5 do
			if ezSkillShot[myHero.charName .. "Settings"]["FollowTarget"] then
			DrawCircle(c.x, c.y,c.z, 75+myHero.range + j, 0x00FF00)
			else
			DrawCircle(c.x, c.y,c.z, 100 + j, 0x00FF00)
			end
		end
	end
	
	
	
	
	--[[
		for _, heroObj in pairs(heroDB) do
			if heroObj.dash.endTime then
				DrawCircle(heroObj.dash.from.x, heroObj.dash.from.y,heroObj.dash.from.z, 50, 0x19A712)			
				DrawCircle(heroObj.dash.to.x, heroObj.dash.to.y,heroObj.dash.to.z, 50, 0x19A712)
			end
		end
	--]]
	
	if ezSkillShot.Info.DrawEnemyPos then
	
	for i=1, heroManager.iCount do
	local hero = heroManager:getHero(i)	
		if hero.team == TEAM_ENEMY then
		
		local currentTarget = GetHeroByName(hero.name)
		
		
		if currentTarget and currentTarget.waypointDir then
			predictDelayPos = currentTarget.lastPosVec + currentTarget.waypointDir * currentTarget.moveSpeed * 250/1000
			DrawCircle(predictDelayPos.x, predictDelayPos.y, predictDelayPos.z, 100, 0xFFFFFF)
		end
		
		--[[
		if currentTarget and currentTarget.waypointDir and GetTarget() and GetTarget().name == hero.name then
			local point = currentTarget.lastPosVec + (Vector(myHero) - currentTarget.lastPosVec):normalized() * 50
			local rotPoint = RotateAroundPoint(30, hero, point)
			DrawCircle(rotPoint.x, rotPoint.y, rotPoint.z, 100, 0xFFFFFF)
		end
		--]]
					
		end
	end
	
	end
	
	if ezSkillShot.Info.PrintBuffs then
	OnDrawBuffs()
	end
	
	if ezSkillShot.Info.PrintSkillName then
	OnDrawSkillName()
	end
	
	if ezSkillShot.Info.PrintIncomingSpells then
	OnDrawIncomingSpells()
	end
	
	
	if ezSkillShot.Info.DrawInfoRangeCircle then
		if ezSkillShot.Info.InfoCircleFollow then
		DrawCircle(mousePos.x, mousePos.y, mousePos.z, ezSkillShot.Info.InfoCircleRange, 0x00FF00)
		else
		DrawCircle(myHero.x, myHero.y, myHero.z, ezSkillShot.Info.InfoCircleRange, 0x00FF00)
		end
	end
	
	--OnDrawSkillShotNames()
end

function OnDrawIncomingSpells ()
	local topOffset = 150
	local leftOffset = 100
	local fontSize = 20
	
	local count = 0
	for key, details in pairs(incomingSpells) do
		--DrawText(details.spell.name .. " : " .. details.dmg, fontSize, leftOffset, topOffset, 0xFF00FF00)
		
		--topOffset = topOffset + 15
		count = count + 1
	end
	
	DrawText("Count: " .. count, fontSize, leftOffset, topOffset, 0xFF00FF00)
end	
	
function OnDrawSkillName ()
	local topOffset = 150
	local leftOffset = 100
	local fontSize = 20
	
	
	local cTarget = GetTarget()
	
	if not cTarget then
		cTarget = myHero
	end
	
	DrawText("Q: " .. cTarget:GetSpellData(_Q).name .. " - " .. cTarget:GetSpellData(_Q).currentCd, fontSize, leftOffset, topOffset, 0xFF00FF00)
	topOffset = topOffset + 15
	DrawText("W: " .. myHero:GetSpellData(_W).name, fontSize, leftOffset, topOffset, 0xFF00FF00)
	topOffset = topOffset + 15
	DrawText("E: " .. myHero:GetSpellData(_E).name, fontSize, leftOffset, topOffset, 0xFF00FF00)
	topOffset = topOffset + 15
	DrawText("R: " .. myHero:GetSpellData(_R).name, fontSize, leftOffset, topOffset, 0xFF00FF00)
	topOffset = topOffset + 15
end

function OnDrawSkillShotNames ()
local topOffset = 150
	local leftOffset = 100
	local fontSize = 20

	
	
	for name, skillShot in pairs(skillShots) do
		DrawText(name, fontSize, leftOffset, topOffset, 0xFF00FF00)
		topOffset = topOffset + 15
	end
end

function OnDrawBuffs ()
	local topOffset = 150
	local leftOffset = 100
	local fontSize = 20

	local cTarget = GetTarget()
	
	if not cTarget then
		cTarget = myHero
	end
	
	
	for i=1, heroManager.iCount do
	local hero = heroManager:getHero(i)	
		if cTarget and cTarget.name == hero.name then
			
			DrawText("Hero: " .. hero.name, fontSize, leftOffset, topOffset, 0xFF00FF00)
			topOffset = topOffset + 15
			
			local buffs = ezBuffTracker:getHeroBuffs(cTarget)
						
			for buffName, buff in pairs(buffs) do
			
			local tBuff = buff.buff
			
			if BuffIsValid(tBuff) then			
			
			local text = "Buff name: " .. tBuff.name .. (tBuff.stack and " Buff stack: " .. tBuff.stack or " ")
			
			DrawText(text, fontSize, leftOffset, topOffset, 0xFF00FF00)
			topOffset = topOffset + 15
			end
		
			
			end
			topOffset = topOffset + 30
		end
	end
end

function GetHeroByName (name)
	if name == nil then return nil end
	
	return heroDB[name]
end

function GetEffectiveArea (skillShot, hero)
	if skillShot.type == "LINE" then
		return skillShot.radius + GetDistance(hero,hero.minBBox)
	else
		return skillShot.radius
	end
end

function PredictHeroMovement (hero, timeElapsed, skillShot, settings)

	--local timeElapsed = GetSpellTimeWhenHit (projectileSpeed2, spellDelay2, myHero, hero) - GetTick()
	
	local width = skillShot.radius
	local skillShotType = skillShot.type
	local skillShotDelay = skillShot.spellDelay
	local skillShotSpeed = skillShot.projectileSpeed
	
	local effectiveArea = GetEffectiveArea (skillShot, hero)

	local predictedPos = hero.lastPosVec + hero.directionVec * (hero.moveSpeed * timeElapsed/1000)
	local predictDist = GetDistance(hero.lastPosVec, predictedPos)
	
	local reactionTime = timeElapsed - (settings.IgnoreDelay or 0)

	--print(timeElapsed .. " vs " .. timeWhenHit1)
	
	if hero.isDead then return nil end
	
	--if true then return predictedPos end
	
	if settings.Instant then
		return predictedPos
	end
	
	if hero.waypoints and #hero.waypoints > 1 then
	local vecDiff = Vector(hero.waypoints[2].x, hero.lastPosVec.y, hero.waypoints[2].y) - hero.lastPosVec
	local heroDir = vecDiff:normalized()
	
	predictedPos = hero.lastPosVec + heroDir * (hero.moveSpeed * timeElapsed/1000)
	end
		
	local waypointDist = nil
	
	if hero.waypoints ~= nil and #hero.waypoints > 1 then
		waypointDist = GetPathLength(hero.waypoints, 1, 2)
	end
	
	--is Stunned/Rooted/Knocked Up
	if settings.CC and hero.cc then
		for buffname, buffTime in pairs(hero.cc) do
					
			if buffTime - GetTick() + effectiveArea/(hero.moveSpeed/1000) > timeElapsed then
			--print(buffTime - GetTick() + width/(hero.moveSpeed/1000))
				return hero.lastPosVec
			elseif GetTick() - buffTime > 0 then
				hero.cc[buffname] = nil			
			end
		end	
	end
	
	--is Dashing
	if settings.Dash and hero.dash.endTime then
		
		local vecDiff = hero.dash.to - hero.dash.from
		local heroDir = vecDiff:normalized()
		
		local skillShotDelay = skillShot.spellDelay + GetLatency()/2
		
		--local predictedDashPos = hero.lastPosVec - heroDir * width --hero.dash.speed * skillShotDelay/1000
		local predictedDashPos = hero.dash.from + heroDir * hero.dash.speed * skillShotDelay/1000
		
		
		local timeWhenHit = skillShotDelay

		if skillShotSpeed then
			local timeWhenCollide = GetTimeProjectileCollide(predictedDashPos, heroDir, hero.dash.speed, Vector(myHero), skillShotSpeed)
			
			if timeWhenCollide then
				timeWhenHit = skillShotDelay + timeWhenCollide * 1000
			end			
		end		
			
		if skillShotSpeed and timeWhenHit > skillShotDelay and hero.dash.endTime - GetTick() + effectiveArea/(hero.moveSpeed/1000) > timeWhenHit then			
		--if  hero.dash.endTime - GetTick() > 0 then
		--print("true" .. timeWhenHit )
			return hero.dash.from + heroDir * (hero.dash.speed * timeWhenHit/1000)
			--return hero.dash.from + heroDir * (hero.dash.speed * 250/1000)
		elseif skillShotSpeed == nil and hero.dash.endTime - GetTick() + effectiveArea/(hero.moveSpeed/1000) > skillShotDelay then
			return hero.dash.from + heroDir * (hero.dash.speed * skillShotDelay/1000)
		elseif hero.dash.endTime - GetTick() > 0 then
			return hero.dash.to
		elseif GetTick() - hero.dash.endTime > 0 then
			hero.dash = {}	
		end
	end
			
	--Attack Animation Delay
	if settings.Animation and hero.windupFinishTime and hero.windupFinishTime - GetTick() + effectiveArea/(hero.moveSpeed/1000) > reactionTime then
		return hero.lastPosVec
	end
	
	--Walking in straight line for a long time
	if settings.NoChangeDir and hero.lastChangedDirTime and GetTick() - hero.lastChangedDirTime > 850 then
		--return hero.lastPosVec + hero.directionVec * (hero.moveSpeed * timeElapsed/1000 - (width or 0)/2)
		return predictedPos
	end
	
	
	--Facing straight at you
	if settings.SmallDirDeg and skillShotType == "LINE"
		and hero.waypoints and #hero.waypoints > 1
		and 250 + effectiveArea/(hero.moveSpeed/1000) > reactionTime then
		
		local heroDirDeg2 = math.deg( math.acos( (hero.lastPosVec - Vector(myHero)):normalized():dotP((hero.lastPosVec - predictedPos):normalized()) ))
			
		if heroDirDeg2 < 20 or heroDirDeg2 > 160 then		
		return predictedPos
		end
	end
	
		
	--Distance/Delay too small to miss (need to move out of skillshot radius + hero hitbox width)
	--Also covers movement speed too slow case
	if settings.SmallDistance 
		and effectiveArea/(hero.moveSpeed/1000) > reactionTime then
		--return hero.lastPosVec + hero.directionVec * (hero.moveSpeed * 250/1000)
		return predictedPos
	end

		
	--Just changed directions
	if settings.JustChangedDir and hero.waypoints and #hero.waypoints > 1
		and hero.lastChangedDirTime and GetTick() - hero.lastChangedDirTime < 100 then
		--and hero.averageDirTime and hero.averageDirTime + (GetDistance(hero,hero.minBBox) + width)/(hero.moveSpeed/1000) > reactionTime then
				
		local vecDiff = Vector(hero.waypoints[2].x, hero.lastPosVec.y, hero.waypoints[2].y) - hero.lastPosVec
		local heroDir = vecDiff:normalized()
		
		--Waypoint distance is smaller than the predicted pos (maybe a wall in the way)
		if waypointDist ~= nil and waypointDist < GetDistance(hero.lastPosVec, predictedPos) then		
			return Vector(hero.waypoints[2].x, hero.lastPosVec.y, hero.waypoints[2].y)
		end
		
		if hero.closestEnemy and hero.closestEnemyDistance > 800 then
			return hero.lastPosVec + heroDir * hero.averageDist
		end		
		
		--return predictedPos2
		return predictedPos
	end
	
	--Running Away
	if settings.RunningAway  
		and hero.lastRunAwayTime and GetTick() - hero.lastRunAwayTime > 600 then
		return predictedPos
	end
	
	return nil	
end

function GetSpellTimeWhenHit (speed, delay, startpoint, endpoint)
	
	if speed == 0 or speed == nil then
		return GetTick() + (delay or 0) + GetLatency()/2
	else
		return GetTick() + (GetDistance(startpoint, endpoint))/(speed/1000) + (delay or 0) + GetLatency()/2
	end
end

function OnApplyParticle(unit, particle)
	if ezSkillShot.Info.PrintParticle then
		local cTarget = GetTarget()
	
		if not cTarget then
			cTarget = myHero
		end
		
		if unit and unit.name == cTarget.name then
			print(particle)
		end
	end
end

function getAttackDetails(source, target, spell)
	return {startTime = os.clock() * 1000,
			windupTime = (spell.windUpTime or 0) * 1000,
			dmg = target and GetSkillDamageByName(source, target, spell),
			spell = spell,
			spellParticle = nil,
			target = target,
			}
end

function GetSkillDamageByName (hero, target, spell)
	local spellName = spell.name

	if hero.type ~= 'obj_AI_Hero' then
		if hero.type == "obj_AI_Turret" then
			return hero.totalDamage * (100/(100 + target.armor * (1-.3)))
		end
	
		
		return 0
	end
	
	if spellName:find("BasicAttack") or spellName:find("basicattack")  then
		return getDmg("AD",target,hero,3)
	elseif spellName:find("CritAttack") or spellName:find("critattack") then
		return getDmg("AD",target,hero,3) * 2	
	elseif hero:GetSpellData(_Q).name == spellName then
		return getDmg("Q",target,hero,3,hero:GetSpellData(_Q).level)
	elseif hero:GetSpellData(_W).name == spellName then
		return getDmg("W",target,hero,3,hero:GetSpellData(_W).level)
	elseif hero:GetSpellData(_E).name == spellName then
		return getDmg("E",target,hero,3,hero:GetSpellData(_E).level)
	elseif hero:GetSpellData(_R).name == spellName then
		return getDmg("R",target,hero,3,hero:GetSpellData(_R).level)
	else
		return 0
	end
end

function DeleteIncomingSpell(key)
	incomingSpells[key] = nil	
end

function DeleteIncomingSpell2()
	for key, details in pairs(incomingSpells) do
		if os.clock() * 1000 - details.startTime > 2000 then
			print(os.clock() * 1000 - details.startTime)
			--incomingSpells[key] = nil
		end
	end
end

function OnAnimation(unit, animation)    
	if unit.name == myHero.name then
		if GetTick() < me.lastWindup 
			and GetTick() - me.detectAutoTime < me.windupTime()
			and animation:find("Run") then
			
			me.lastWindup = GetTick() - 50
			me.nextBasicTime = GetTick() - 50
		end
			
	end	
end

function OnProcessSpell(object, spell)

	if (object.type == 'obj_AI_Hero' or champions[object.charName])
		and GetDistance(object) < 1500 then
				
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)		
			
			if (hero.team ~= object.team) and (GetDistance(hero, spell.endPos) < 50) then
			incomingSpells[object.name .. spell.name] = getAttackDetails(object, hero, spell)
			
			--print(spell.name .. " : " .. incomingSpells[object.name .. spell.name].dmg)
			DelayAction(DeleteIncomingSpell,2, {object.name .. spell.name})
			
			break
			end
		end

	end
	
	if object.name == myHero.name then
		if spell.target then
			me.recentTarget = spell.target
			me.recentTargetTime = GetTick()
		end
		
		if ezSkillShot.Info.PrintSpellName then
			print(spell.name)
			print("Windup time: " .. spell.windUpTime)
			print("Animation time: " .. spell.animationTime)
		end
		
	
		if (spell.name:find("Attack") or isSpellAttack(spell.name))
		 and GetTick() < me.lastCommandTime then
		 
			if me.baseAttackSpeed == nil then
				local calcBase = (1/spell.animationTime) / myHero.attackSpeed
				
				if calcBase > .6 and calcBase < .7 then			
				me.baseAttackSpeed = calcBase
				me.windupTimeRatio = spell.windUpTime/spell.animationTime				
				me.windupTime = function() return me.windupTimeRatio * GetNextAttackTime() end
				end
			end	
		 
		 --[[
			if me.minBBox == nil or GetDistance(spell.endPos) - myHero.range > me.minBBox then
				me.minBBox = GetDistance(spell.endPos) - myHero.range
				print(me.minBBox)
			end]]
			
			me.lastWindup = GetTick() + me.windupTime()
			me.nextBasicTime = GetTick() + GetNextAttackTime()
			me.detectAutoTime = GetTick()
		end
		
		if myChampion.skillshots[spell.name] and myChampion.skillshots[spell.name].isAutoReset then
			me.lastWindup = GetTick() - 50
			me.nextBasicTime = GetTick() - 50
			
			--print("AA reset")
		end
		
		--me.lastWindup = GetTick() + spell.windUpTime*1000 + 20
		--me.nextAnimationTime = GetTick() + spell.windUpTime*1000 + 50
		
			
		return
	end

	if ezSkillShot.GSettings.PredictionMode == 1 then
	
	for _, hero in pairs(heroDB) do
		if hero.name == object.name and spell ~= nil then			
			hero.windupFinishTime = GetTick() + (spell.windUpTime * 1000 or 0)
			return
		end
	end
	
	end
end

function GetNextAttackTime ()
	return 1000/(me.baseAttackSpeed * myHero.attackSpeed)
end

function isSpellAttack(spellName)
	return (
		--Ashe
		spellName == "frostarrow"
		--Caitlyn
		or spellName == "CaitlynHeadshotMissile"
		--Kennen
		or spellName == "KennenMegaProc"
		--Quinn
		or spellName == "QuinnWEnhanced"
		--Trundle
		or spellName == "TrundleQ"
		--XinZhao
		or spellName == "XenZhaoThrust"
		or spellName == "XenZhaoThrust2"
		or spellName == "XenZhaoThrust3"
		--Garen
		or spellName == "GarenSlash2"
		--Renekton
		or spellName == "RenektonExecute"
		or spellName == "RenektonSuperExecute"
		--Yi
		or spellName == "MasterYiDoubleStrike"
    )
end

function OnGainBuff(hero, buff)

	if hero.type == 'obj_AI_Hero' and hero.team ~= myHero.team and (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_KNOCKUP or buff.type == BUFF_SUPPRESS) then
		for _, heroObj in pairs(heroDB) do
			if heroObj.name == hero.name then			
				heroObj.cc[buff.name] = GetTick() + buff.duration*1000
			return
			end
		end
	end
end

--[[
function OnGainAggro(attacker)
	if attacker.type == 'obj_AI_Hero' then
		local hero = GetHeroByName(attacker.name)
		
		hero.targetMe = true
	end
end

function OnLoseAggro(attacker)
	if attacker.type == 'obj_AI_Hero' then
		local hero = GetHeroByName(attacker.name)
		
		hero.targetMe = nil
	end
end
--]]

function OnDash(hero, dash)
	if ezSkillShot.GSettings.PredictionMode == 1 then

	if hero.type == 'obj_AI_Hero' and hero.team ~= myHero.team  then
		if not dash.endPos then
			dash.endPos = Vector(dash.target)
		end
		
		for _, heroObj in pairs(heroDB) do
			if heroObj.name == hero.name then			
				heroObj.dash = {endTime = GetTick() + dash.duration * 1000, from = dash.startPos, to = dash.endPos, target= dash.target, speed=dash.speed }
				--print("Dash endTime" .. (dash.endT) .. " vs " .. dash.duration)
				
			return
			end
		end
	end
	
	end
end

function isInRangeFirstCheck (currentTarget, range, timeElapsed)
	local trueRange = range + GetDistance(myHero, myHero.minBBox)
	local maxRunAwayPos = currentTarget.lastPosVec + (currentTarget.lastPosVec - Vector(myHero)):normalized() * currentTarget.moveSpeed * timeElapsed/1000
	
	if ezSkillShot[myHero.charName .. "Settings"].CheckInRange and GetDistance(myHero, maxRunAwayPos) <  trueRange then
		return true
	elseif ezSkillShot[myHero.charName .. "Settings"].CheckInRange == false and GetDistance(myHero, currentTarget) <  trueRange then
		return true
	else
		return false
	end
end

function isTargetInRange (currentTarget, predictPos, skillShot, timeElapsed)
	local trueRange = GetTrueRange(skillShot)
	local maxRunAwayPos = currentTarget.lastPosVec + (currentTarget.lastPosVec - Vector(myHero)):normalized() * currentTarget.moveSpeed * timeElapsed/1000
	
	if skillShot.type == "CIRCULAR" then
		trueRange = trueRange + skillShot.radius
	elseif skillShot.type == "LINE" then
		trueRange = trueRange + GetDistance(currentTarget,currentTarget.minBBox)
	end
	
	for buffname, buffTime in pairs(currentTarget.cc) do
		if buffTime - GetTick() + skillShot.radius/(currentTarget.moveSpeed/1000) > timeElapsed then
			return true
		end
	end
	
	if ezSkillShot[myHero.charName .. "Settings"].CheckInRange and GetDistance(myHero, maxRunAwayPos) < trueRange then		
		return true
	elseif ezSkillShot[myHero.charName .. "Settings"].CheckInRange == false and GetDistance(myHero, predictPos) <  trueRange then
		return true
	end
	
	return false	
end

function GetTimeProjectileCollide (targetPos, targetDir, targetSpeed, sourcePos, projSpeed )
	local velocity = targetDir * targetSpeed
	
	local velocityX = velocity.x
	local velocityY = velocity.z
	
	local relStart = targetPos - sourcePos
	
	local relStartX = relStart.x
	local relStartY = relStart.z

	local a = velocityX * velocityX + velocityY * velocityY - projSpeed * projSpeed
	local b = 2 * velocityX * relStartX + 2 * velocityY * relStartY
	local c = relStartX * relStartX + relStartY * relStartY -- 150 * 150
	
	local disc = b * b - 4 * a * c
	
	if disc >= 0 then
		local t1 = -( b + math.sqrt( disc )) / (2 * a )
		local t2 = -( b - math.sqrt( disc )) / (2 * a )
		
		
		if t1 and t2 and t1 > 0 and t2 > 0 then
			if t1 > t2 then
				return t2
			else
				return t1
			end
		elseif t1 and t1 > 0 then
			return t1
		elseif t2 and t2 > 0 then
			return t2
		end
	end
	
	return nil
end

function GetTrueRangeAutoAttack(source)
	return source.range + GetDistance(source, source.minBBox)
end

function GetTrueRange(skillShot)

	local minBBox = 75 --GetDistance(myHero, myHero.minBBox)

	if skillShot.rangeFn then
		return skillShot.rangeFn()	
	elseif skillShot.isTrueRange then
		return skillShot.range
	elseif skillShot.isAutoReset then
		return myHero.range + minBBox
	elseif skillShot.name == "AutoAttack" then	
		return myHero.range + minBBox
	elseif skillShot.isAutoBuff then
		return myHero.range + minBBox
	elseif skillShot.isSelfCast or skillShot.isTargeted then	
		return skillShot.range
	elseif skillShot.spellKey and skillShot.type == "LINE" then
		return skillShot.range + minBBox
	elseif skillShot.spellKey and skillShot.type == "CIRCULAR" then
		return skillShot.range
	end

end

function HeroAttack(target)
	if ValidTarget(target, GetTrueRangeAutoAttack(myHero)) then
	myHero:Attack(target)
	
	me.lastWindup = GetTick() + me.windupTime() + GetLatency() + 50
	me.nextBasicTime = GetTick() + me.windupTime() + GetLatency() + 50
	me.lastCommandTime = GetTick() + me.windupTime() + GetLatency() + 50
	
	--me.lastAACommand = GetTick() + 250
	
	--print("attack")
	elseif ValidTarget(target) then
		myHero:Attack(target)
	end
end

function OnSendPacket(p)	

	if ezSkillShot[myHero.charName .. "Settings"].BlockMovement and GetTick() < me.lastWindup - GetLatency() then
		packet = Packet(p)
		packetName = Packet(p):get('name')		
		
		if packetName == 'S_MOVE' or packetName == 'S_CAST' then		
			packet:block()		
		end
	end
end

function GetAttackTime ()
	return (1/(.665 * myHero.attackSpeed))*1000
end

function CheckIsExecute(skillShot, target)
	if not skillShot.isExecute then
		return true
	else
		local spellDamage, TypeDmg = getDmg(spellKeyStr[skillShot.spellKey],target,myHero,3)
		
		return spellDamage > target.health
	end
end

function CheckSpellName (skillShot)
	if skillShot.checkName then
		if skillShot.name == "AutoAttack" then
			return true
		else
			return skillShot.spellName == myHero:GetSpellData(skillShot.spellKey).name
		end		
	else
		return true
	end
end

function CheckIncomingDamagePercent(skillShot, selectedTarget)
	if not skillShot.isShield then
		return true
	else
		local dmg = GetIncomingDamage(selectedTarget)
		return (skillShot.damage and skillShot.damage() * .01 * skillShot.params.HealthPercent < dmg)
			or skillShot.params.HealthPercent < 100 * dmg/selectedTarget.maxHealth
			or selectedTarget.health < dmg
	end
end

function checkHealthPercent(skillShot, selectedTarget)
	if not skillShot.checkHealthPercent and not skillShot.isHeal then
		return true
	else
		return skillShot.params.HealthPercent > 100 * selectedTarget.health/selectedTarget.maxHealth
	end
end




function CheckItemSlot ()
	for skillname, skillShot in pairs(skillShots) do
		if skillShot.itemName then
			skillShot.spellKey = GetInventorySlotItem(skillShot.id)
		end
	end
end

function CheckAutoBuff ()
	
	autoBuffSkills = {}

	for skillname, skillShot in pairs(skillShots) do
		if skillShot.isAutoBuff then
			autoBuffSkills[skillname] = skillShot			
		end
	end
end

function SortSkillsCD ()
	local skillsCDSorted = {}
	
	for skillname, skillShot in pairs(skillShots) do
		if skillShot.coolDown then
			skillsCDSorted[#skillsCDSorted+1] = {skillShot = skillShot, cd = skillShot.coolDown }			
		elseif skillShot.spellKey then
			skillsCDSorted[#skillsCDSorted+1] = {skillShot = skillShot, cd = myHero:GetSpellData(skillShot.spellKey).cd }			
		elseif skillShot.name == "AutoAttack" then
			skillsCDSorted[#skillsCDSorted+1] = {skillShot = skillShot, cd = (1/(.665 * myHero.attackSpeed)) }			
		end
	end
	
	table.sort(skillsCDSorted, 
	function (a, b)
		return a.cd < b.cd 
	end)
	
	return skillsCDSorted
end

function Initialize ()
	if ezSkillShot.GSettings.PredictionMode == 1 then
		wayPointManager = WayPointManager()
	elseif ezSkillShot.GSettings.PredictionMode == 2 then
		VP = VPrediction()
	elseif ezSkillShot.GSettings.PredictionMode == 3 then
		ezFreePred = ezFreePrediction()
	end

	CheckItemSlot()	
	SetInterval(CheckItemSlot, 5, nil, {})
	
	--CheckAutoBuff()	
	--SetInterval(CheckAutoBuff, 5, nil, {})
	
	--SortSkillsCD()
	--SetInterval(SortSkillsCD, 5, nil, {})
	
	enemyMinions = minionManager(MINION_ENEMY, 2000, player, MINION_SORT_HEALTH_ASC)
end

function CheckChanneled (skillShot)
	if skillShot.channelDuration then
		me.lastWindup = GetTick() + skillShot.channelDuration + skillShot.spellDelay
		--me.nextBasicTime = GetTick() + skillShot.channelDuration + skillShot.spellDelay
	end		
end

function GetTick()
	return GetGameTimer() * 1000
end

function OnTick()
	
	if ezSkillShot.GSettings.PredictionMode == 1 then
	UpdateHeroDirection ()
	--DeleteIncomingSpell2 ()
	end
	
	if ezSkillShot.KeySettings.FarmingKey then
	enemyMinions:update()
	end
	
		
	--CheckTargetBuff(myHero,"aa")
	--print(myHero:GetSpellData(_Q).name)
	
	--[[
	if ezSkillShot[myHero.charName .. "Settings"].RangeHarassMode and ezSkillShot.KeySettings.CastSpell 
	and GetTick() > me.lastWindup then
		local closestHero = GetClosestEnemyChampion(myHero)
				
		if closestHero then
		
		local currentTarget = GetHeroByName(closestHero.name)
		local predictedPos = currentTarget.lastPosVec + currentTarget.directionVec * (closestHero.ms * 250/1000)
				
		if currentTarget.targetMe and GetDistance(myHero, currentTarget) < 1000 then --ezSkillShot[myHero.charName .. "Settings"][myHero.charName .. "HarassRange"] then
		local dir = (Vector(myHero) - Vector(closestHero)):normalized()
		local pos = Vector(myHero) + dir * (myHero.ms * 250/1000)
		
		myHero:MoveTo(pos.x, pos.z)
		return
		
		end	
		
		end
	end
	--]]
	
	
	local selectedTarget = nil		
	
	local priorityTable = GetPriorityTable()

		--print(GetTick() - me.lastWindup)
		
	for skillname, skillShot in pairs(skillShots) do
	
		
	if GetTarget() ~= nil then
		selectedTarget = GetTarget()
		
		if ezSkillShot[myHero.charName .. "Settings"].AutoSelectTarget == false then
			ezSkillShot[myHero.charName .. "Settings"].currentTarget = GetTarget()
		end		
	end	
	
	if ezSkillShot[myHero.charName .. "Settings"].currentTarget and ezSkillShot[myHero.charName .. "Settings"].currentTarget.dead then
		ezSkillShot[myHero.charName .. "Settings"].currentTarget = nil
	end
	
	if ezSkillShot.KeySettings.CastSpell == false 
	or (selectedTarget and not selectedTarget.type == "obj_AI_Hero") then
		ezSkillShot[myHero.charName .. "Settings"].currentTarget = nil
		selectedTarget = nil
	elseif ezSkillShot[myHero.charName .. "Settings"].currentTarget then
		selectedTarget = ezSkillShot[myHero.charName .. "Settings"].currentTarget
	end

	
	
	if (GetTick() > me.lastWindup or skillShot.noAnimation)  and ((skillShot.params.UseSpell and ezSkillShot.KeySettings.CastSpell)
		or (skillShot.params.UseHarassSpell and ezSkillShot.KeySettings.CastHarassSpell)) 
		and (skillShot.spellKey or skillname == myHero.charName .. "AutoAttack") then
		
		if (ezSkillShot.KeySettings.CastHarassSpell or GetSkillOrder(skillShot.params.SkillOrder)) and 
		((skillShot.spellKey and myHero:CanUseSpell(skillShot.spellKey) == READY) 
		or (skillname == myHero.charName .. "AutoAttack" and GetTick() > me.nextBasicTime))
		and CheckTargetBuff(myHero, skillShot.heroHasBuff) and CheckTargetNoBuff(myHero, skillShot.heroHasNoBuff)
		and CheckSpellName(skillShot) then			

	
		local trueRange = GetTrueRange(skillShot)
		
		if skillShot.isHeal then			
			if skillShot.isTargeted then	
				local allyTable = GetLowestHPAlly(skillShot.range)
				
				if #allyTable > 0 then				
					selectedTarget = allyTable[1].obj
				end
			elseif skillShot.isSelfCast then			
				selectedTarget = myHero			
			end		
		end
		
		if skillShot.isShield then		
			if skillShot.isTargeted then
				local allyTable = GetHigestIncomingDamageAlly(skillShot.range)

				if #allyTable > 0 then
					selectedTarget = allyTable[1].obj
				end				
			elseif skillShot.isSelfCast then			
				selectedTarget = myHero		
			end		
		end
		
		
		if ezSkillShot[myHero.charName .. "Settings"].AutoSelectTarget and 
			(ezSkillShot[myHero.charName .. "Settings"].PrioritizeSelectedTarget == false or ezSkillShot[myHero.charName .. "Settings"].currentTarget == nil )
			and skillShot.isHeal == nil and skillShot.isShield == nil then

		for n=1, #priorityTable, 1 do
		local enemy = priorityTable[n]
		
		
		if PlayerCanChase(enemy.enemyObj,trueRange) 
			and CheckTargetBuff(enemy.enemyObj, skillShot.targetHasBuff, skillShot.projectileSpeed) then		
		selectedTarget = enemy.enemyObj
		ezSkillShot[myHero.charName .. "Settings"].currentTarget = enemy.enemyObj
		break
		end
		
		end
		end
	
			
		if selectedTarget ~= nil and ValidTarget(selectedTarget, trueRange, skillShot.isHeal == nil and skillShot.isShield == nil)
			and CheckTargetBuff(selectedTarget, skillShot.targetHasBuff, skillShot.projectileSpeed) 
			and CheckIsExecute(skillShot,selectedTarget) and checkHealthPercent(skillShot, selectedTarget)
			and CheckIncomingDamagePercent(skillShot, selectedTarget)
			and (skillShot.castReq == nil or skillShot.castReq(selectedTarget)) then
		
		if skillname == myHero.charName .. "AutoAttack" then
			HeroAttack(selectedTarget)
			--print(selectedTarget.name)
			return
		elseif skillShot.isSelfCast then
			CastSpell(skillShot.spellKey)
			
			
			
			if skillShot.isAutoReset then
				--me.lastWindup = GetTick() - 100
				me.nextBasicTime = GetTick() - 100
			end
			
			CheckChanneled(skillShot)--move to on procspell
			return
		elseif skillShot.isTargeted then
			CastSpell(skillShot.spellKey, selectedTarget)
			
			CheckChanneled(skillShot)
			return
		else		
		
		if ezSkillShot.GSettings.PredictionMode == 2 then
			local ret = CastVPredictionSkillShot(skillShot, selectedTarget)
			CheckChanneled(skillShot)
			
			if ret then	return end
		elseif ezSkillShot.GSettings.PredictionMode == 3 then	
			local ret = CastEzFreeSkillShot(skillShot, selectedTarget)		
			CheckChanneled(skillShot)
			
			if ret then	return end
		else
			local ret = CastEzCarrySkillShot(skillShot, selectedTarget)		
			CheckChanneled(skillShot)
			
			if ret then	return end
		end		
		
		end
		
		
		end
		
		end --skill order check
		
	end --cast spell check

	end --for loop
	
	Farm()
	
	if ezSkillShot[myHero.charName .. "Settings"].Orbwalk and ezSkillShot.KeySettings.CastSpell and
		GetTick() > me.lastWindup then
		
		if ezSkillShot[myHero.charName .. "Settings"]["FollowTarget"] and ezSkillShot[myHero.charName .. "Settings"].currentTarget then
		
		
		
		--if (GetDistance(myHero,selectedTarget) - (75 + myHero.range))/myHero.ms * 1000 > GetTick() - me.nextBasicTime then			
		local myHeroDir = (Vector(mousePos.x,0, mousePos.z) - Vector(myHero.x,0,myHero.z)):normalized()
		local myHeroPredPos = Vector(myHero) + myHeroDir * myHero.ms * (160/1000)
		
		if GetDistance(selectedTarget) > 75 + myHero.range then
			myHero:MoveTo(selectedTarget.x, selectedTarget.z)		
		elseif GetDistance(selectedTarget) < 75 + myHero.range
			and GetDistance(myHeroPredPos,selectedTarget) > 75 + myHero.range then
			myHero:HoldPosition()		
		else
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
		
		
		else
		
		if GetDistance(mousePos) < ezSkillShot[myHero.charName .. "Settings"].OrbwalkHoldZone and myHero.range > 400 then
			if not me.holdPos then
				myHero:HoldPosition()
				me.holdPos = true
			end
		else
			myHero:MoveTo(mousePos.x, mousePos.z)
			me.holdPos = false
		end
		
		
		end
	end
	
end

function PlayerCanChase (target, trueRange)
	--return target.valid and not target.dead and GetDistance(target) < trueRange + 250	
	return ValidTarget(target,trueRange)		
end

function CastVPredictionSkillShot(skillShot, selectedTarget)

	if skillShot.type == "LINE" then
	CastPosition,  HitChance,  Position = VP:GetLineCastPosition(selectedTarget, skillShot.spellDelay, skillShot.radius, skillShot.range, skillShot.projectileSpeed, myHero, true)
	if HitChance >= skillShot.params.PredictPriority and GetDistance(CastPosition) < skillShot.range then
		if skillShot.isCollision and collisionManager:GetMinionCollision(myHero, CastPosition, skillShot.projectileSpeed, skillShot.spellDelay, skillShot.radius) == nil then
		CastSpell(skillShot.spellKey, CastPosition.x, CastPosition.z)
		return true
		elseif skillShot.isCollision == nil then
		CastSpell(skillShot.spellKey, CastPosition.x, CastPosition.z)
		return true
		end
	end
	
	else
	CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(selectedTarget, skillShot.spellDelay, skillShot.radius, skillShot.range)
          if HitChance >= skillShot.params.PredictPriority and GetDistance(CastPosition) < skillShot.range then
              CastSpell(skillShot.spellKey, CastPosition.x, CastPosition.z)
			  return true
		  end	
	end

	return false
end

function CastEzFreeSkillShot(skillShot, selectedTarget)
			
	local predictPos = ezFreePred:GetPrediction(skillShot.spellDelay, skillShot.projectileSpeed, selectedTarget)
	
	if predictPos ~= nil and GetDistance(predictPos) < GetTrueRange(skillShot) then
	
	if skillShot.isCollision and collisionManager:GetMinionCollision(myHero, predictPos, skillShot.projectileSpeed, skillShot.spellDelay, skillShot.radius) == nil then
		CastSpell(skillShot.spellKey, predictPos.x, predictPos.z)
		return true
	elseif skillShot.isCollision == nil then
		CastSpell(skillShot.spellKey, predictPos.x, predictPos.z)
		return true
	end
	
	end

	return false
end

function CastEzCarrySkillShot(skillShot, selectedTarget)
	local currentTarget = GetHeroByName(selectedTarget.name)
	
	if currentTarget ~= nil then
	
	local spellDelay = skillShot.spellDelay + GetLatency()/2
	
	local predictDelayPos = currentTarget.lastPosVec
	if currentTarget.waypointDir then
		predictDelayPos = currentTarget.lastPosVec + currentTarget.waypointDir * currentTarget.moveSpeed * spellDelay/1000
	end		

	local timeWhenHit = spellDelay
	local predictPos = nil
	
	
	if skillShot.projectileSpeed then
		local timeWhenCollide = GetTimeProjectileCollide(predictDelayPos, currentTarget.directionVec, currentTarget.moveSpeed, Vector(myHero), skillShot.projectileSpeed)
		
		if timeWhenCollide then
			timeWhenHit = spellDelay + timeWhenCollide * 1000
			predictPos = PredictHeroMovement (currentTarget, timeWhenHit, skillShot, GetEzSkillShotSettings(skillShot))
		end
	else
		predictPos = PredictHeroMovement (currentTarget, spellDelay, skillShot, GetEzSkillShotSettings(skillShot))
	end		
	
	if predictPos ~= nil and isTargetInRange(currentTarget, predictPos, skillShot, timeWhenHit) then
	
	if skillShot.isCollision and collisionManager:GetMinionCollision(myHero, predictPos, skillShot.projectileSpeed, skillShot.spellDelay, skillShot.radius) == nil then
		CastSpell(skillShot.spellKey, predictPos.x, predictPos.z)
		return true
	elseif skillShot.isCollision == nil then
		CastSpell(skillShot.spellKey, predictPos.x, predictPos.z)
		return true
	end
	
	end
	
	
	end --currentTarget
	
	return false
end

function GetEzSkillShotSettings (skillShot)
	
	local skillShotParams = {}
	
	if skillShot.params.PredictPriority == 1 then
	skillShotParams.Instant = true	
	elseif skillShot.params.PredictPriority == 2 then	
	skillShotParams.CC = true
	skillShotParams.Dash = true
	skillShotParams.Animation = true
	skillShotParams.NoChangeDir = true
	skillShotParams.SmallDistance = true
	if skillShot.type == "LINE" then
	skillShotParams.SmallDirDeg = true	
	end	
	skillShotParams.JustChangedDir = true
	skillShotParams.RunningAway = true
	skillShotParams.IgnoreDelay = 0
	elseif skillShot.params.PredictPriority == 3 then
	
	skillShotParams.CC = true
	skillShotParams.Dash = true
	skillShotParams.SmallDistance = true
	skillShotParams.JustChangedDir = true
	skillShotParams.Animation = true
	skillShotParams.IgnoreDelay = 0
	end
	
	return skillShotParams
end

function DeleteMarkedMinion(key)
	markedMinion[key] = nil	
end

function GetSkillDamage (skillShot, target)
	if skillShot.itemName and skillShot.spellName then
		return getDmg(skillShot.spellName,target,myHero,3)
	elseif skillShot.name == "AutoAttack" then
		--[[
		local addDmg = 0
		for skillname, skillShot in pairs(autoBuffSkills) do
			if buffCond and buffCond
		end]]--
		
		return getDmg("AD",target,myHero,3)
	elseif not skillShot.summonersName then
		local damage, typeDmg = getDmg(spellKeyStr[skillShot.spellKey],target,myHero,3)
		
		return damage + (typeDmg == 2 and getDmg("AD",target,myHero,3) or 0)
	end
		
	return 0
end

function Farm ()
	
	if ezSkillShot.KeySettings.FarmingKey and GetTick() > me.lastWindup then
	
	for skillname, skillShot in pairs(skillShots) do
		
	if skillShot.params.Farming and skillShot.params.Farming.FarmWithSpell 
		and ((skillShot.spellKey and myHero:CanUseSpell(skillShot.spellKey) == READY) 
			or (skillShot.name == "AutoAttack" and GetTick() > me.nextBasicTime))
		and CheckTargetBuff(myHero, skillShot.heroHasBuff) and CheckTargetNoBuff(myHero, skillShot.heroHasNoBuff)
		and CheckSpellName(skillShot) then
			
		for _, minion in pairs(enemyMinions.objects) do
		
		if markedMinion[minion.name] == nil and GetFarmSkillOrder(skillShot.params.Farming.FarmOrder, minion)
			and (GetTrueRange(skillShot) > GetDistance(myHero, minion)
			or (skillShot.params.Farming.MoveToMinion and GetDistance(myHero, minion) - GetTrueRange(skillShot) < 250 )) then
			
			if GetSkillDamage(skillShot, minion) > minion.health then
						
			if skillShot.name == "AutoAttack" then
				HeroAttack(minion)
			elseif skillShot.isSelfCast then
				CastSpell(skillShot.spellKey)			
				
				if skillShot.isAutoReset then
					me.nextBasicTime = GetTick() - 100
					return					
				end
			elseif skillShot.isTargeted then
				CastSpell(skillShot.spellKey, minion)				
			else			
				if skillShot.isCollision then
				
				local colMin = collisionManager:GetMinionCollision(myHero, Vector(minion), skillShot.projectileSpeed, skillShot.spellDelay, skillShot.radius)
				
				if colMin.name == minion.name then
					CastSpell(skillShot.spellKey, minion.x, minion.z)
				else
					return				
				end
				
				else
				CastSpell(skillShot.spellKey, minion.x, minion.z)			
				end			
			end			
				markedMinion[minion.name] = true
				DelayAction(DeleteMarkedMinion,2, {minion.name})
				return				
			end
		
		end
		
		end
		
	end
	
	end
	
	end
end

--degrees
function RotateAroundPoint (angleDeg, center, point)
local angleRad = math.rad(angleDeg)

local rotatedPointX = math.cos(angleRad) * (point.x - center.x) - 
        math.sin(angleRad) * (point.z - center.z) + center.x
local rotatedPointY  = math.sin(angleRad) * (point.x - center.x) + 
        math.cos(angleRad) * (point.z - center.z) + center.z
		
return Vector(rotatedPointX, point.y, rotatedPointY)
end

function CheckValidBuffDuration (tBuff, target, projSpeed)
	if projSpeed and tBuff.endT - GetTick() > GetDistance(target)/projSpeed then
		return true
	elseif not projSpeed then
		return true
	end
	
	return false
end

function CheckTargetNoBuff(target, buffName)
	if buffName then
		return not ezBuffTracker:targetHasBuffEx(target, buffName)
	else
		return true
	end	--buffname
	
	return true
end

--Move to OnGainBuff?
function CheckTargetBuff(target, buffName, projSpeed)
	if buffName then
		return ezBuffTracker:targetHasBuffEx(target, buffName)
	else
		return true
	end	--buffname
	
	return false
end

function GetIncomingDamage (target)
	local predictedDamage = 0

	for _, attackDetails in pairs(incomingSpells) do
		if attackDetails.target and attackDetails.target.name == target.name then
			predictedDamage = predictedDamage + attackDetails.dmg
		end
	end
	return predictedDamage
end

function GetHigestIncomingDamageAlly (range)
	
	local allyTable = {}	
	
	for i = 1, heroManager.iCount do
		local ally = heroManager:GetHero(i)		
		
		if ValidTarget(ally, range, false) then		
			allyTable[#allyTable + 1] = {obj = ally, predictedDamage = GetIncomingDamage(ally)}
		end		
	end
	
	table.sort(allyTable, 
	function (a, b)
		return a.predictedDamage > b.predictedDamage 
	end)
	
	return allyTable
end

function GetLowestHPAlly (range)
	local allyTable = {}
	
	for i = 1, heroManager.iCount do
		local ally = heroManager:GetHero(i)
		if ValidTarget(ally, range, false) then
			allyTable[#allyTable + 1] = {obj = ally, effectiveHealth = ally.health * ( 1 + ( (ally.magicArmor + ally.armor) / 100 ))}
		end				
	end
	
	table.sort(allyTable, 
	function (a, b)
		return a.effectiveHealth < b.effectiveHealth 
	end)
	
	return allyTable
end

function GetPriorityTable()
	local phEHTable = {}
	
	for _, enemy in pairs(GetEnemyHeroes()) do
		local priority = 1 + TS_GetPriority(enemy, player.enemyTeam)/5
			
		if ValidTarget(enemy) and priority < 2 then
			if player.damage > player.ap then
			phEHTable[#phEHTable + 1] = {enemyObj = enemy, charName = enemy.charName, effectiveHealth = priority * enemy.health * ( 1 + ( enemy.armor / 100 ))}
			else
			phEHTable[#phEHTable + 1] = {enemyObj = enemy, charName = enemy.charName, effectiveHealth = priority * enemy.health * ( 1 + ( enemy.magicArmor / 100 ))}
			end
		end
	end
	
	table.sort(phEHTable, 
		function (a, b)
			return a.effectiveHealth < b.effectiveHealth 
		end)
	
	return phEHTable
	
end

function GetFarmSkillOrder(priority, minion)
	for skillname, skillShot in pairs(skillShots) do
			
		if skillShot.params.UseSpell and skillShot.params.Farming 
			and skillShot.params.Farming.FarmOrder ~= 0 and skillShot.params.Farming.FarmOrder < priority then
			
			if skillname == myHero.charName .. "AutoAttack" and (GetTick() > me.nextBasicTime or GetTick() < me.lastWindup)
				and GetTrueRange(skillShot) > GetDistance(myHero, minion)
			and (skillShot.params.Farming.MoveToMinion == false or GetDistance(myHero, minion) - GetTrueRange(skillShot) < 250 ) then
				return false
			elseif skillShot.spellKey and myHero:CanUseSpell(skillShot.spellKey) == READY
				and (not skillShot.checkName or skillShot.spellName == myHero:GetSpellData(skillShot.spellKey).name) then
	
				return false
			end
		end
	end

	return true
end

function GetSkillOrder(priority)

	for skillname, skillShot in pairs(skillShots) do
	
		if skillShot.params.UseSpell and skillShot.params.SkillOrder ~= 0 and skillShot.params.SkillOrder < priority then
			if skillname == myHero.charName .. "AutoAttack" and (GetTick() > me.nextBasicTime or GetTick() < me.lastWindup) then
				return false
			elseif skillShot.spellKey and myHero:CanUseSpell(skillShot.spellKey) == READY
				and (not skillShot.checkName or skillShot.spellName == myHero:GetSpellData(skillShot.spellKey).name) then
	
				return false
			end
		end
	end

	return true
end

function GetSummonerSlot (spellName)
	if myHero:GetSpellData(SUMMONER_1).name == spellName then
		return SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name == spellName then
		return SUMMONER_2
	else
		return nil
	end
end

function AddHealthPercentMenu (menu, skill)
	
	if skill.isShield or skill.isHeal or skill.checkHealthPercent then
		local defaultPercent = 50
		
		if skill.checkHealthPercent then
			defaultPercent = 30
		elseif skill.isShield then
			if skill.damage then
			defaultPercent = 50
			else
			defaultPercent = 15
			end
		end
	
		menu:addParam("HealthPercent", "Health Percent to Cast Spell", SCRIPT_PARAM_SLICE, defaultPercent, 1, 100, 0)
	end
end

function AddFarmMenu (menu, skillShot)
	local name = skillShot.name
		
	local defaultFarmSetting = false
	local defaultOrder = 2
	
	if skillShot.name == "AutoAttack" then
		defaultFarmSetting = true
		defaultOrder = 1
	elseif skillShot.itemName and skillShot.coolDown then
		defaultFarmSetting = true
		name = skillShot.itemName
	elseif skillShot.spellKey and myHero:GetSpellData(skillShot.spellKey).cd < 10 then
		defaultFarmSetting = true
	end
	
	menu:addSubMenu("Farming", "Farming")
	menu.Farming:addParam("FarmWithSpell", "Use to Farm", SCRIPT_PARAM_ONOFF, defaultFarmSetting)
	
	if skillShot.name == "AutoAttack" then
		menu.Farming:addParam("MoveToMinion", "Move To Minion", SCRIPT_PARAM_ONOFF, true)
	end
	
	menu.Farming:addParam("FarmOrder", "Order", SCRIPT_PARAM_SLICE, defaultOrder, 0, 5, 0)
end

function AddSpellMenu (menu, skillShot)
	
	local defaultPriority = 0
	local defaultFarmSetting = false
	
	if skillShot.name == "AutoAttack" then
		defaultPriority = 1
	end
		
	menu:addParam("UseSpell", "Use " .. skillShot.name, SCRIPT_PARAM_ONOFF, true)
	menu:addParam("UseHarassSpell", "Harass with " .. skillShot.name, SCRIPT_PARAM_ONOFF, false)
	menu:addParam("DrawRange", "Draw Range", SCRIPT_PARAM_ONOFF, false)
	menu:addParam("SkillOrder", "Skill Order", SCRIPT_PARAM_SLICE, defaultPriority, 0, 5, 0)

	AddFarmMenu(menu,skillShot)
end

function OnLoad()
	PrintChat("<font color=\"#3F92D2\" >Yomie's AutoCarry v" .. sVersion .. " Loaded - " .. myHero.charName .. "</font>")
	
	CheckForUpdates()
	
	ezSkillShot = scriptConfig("ezCarry v" .. sVersion, "ezSkillshot")

	ezSkillShot:addSubMenu("Settings",myHero.charName .. "Settings")
	
	TargetSelector = TargetSelector(TARGET_PRIORITY, 2000, DAMAGE_PHYSICAL, false)
	TargetSelector.name = "Selector"
	ezSkillShot[myHero.charName .. "Settings"]:addTS(TargetSelector)
	
		
	--Check if target can run out of range or not
	ezSkillShot[myHero.charName .. "Settings"]:addParam("CheckInRange", "Target In Range Check", SCRIPT_PARAM_ONOFF, true)
	ezSkillShot[myHero.charName .. "Settings"]:addParam("DrawSelected", "Draw Selected Enemy", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot[myHero.charName .. "Settings"]:addParam("AutoSelectTarget", "Auto select target", SCRIPT_PARAM_ONOFF, true)
	ezSkillShot[myHero.charName .. "Settings"]:addParam("PrioritizeSelectedTarget", "Prioritize Selected Target", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot[myHero.charName .. "Settings"]:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	ezSkillShot[myHero.charName .. "Settings"]:addParam("BlockMovement", "BlockMovement", SCRIPT_PARAM_ONOFF, false)
		
	--melee only
	ezSkillShot[myHero.charName .. "Settings"]:addParam("FollowTarget", "Follow Target", SCRIPT_PARAM_ONOFF, false)
	
		
	--range only
	ezSkillShot[myHero.charName .. "Settings"]:addParam("OrbwalkHoldZone", "OrbwalkHoldZone", SCRIPT_PARAM_SLICE, 175, 0, 700, 0)
	
		
	local trueRange = GetTrueRangeAutoAttack(myHero)
	
	--ezSkillShot[myHero.charName .. "Settings"]:addParam("RangeHarassMode", "Range Harass Mode", SCRIPT_PARAM_ONOFF, false)
	--ezSkillShot[myHero.charName .. "Settings"]:addParam(myHero.charName .. "HarassRange", "Harass Range", SCRIPT_PARAM_SLICE, trueRange - 50, 0, 1000, 0)
	
	ezSkillShot:addSubMenu("General Settings","GSettings")
	
	if VIP_USER then
	ezSkillShot.GSettings:addParam("PredictionMode", "Prediction Library (Requires Reload)", SCRIPT_PARAM_LIST, 1, {"ezSkillShot", "VPrediction", "ezFreePred" })
	else
	ezSkillShot.GSettings:addParam("PredictionMode", "Prediction Library (Requires Reload)", SCRIPT_PARAM_LIST, 3, {"ezSkillShot", "VPrediction", "ezFreePred" })
	end
	--https://bitbucket.org/honda7/bol/raw/8c79315fd8b732e819736fbfc911ccfde43b3bc0/Common/VPrediction.lua

	
	
	ezSkillShot:addSubMenu("Info", "Info")
	ezSkillShot.Info:addParam("DrawEnemyPos", "DrawEnemyPos", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("PrintSpellName", "PrintSpellName", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("PrintBuffs", "PrintBuffs", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("PrintIncomingSpells", "PrintIncomingSpells", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("PrintSkillName", "PrintSkillName", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("PrintParticle", "Print Particle", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("DrawInfoRangeCircle", "DrawInfoRangeCircle", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("InfoCircleFollow", "InfoCircleFollow", SCRIPT_PARAM_ONOFF, false)
	ezSkillShot.Info:addParam("InfoCircleRange", "InfoCircleRange", SCRIPT_PARAM_SLICE, 0, 0, 2000, 0)
	
	
	ezSkillShot:addSubMenu("Key Settings", "KeySettings")
	ezSkillShot.KeySettings:addParam("CastSpell", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, castSpellKey)
	ezSkillShot.KeySettings:addParam("CastHarassSpell", "Harrass Key", SCRIPT_PARAM_ONKEYDOWN, false, castHarassKey)
	ezSkillShot.KeySettings:addParam("FarmingKey", "Farming Key", SCRIPT_PARAM_ONKEYDOWN, false, castLastHitKey)
	
	ezSkillShot:addSubMenu("Items", "Items")
	
	for itemName, item in pairs(items) do
		ezSkillShot.Items:addSubMenu(itemName, myHero.charName .. item.itemName)
		ezSkillShot.Items[myHero.charName .. item.itemName]:addParam("UseSpell", "Use " .. itemName, SCRIPT_PARAM_ONOFF, true)
		
		if item.spellName then
			AddFarmMenu(ezSkillShot.Items[myHero.charName .. item.itemName],item)
		end
		
		ezSkillShot.Items[myHero.charName .. item.itemName]:addParam("SkillOrder", "Skill Order", SCRIPT_PARAM_SLICE, 0, 0, 5, 0)		
		
		AddHealthPercentMenu(ezSkillShot.Items[myHero.charName .. item.itemName], item)	
		
		skillShots[myHero.charName .. item.itemName] = item
	end
	
	
	ezSkillShot:addSubMenu("Summoners", "Summoners")
	for name, summonerSpell in pairs(summonerSpells) do
		local slot = GetSummonerSlot(summonerSpell.spellName)
		
		
		if slot then	
		ezSkillShot.Summoners:addSubMenu(summonerSpell.summonersName, myHero.charName .. summonerSpell.spellName)
		ezSkillShot.Summoners[myHero.charName .. summonerSpell.spellName]:addParam("UseSpell", "Use " .. summonerSpell.summonersName, SCRIPT_PARAM_ONOFF, true)
		ezSkillShot.Summoners[myHero.charName .. summonerSpell.spellName]:addParam("SkillOrder", "Skill Order", SCRIPT_PARAM_SLICE, 0, 0, 5, 0)
		
		AddHealthPercentMenu(ezSkillShot.Summoners[myHero.charName .. summonerSpell.spellName], summonerSpell)
		
		summonerSpell.spellKey = slot
		skillShots[myHero.charName .. summonerSpell.spellName] = summonerSpell
		end		
		
	end

	
	ezSkillShot:addSubMenu("-- Spell Settings --", "SeperateBar")
	--ezSkillShot:addParam("SeperateBar", "-- Spell Settings --", SCRIPT_PARAM_INFO, "")
	
	for skillname, skillShot in pairs(skillShots) do
	
	
	if skillShot.spellDelay == nil then
		skillShot.spellDelay = 250
	end
	
	
	if skillname == myHero.charName .. "AutoAttack" then
	ezSkillShot:addSubMenu("AutoAttack", skillShot.spellName)

	AddSpellMenu(ezSkillShot[skillShot.spellName], skillShot)
	
	--ezSkillShot[skillShot.spellName]:addParam("BlockMovement", "BlockMovement", SCRIPT_PARAM_ONOFF, true)
	
	
	
	skillShot.params = 	ezSkillShot[skillShot.spellName]
	
	elseif skillShot.summonersName then		
		skillShot.params = ezSkillShot.Summoners[myHero.charName .. skillShot.spellName]
	
	elseif skillShot.itemName then		
		skillShot.params = ezSkillShot.Items[myHero.charName .. skillShot.itemName]
		
	elseif skillShot.isTargeted or skillShot.isSelfCast then
	ezSkillShot:addSubMenu(skillShot.name .. " " .. spellKeyStr[skillShot.spellKey], skillShot.spellName)

	AddSpellMenu(ezSkillShot[skillShot.spellName], skillShot)	
	AddHealthPercentMenu(ezSkillShot[skillShot.spellName], skillShot)	
	
	skillShot.params = 	ezSkillShot[skillShot.spellName]
	
	else
	ezSkillShot:addSubMenu(skillShot.name .. " " .. spellKeyStr[skillShot.spellKey], skillShot.spellName)
	
	ezSkillShot[skillShot.spellName]:addParam("PredictPriority", "Prediction Hit Chance", SCRIPT_PARAM_LIST, 2, {"Low", "Medium", "High" })
	AddSpellMenu(ezSkillShot[skillShot.spellName], skillShot)	
	AddHealthPercentMenu(ezSkillShot[skillShot.spellName], skillShot)
			
	skillShot.params = 	ezSkillShot[skillShot.spellName]
	
	end
	
	end
	
	Initialize ()
end