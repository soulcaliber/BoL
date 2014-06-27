local AUTOUPDATE = true

local me = {}
local Menu = nil

local sVersion = 2.34

local comboKey = 32
local LastHitKey = string.byte("C")
local LaneClearKey = string.byte("V")
local TurnOffKey = string.byte("X")

------------------------------------------Unit Info---------------------------------------------
--Changes: Draven, Jinx, Karma, Kennen, Lucian, Lulu, Malzahar, Sivir, Syndra, Xerath
--Added: Elise, Thresh, Lissandra, Nami

local unitInfo = {
	    Ahri         = { projSpeed = 1.75},
        Anivia       = { projSpeed = 1.4},
        Annie        = { projSpeed = 1.2},
        Ashe         = { projSpeed = 2.0},
        Brand        = { projSpeed = 2.0},
        Caitlyn      = { projSpeed = 2.5},
        Cassiopeia   = { projSpeed = 1.20},
        Corki        = { projSpeed = 2.0},
        Draven       = { projSpeed = 1.7},
		Elise        = { projSpeed = 1.6},
		Ezreal       = { projSpeed = 2.0},
        FiddleSticks = { projSpeed = 1.75},
        Graves       = { projSpeed = 3.0},
        Heimerdinger = { projSpeed = 1.5},
        Janna        = { projSpeed = 1.2},
        Jayce        = { projSpeed = 2.2},
		Jinx         = { projSpeed = 2.75},
        Karma        = { projSpeed = 1.5},
        Karthus      = { projSpeed = 1.20},
        Kayle        = { projSpeed = math.huge},
        Kennen       = { projSpeed = 1.60},
        KogMaw       = { projSpeed = 1.8},
        Leblanc      = { projSpeed = 1.7},
		Lissandra    = { projSpeed = 2.0},
        Lucian       = { projSpeed = 2.8},
        Lulu         = { projSpeed = 1.45},
        Lux          = { projSpeed = 1.6},
        Malzahar     = { projSpeed = 2.0},
        MissFortune  = { projSpeed = 2.0},
        Morgana      = { projSpeed = 1.6},        
		Nami      	 = { projSpeed = 1.5},
		Nidalee      = { projSpeed = 1.75},
        Orianna      = { projSpeed = 1.45},
        Quinn        = { projSpeed = 2.0},
        Ryze         = { projSpeed = 2.4},
        Sivir        = { projSpeed = 1.75},
        Sona         = { projSpeed = 1.5},
        Soraka       = { projSpeed = 1.0},
        Swain        = { projSpeed = 1.6},
        Syndra       = { projSpeed = 1.8},
        Teemo        = { projSpeed = 1.3},
		Thresh       = { projSpeed = math.huge}, --??
        Tristana     = { projSpeed = 2.25},
        TwistedFate  = { projSpeed = 1.5},
        Twitch       = { projSpeed = 2.5},
        Urgot        = { projSpeed = 1.3},
        Varus        = { projSpeed = 2.0},
		Vayne        = { projSpeed = 2.0},
        Veigar       = { projSpeed = 1.1},
		Velkoz		 = { projSpeed = math.huge},
        Viktor       = { projSpeed = 2.3},
        Vladimir     = { projSpeed = 1.4},
        Xerath       = { projSpeed = 2.0},
        Ziggs        = { projSpeed = 1.5},
        Zilean       = { projSpeed = 1.2},
        Zyra         = { projSpeed = 1.7},		
		}
	
	unitInfo["Blue_Minion_Basic"] = 	 { windupTime = 333, projSpeed = 0, delayOffset = 300, isMinion = true, projectileName = "DrawFX"}
	unitInfo["Blue_Minion_Wizard"] =     { windupTime = 460, projSpeed = 0.68, delayOffset = 200, distOffset = 80, isMinion = true, projectileName = "Mfx_bcm_mis.troy" }
	unitInfo["Blue_Minion_MechCannon"] = { windupTime = 365, projSpeed = 1.18, delayOffset = 100, isSiegeMinion = true, isMinion = true, projectileName = "SpikeBullet.troy" }
	unitInfo["Blue_Minion_MechMelee"] =  { projSpeed = 0, delayOffset = 100, isSiegeMinion = true, isMinion = true }
	
	unitInfo["Red_Minion_Basic"] = 		{ windupTime = 333, projSpeed = 0, delayOffset = 300, isMinion = true, projectileName = "DrawFX"}
	unitInfo["Red_Minion_Wizard"] =     { windupTime = 460, projSpeed = 0.68, delayOffset = 200, distOffset = 80, isMinion = true, projectileName = "Mfx_pcm_mis.troy" }
	unitInfo["Red_Minion_MechCannon"] = { windupTime = 365, projSpeed = 1.18, delayOffset = 100, isSiegeMinion = true, isMinion = true, projectileName = "TristannaBasicAttack_mis.troy" }
	unitInfo["Red_Minion_MechMelee"] =  { projSpeed = 0, delayOffset = 100, isSiegeMinion = true, isMinion = true }

	-- Blue Turrets
	unitInfo["OrderTurretNormal"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "OrderTurretFire2_mis.troy" }
	unitInfo["OrderTurretNormal2"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "OrderTurretFire2_mis.troy"  }
	unitInfo["OrderTurretDragon"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "OrderTurretFire2_mis.troy" }
	unitInfo["OrderTurretAngel"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "OrderTurretFire2_mis.troy" }
	
	-- Red Turrets
	unitInfo["ChaosTurretWorm"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "ChaosTurretFire2_mis.troy" }
	unitInfo["ChaosTurretWorm2"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "ChaosTurretFire2_mis.troy"  }
	unitInfo["ChaosTurretGiant"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "ChaosTurretFire2_mis.troy"  }
	unitInfo["ChaosTurretNormal"] =	{ aaDelay = 150, projSpeed = 1.14, yOffset = 400, delayOffset = 50, isTurret = true, projectileName = "ChaosTurretFire2_mis.troy"  }

------------------------------------------Unit Info---------------------------------------------
local refreshAttacks = {"PowerFist","DariusNoxianTacticsONH","Takedown","Ricochet","BlindingDart","VayneTumble","JaxEmpowerTwo","MordekaiserMaceOfSpades","SiphoningStrikeNew","RengarQ","MonkeyKingDoubleAttack","YorickSpectral","ViE","GarenSlash3","HecarimRamp","XenZhaoComboTarget","LeonaShieldOfDaybreak","ShyvanaDoubleAttack","shyvanadoubleattackdragon","TalonNoxianDiplomacy","TrundleTrollSmash","VolibearQ","PoppyDevastatingBlow","Meditate","FioraFlurry"}

for _, name in pairs(refreshAttacks) do
	refreshAttacks[name] = true
end

local startAttackSpeed = 0.665

local allyMinions = {}
local enemyMinions = {}

local incomingDetails = {}

local displayObj = nil

local movePerSec = 1/6
local lastMoveCommand = 0

if unitInfo[myHero.charName] ~= nil then
	me.projSpeed = unitInfo[myHero.charName].projSpeed
else
	me.projSpeed = 0
	--print("Hero projectile speed not found.")
end

function GetTick()
	return GetGameTimer() * 1000
end

function OnTick()
	LastHitOnTick()
end

function LastHitOnTick()
	enemyMinions:update()
	allyMinions:update()	
	
	UpdateSpellParticles()
	

	if Menu.TurnOffRange and Menu.TurnOffRange > 0 then
		
		local foundEnemy = false
		for i=1, heroManager.iCount do
			local hero = heroManager:getHero(i)
	
			if hero.team == TEAM_ENEMY and ValidTarget(hero) and GetDistance(myHero, hero) < Menu.TurnOffRange then
				Menu.LastHitOn = false
				foundEnemy = true
				break
			end	
		end
		
		if Menu.AutoTurnOn and foundEnemy == false then
			Menu.LastHitOn = true
		end
	end
	
	if me.recalling and me.recallPos and GetDistance(me.recallPos) > 25 then
		me.recalling = false
		Menu.LastHitOn = true
	end
	
	if Menu.LastHitSettings.UnderTowers and UnderTurret(myHero) then
		Menu.LastHitOn = false
	end
	
	if me.recalling then
		Menu.LastHitOn = false
		--Menu.LaneClearOn = false
		--Menu.ForceLastHit = false
	end
	
	if Menu.AutoTurnOn == false then
		Menu.LastHitOn = false
	end	
	
	
	if Menu.ComboKey and Menu.Orbwalk.AttackChampions then
		if GetTick() > me.lastWindup
			and not me.recalling
			and GetTick() - lastMoveCommand > movePerSec*1000 then
		
		if GetDistance(mousePos) < Menu.Orbwalk.OrbWalkHoldZone then
			if not me.holdPos then
				myHero:HoldPosition()
				me.holdPos = true
			end
		else
			myHero:MoveTo(mousePos.x, mousePos.z)
			lastMoveCommand = GetTick()
			me.holdPos = false
		end
		
		end
		
		
		if GetTick() > me.nextBasicTime then
			local target = GetPriorityTarget()
			
			if ValidTarget(target, myHero.range + 75) then
			HeroAttack(target)
			return
			end
		end		
	end
	
	if ( Menu.AutoTurnOn and not (Menu.LastHitSettings.StopComboKey and Menu.ComboKey) ) 
		or Menu.LaneClearOn or Menu.ForceLastHit then
		
		if Menu.Orbwalk.OrbWalk and GetTick() > me.lastWindup
			and not me.recalling
			and GetTick() - lastMoveCommand > movePerSec*1000 then
		
		if GetDistance(mousePos) < Menu.Orbwalk.OrbWalkHoldZone then
			if not me.holdPos then
				myHero:HoldPosition()
				me.holdPos = true
			end
		else
			myHero:MoveTo(mousePos.x, mousePos.z)
			lastMoveCommand = GetTick()
			me.holdPos = false
		end
		
		end
		
	if GetTick() > me.nextBasicTime
		and (( Menu.LastHitOn and not me.recalling)
		or Menu.LaneClearOn or Menu.ForceLastHit) then
		
	local selectedMinion = {}
	local laneClearMinions = {}
	local doLaneClear = true
	
	for _, minion in pairs(enemyMinions.objects) do	
		if ValidTarget(minion, GetTrueRange(myHero)) then			
					
			local predictDamage = 0				
			local sumDmg = 1						
			local sumViableDmg = 1
			
			for sourceName, attackDetails in pairs(incomingDetails) do				
			
				if attackDetails.target.name == minion.name
					and checkAttackStillViable(attackDetails, minion) then
						
				if GetMyTimeToHit(minion) > GetTimeWhenHit(attackDetails, minion) then
					predictDamage = predictDamage + attackDetails.dmg
				end
				

				sumViableDmg = sumViableDmg + attackDetails.dmg
				end
				
				if attackDetails.target.name == minion.name then
				sumDmg = sumDmg + attackDetails.dmg
				end
			end
		
			
			if predictDamage < minion.health and predictDamage + myCalcDamage(myHero, minion) - 2 > minion.health then
				selectedMinion[#selectedMinion+1] = {minion = minion, sumIncoming = minion.health/sumViableDmg, sumViableDmg = sumViableDmg }
			end			
			
			laneClearMinions[#laneClearMinions+1] = {minion = minion, sumIncoming = minion.health/sumDmg }			
			
			if sumDmg + myCalcDamage(myHero, minion) - 2 > minion.health then
			doLaneClear = false
			end

		end	
	end

	if #selectedMinion > 0 then
		table.sort(selectedMinion, 
		function (a, b)
			return a.sumIncoming < b.sumIncoming 
		end)		
		
		if ValidTarget(selectedMinion[1].minion, GetTrueRange(myHero)) then
		
		local minion = selectedMinion[1].minion
		
		HeroAttack(selectedMinion[1].minion)		
		return
		end
	end
	
	if Menu.LaneClearOn and #laneClearMinions > 0 and doLaneClear then
		table.sort(laneClearMinions, 
		function (a, b)
			return a.sumIncoming < b.sumIncoming 
		end)
		
		if ValidTarget(laneClearMinions[#laneClearMinions].minion, GetTrueRange(myHero)) then
		HeroAttack(laneClearMinions[#laneClearMinions].minion)
		return
		end
	end
	
	end

	end
end

function HeroAttack(target)

	if ValidTarget(target, GetTrueRange(myHero)) and me.lastWindup < GetTick() then
	myHero:Attack(target)	
	
	me.lastWindup = GetTick() + me.windupTime() + GetLatency() + 50
	me.nextBasicTime = GetTick() + me.windupTime() + GetLatency() + 50
	me.lastCommandTime = GetTick() + me.windupTime() + GetLatency() + 50

	--Packet('S_MOVE', { type = 3, x = target.networkID, y = target.networkID, targetNetworkId = target.networkID}):send()
	end
end

function OnSendPacket(p)	

	if Menu.BlockMovement and not Menu.ComboKey and GetTick() < me.lastWindup
		and GetTick() < me.lastCommandTime then
		packet = Packet(p)
		packetName = Packet(p):get('name')		
		
		if packetName == 'S_MOVE' or packetName == 'S_CAST' then		
			packet:block()		
		end
	end
end

function UpdateSpellParticles()
	for sourceName, attackDetails in pairs(incomingDetails) do
		if attackDetails.spellParticle == nil and attackDetails.projectileID then
			local mis = objManager:GetObjectByNetworkId(attackDetails.projectileID)
				
			if mis then
			incomingDetails[sourceName].spellParticle = mis
			end				
		end
	end
end

function GetTrueRange(source)
	return source.range + 150--GetDistance(source, source.minBBox)
end

function MyGetDistance(source, target)
	target = target or player
	return math.sqrt((source.x-target.x)^2 + (source.y-target.y)^2 + (source.z-target.z)^2)
end

function GetMyTimeToHit(target)
	local latencyDelay = Menu.LastHitSettings.LatencyDelay and GetLatency()/2 or 0

	if myHero.range < 400 then
		return GetTick() + me.windupTime() - 20 + latencyDelay - Menu.LastHitSettings.LastHitDelay
	else
		return GetTick() + MyGetDistance(myHero.visionPos, target.visionPos)/me.projSpeed + me.windupTime() + latencyDelay - 20 - Menu.LastHitSettings.LastHitDelay
	end
end

function GetTimeWhenHit(attackDetails, target)

	local latencyDelay = Menu.LastHitSettings.LatencyDelay and GetLatency()/2 or 0

	if attackDetails.speed == 0 then
		return attackDetails.startTime + attackDetails.spellWindup + attackDetails.delayOffset - latencyDelay
	elseif attackDetails.speed > 0 and attackDetails.spellParticle then
		return GetTick() + MyGetDistance(attackDetails.spellParticle, target.visionPos)/attackDetails.speed + attackDetails.delayOffset - latencyDelay
	else
		return GetTick() + 2000
	end	
end

function getAllyMinion(name)
	for i, minion in pairs(allyMinions.objects) do
		if minion ~= nil and minion.valid and minion.name == name then
			return minion
		end
	end
	return nil
end
 
function getEnemyMinion(name)
	for i, minion in pairs(enemyMinions.objects) do
		if minion ~= nil and ValidTarget(minion) and minion.name == name then
			return minion
		end
	end
	return nil
end

function OnDraw()	
	if Menu.DrawRangeCircle then
		DrawCircle(myHero.x, myHero.y, myHero.z, getTrueRange(), 0x19A712)
		DrawCircle(myHero.x, myHero.y,myHero.z, Menu.Orbwalk.OrbWalkHoldZone, 0xFFFFFF)
	end
	
	--DevOnDraw()
end

function DevOnDraw()
	for sourceName, attackDetails in pairs(incomingDetails) do
		local target = getEnemyMinion(attackDetails.target.name)		
		local source = getAllyMinion(attackDetails.source.name)
		
		if attackDetails.source.type == "obj_AI_Turret" then
			source = attackDetails.source
		end
	
		if target and source and attackDetails.stillViable then
		DrawLine3D(target.x, target.y, target.z, source.x, source.y, source.z, 5, 0xFF00FF00)
		end
	end
end

function getTrueRange()
    return myHero.range + GetDistance(myHero.minBBox)
end

function getMinionAttackDetails(source, target, spell)
	return {startTime = GetTick(),
			spellWindup = unitInfo[source.charName].windupTime or (spell.windUpTime * 1000),
			speed = unitInfo[source.charName].projSpeed or 0, 
			dmg = myCalcDamage(source,target), -- source:CalcDamage(target),
			source = source,
			target = target,
			spell = spell,
			projectileID = spell.projectileID,
			delayOffset = unitInfo[source.charName].delayOffset or 0,
			spellParticle = nil,
			projectileName = unitInfo[source.charName].projectileName,
			stillViable = true
			}
end

function myCalcDamage(source, target)
	local armorPen = 0
	local armorPenPercent = 0
	
	local magicPen = 0
	local magicPenPercent = 0
	
	local magicDamage = 0
	local physDamage = source.totalDamage
	
	local dmgReductionPercent = 0

	local totalDamage = physDamage

		
	if source.name == myHero.name then
		if Menu.Mastery.ArcaneBladeOn then
			magicDamage = myHero.ap * .05
		end
		
		if Menu.Mastery.DevestatingStrike then
			armorPenPercent = .06
		end
		
		if Menu.Mastery.HavocOn then
			physDamage = physDamage * 1.03
			magicDamage = magicDamage * 1.03
		end
		
		if Menu.Mastery.ExecutionerOn then
			physDamage = physDamage * 1.05
			magicDamage = magicDamage * 1.05
		end
				
		if Menu.Mastery.DEdgedSwordOn then
			physDamage = myHero.range < 400 and physDamage*1.02 or (physDamage*1.015)
			magicDamage = myHero.range < 400 and magicDamage*1.02 or (magicDamage*1.015)
		end
		
		if Menu.Mastery.ButcherOn then
			physDamage = physDamage + 2
		end
	
	end
	
	if unitInfo[source.charName] ~= nil then
		if unitInfo[source.charName].isTurret ~= nil then	
			armorPenPercent = .3
		end
		
		if unitInfo[source.charName].isTurret ~= nil and unitInfo[target.charName].isMinion ~= nil then	
			physDamage = physDamage * 1.25
		end
		
		if unitInfo[source.charName].isTurret ~= nil and unitInfo[target.charName].isSiegeMinion ~= nil then
			dmgReductionPercent = .3
		end
	end

	return (physDamage * (100/(100 + target.armor * (1-armorPenPercent)))  
	 + magicDamage * (100/(100 + target.magicArmor * (1-magicPenPercent))) ) * (1-dmgReductionPercent)
end

function checkAttackStillViable (attackDetails, target)
			
	if attackDetails == nil then return false end
	
	if attackDetails.stillViable == false then return false end
	
	local source = getAllyMinion(attackDetails.source.name)
	--local target = getEnemyMinion(attackDetails.target.name)
	
	if attackDetails.source.type == "obj_AI_Turret" then
		source = attackDetails.source
	end
	
	if source == nil or target == nil 
		or source.dead or target.dead
		or not source.valid or not target.valid then
		attackDetails.stillViable = false
		
		local key = attackDetails.source.name
		incomingDetails[key] = nil		
		return false
	end
		
	if attackDetails.speed == 0 and GetTick() > attackDetails.startTime + attackDetails.spellWindup + attackDetails.delayOffset then
		attackDetails.stillViable = false
	end
	
	local timeElapsed = GetTick() - attackDetails.startTime	
	
	if timeElapsed > 2000 then	
		attackDetails.stillViable = false
		
		local key = attackDetails.source.name
		incomingDetails[key] = nil
		return false
	end
	
	if attackDetails.speed > 0 and attackDetails.spellParticle == nil then
		return false
	end
	
	return true
end

function OnProcessSpell(object, spell)

			
	if unitInfo[object.charName] ~= nil and object.charName ~= myHero.charName then
	
	for _, minion in pairs(enemyMinions.objects) do
					
		if ValidTarget(minion) and minion ~= nil and GetDistance(minion, spell.endPos) < 25	and unitInfo[object.charName].projSpeed > 0  then
			incomingDetails[object.name] = getMinionAttackDetails(object, minion, spell)
			--DelayAction(GetMissileParticle, spell.windUpTime + 0.05, {incomingDetails[object.name]})					
		end
	end
	
	end
	

	if object.name == myHero.name then
		if spell.name:find("Attack")
		or spell.name == "frostarrow"
		or spell.name == "CaitlynHeadshotMissile"
		or spell.name == "KennenMegaProc"
		or spell.name == "QuinnWEnhanced"
		or spell.name == "LucianPassiveShot" then
		
			if me.baseAttackSpeed == nil then
				local calcBase = (1/spell.animationTime) / myHero.attackSpeed
				
				if calcBase > .6 and calcBase < .7 then			
				me.baseAttackSpeed = calcBase
				me.windupTimeRatio = spell.windUpTime/spell.animationTime				
				me.windupTime = function() return me.windupTimeRatio * GetAttackTime() end
				end
			end	
		
			--me.windupTime = me.windupTimeRatio * GetAttackTime()

			me.lastWindup = GetTick() + me.windupTime() + Menu.Orbwalk.OrbwalkDelay
			me.nextBasicTime = GetTick() + GetAttackTime() + Menu.Orbwalk.OrbwalkDelay
			me.detectAutoTime = GetTick()
		else
			me.lastWindup = GetTick() + spell.windUpTime*1000
			me.nextBasicTime = math.max(me.lastWindup, me.nextBasicTime)
		end
		
		if refreshAttack(spell.name) then
			me.lastWindup = GetTick() - 50
			me.nextBasicTime = GetTick() - 50
		end
		
		if spell.name == "Recall" then
			me.recalling = true
			me.recallPos = Vector(myHero)
		end
	end
end

function OnDeleteObj (object)
	for sourceName, attackDetails in pairs(incomingDetails) do
		if object.networkID == attackDetails.spell.projectileID then
			--incomingDetails[sourceName] = nil
			attackDetails.stillViable = false
		end
	end
end

function refreshAttack(spellName)
    return refreshAttacks[spellName]
end

function OnAnimation(unit, animation)    
	if unit.name == myHero.name then
		if Menu.Orbwalk.RestartAuto and GetTick() < me.lastWindup 
			and GetTick() - me.detectAutoTime < me.windupTime()
			and animation:find("Run") then
			
			me.lastWindup = GetTick() - 50
			me.nextBasicTime = GetTick() - 50
		end
			
	end
	
	if incomingDetails[unit.name] then
		if GetTick() < incomingDetails[unit.name].spellWindup and not animation:find("Attack") then
			incomingDetails[unit.name].stillViable = false
		end
		
		if animation == "Death" then
			incomingDetails[unit.name] = nil
		end		
	end	
end

function lastHitOnLoad()
	enemyMinions = minionManager(MINION_ENEMY, 2000, player, MINION_SORT_HEALTH_ASC)
    allyMinions = minionManager(MINION_ALLY, 2000, player, MINION_SORT_HEALTH_ASC)

	me.windupTime = function() return 100 end
	me.lastWindup = 0
	me.nextBasicTime = 0
	me.lastCommandTime = 0
	me.detectAutoTime = 0
end

function GetAttackTime ()
	return 1000/(me.baseAttackSpeed * myHero.attackSpeed)
end

function GetPriorityTarget()
	local pTable = GetPriorityTable()
	local range = GetTrueRange(myHero)
	
	for i=1, #pTable do
		if ValidTarget(pTable[i].enemyObj, range) then
			return pTable[i].enemyObj
		end
	end
	
	return nil
end

function GetPriorityTable()
	local priorityTable = {}
	
	for _, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			priorityTable[#priorityTable + 1] = {enemyObj = enemy, charName = enemy.charName, effectiveHealth = enemy.health * ( 1 + ( enemy.armor / 100 ))}
		end
	end
	
	table.sort(priorityTable, 
		function (a, b)
			return a.effectiveHealth < b.effectiveHealth 
		end)
	
	return priorityTable	
end

function OnLoad()	
		
        PrintChat("<font color=\"#3F92D2\" >Yomie's LastHit Script v" .. sVersion .. " Loaded </font>")
		
		if AUTOUPDATE then
		CheckForUpdates()
		end
		
		Menu = scriptConfig("ezLastHit v" .. sVersion, "ezLastHit" .. sVersion)
		Menu:addParam("LastHitOn", "LastHit On", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("ForceLastHit", "Force LastHit", SCRIPT_PARAM_ONKEYDOWN, false, LastHitKey)
		Menu:addParam("ComboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, comboKey)
		Menu:addParam("AutoTurnOn", "Auto turn on", SCRIPT_PARAM_ONKEYTOGGLE, true, TurnOffKey)
		Menu:addParam("LaneClearOn", "LaneClear Mode", SCRIPT_PARAM_ONKEYDOWN, false, LaneClearKey)
		Menu:addParam("DrawRangeCircle", "Draw Range Circle", SCRIPT_PARAM_ONOFF, true)
		
		Menu:addParam("BlockMovement", "Block Movement when LastHitting (VIP)", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("TurnOffRange", "LastHit Range", SCRIPT_PARAM_SLICE, 700, 0, 2000, 0)
				
		Menu:addSubMenu("LastHit Delay", "LastHitSettings")
		Menu.LastHitSettings:addParam("LastHitDelay", "LastHit Delay", SCRIPT_PARAM_SLICE, 0, -200, 200, 0)
		Menu.LastHitSettings:addParam("LatencyDelay", "Calculate Ping time", SCRIPT_PARAM_ONOFF, true)
		Menu.LastHitSettings:addParam("UnderTowers", "Stop LastHit under tower", SCRIPT_PARAM_ONOFF, false)
		Menu.LastHitSettings:addParam("StopComboKey", "Stop LastHit on ComboKey", SCRIPT_PARAM_ONOFF, false)
		
		Menu:addSubMenu("Orbwalk Settings", "Orbwalk")
		Menu.Orbwalk:addParam("OrbwalkDelay", "Orbwalk Delay", SCRIPT_PARAM_SLICE, 50, -100, 300, 0)
		Menu.Orbwalk:addParam("AttackChampions", "Attack Champions on ComboKey", SCRIPT_PARAM_ONOFF, false)
		--Menu.Orbwalk:addParam("HarassChampions", "Attack Champions on LastHit", SCRIPT_PARAM_ONOFF, false)
		Menu.Orbwalk:addParam("OrbWalk", "Orbwalk when Lasthitting", SCRIPT_PARAM_ONOFF, true)
		Menu.Orbwalk:addParam("RestartAuto", "Restart Canceled Auto", SCRIPT_PARAM_ONOFF, false)
		Menu.Orbwalk:addParam("OrbWalkHoldZone", "Orbwalk Hold Zone", SCRIPT_PARAM_SLICE, 125, 0, 700, 0)
		
		
		Menu.LastHitOn = false
		Menu.AutoTurnOn = false
		Menu.LaneClearOn = false
		Menu.ForceLastHit = false
		
		Menu:permaShow("AutoTurnOn")
		Menu:permaShow("LastHitOn")
		Menu:permaShow("ForceLastHit")
		Menu:permaShow("LaneClearOn")		
				
		Menu:addSubMenu("Mastery", "Mastery")
		Menu.Mastery:addParam("DevestatingStrike", "DevestatingStrike", SCRIPT_PARAM_ONOFF, true)
		Menu.Mastery:addParam("HavocOn", "HavocOn", SCRIPT_PARAM_ONOFF, true)
		Menu.Mastery:addParam("DEdgedSwordOn", "DEdgedSwordOn", SCRIPT_PARAM_ONOFF, true)
		Menu.Mastery:addParam("ButcherOn", "ButcherOn", SCRIPT_PARAM_ONOFF, true)
		Menu.Mastery:addParam("ArcaneBladeOn", "ArcaneBladeOn", SCRIPT_PARAM_ONOFF, true)
		
		lastHitOnLoad()
end

----------------AUTO Update------------------------------

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
			
	--if true then
	if os.time()-lastUpdateTime > 3*86400 and os.time() > lastUpdateTime then --a day has passed
		
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
		local url = "https://bitbucket.org/Xgs/bol/raw/master/ezLastHit.lua"
		Update(versionTextContent, "ezLastHit", sVersion, url, SCRIPT_PATH.."ezLastHit.lua")
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