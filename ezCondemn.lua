if myHero.charName ~= "Vayne" then return end

local sVersion = 1.5

local dashDB = {}
local heroDirDB = {}

function OnLoad()
	PrintChat("<font color=\"#3F92D2\" >ezCondemn v" .. sVersion .. " Loaded</font>")
	
	Menu = scriptConfig("ezCondemn v" .. sVersion, "ezCondemn" .. sVersion)
	Menu:addParam("AutoCondem", "Auto Condemn", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu:addParam("AutoPush", "Auto Push Gap Closer", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("DrawCondem", "Draw Condemn Path", SCRIPT_PARAM_ONOFF, false)
	

	Menu:addSubMenu("Condemn Settings", "CondemnSettings")
	Menu.CondemnSettings:addParam("MaxDistance", "Max Condemn Distance", SCRIPT_PARAM_SLICE, 1000, 0, 1500, 0)
	Menu.CondemnSettings:addParam("CheckDistance", "Check Distance", SCRIPT_PARAM_SLICE, 25, 1, 200, 0)
	Menu.CondemnSettings:addParam("Checks", "Checks", SCRIPT_PARAM_SLICE, 3, 0, 5, 0)
	
	Menu:addSubMenu("Condemn Hero", "HeroSettings")
	
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		
		if hero.team ~= player.team then
			heroDirDB[hero.name] = {lastVec = Vector(0,0,0), dir = Vector(0,0,0), lastAngle = 0, index = i}
			Menu.HeroSettings:addParam(hero.charName, hero.charName, SCRIPT_PARAM_ONOFF, true)
		end
	end	
end

function GetTick()
	return GetGameTimer() * 1000
end

function UpdateHeroDirection ()
	for heroName, heroObj in pairs(heroDirDB) do
		local hero = heroManager:GetHero(heroObj.index)
		local currentVec = Vector(hero)
		local dir = (currentVec - heroObj.lastVec)
		
		if dir ~= Vector(0,0,0) then
			dir = dir:normalized()
		end
		
		heroObj.lastAngle = heroObj.dir:dotP( dir )
		heroObj.dir = dir
		heroObj.lastVec = currentVec
		
		--local heroPos = Vector(hero) + dir * hero.ms * 500/1000
		--DrawCircle(heroPos.x, heroPos.y,heroPos.z, 50, 0x19A712)
	end
end

function OnDash(hero, dash)
	if Menu.AutoPush then
	if hero.type == 'obj_AI_Hero' and hero.team ~= myHero.team  then
		if dash.endPos == nil then
			dash.endPos = Vector(dash.target)
		end

		dashDB[hero.name] = {endTime = GetTick() + dash.duration * 1000, startPos = dash.startPos, endPos = dash.endPos, target= dash.target, speed=dash.speed }
	end
	end
end

function GetCondemCollisionTime (target)
	
	local heroObj = heroDirDB[target.name]
	
	if heroObj.dir ~= Vector(0,0,0) then
	
	if heroObj.lastAngle and heroObj.lastAngle < .8 then
		return nil
	end
	
	
	local windupPos = Vector(target) + heroObj.dir * (target.ms * 250/1000)
	local timeElapsed = GetCollisionTime(windupPos, heroObj.dir, target.ms, myHero, 1600 )
	
	if timeElapsed == nil then
		return nil
	end

	return Vector(target) + heroObj.dir * target.ms * (timeElapsed + .25)/2
	
	end
	
	return Vector(target)
end

function OnDraw ()
	UpdateHeroDirection()

	if myHero:CanUseSpell(_E) == READY then

	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)	
		
		if ValidTarget(hero, 675) 
			and Menu.HeroSettings[hero.charName]
			and myHero:CanUseSpell(_E) == READY then
			
			local predPosition = GetCondemCollisionTime(hero)
			
			if predPosition and not IsWall(D3DXVECTOR3(predPosition.x, predPosition.y, predPosition.z)) then
					
			local checkHeroDistance = Menu.CondemnSettings.CheckDistance
			local heroChecks = Menu.CondemnSettings.Checks
			local AllInsideWall = true
			local checkCount = 0
			local sumCheckDist = 0
			
			for i= -math.floor(heroChecks/2), math.floor(heroChecks/2), 1 do
			checkCount = checkCount + 1
			
			local enemyPosition = predPosition + (Vector(enemyPosition) - Vector(myHero)):normalized()*(checkHeroDistance*i)
			
			local checkDistance = 50
			local checks = math.ceil(425/checkDistance)            
            local InsideTheWall = false
			local checksPos = nil
			
            for k=1, checks, 1 do
                checksPos = enemyPosition + (Vector(enemyPosition) - Vector(myHero)):normalized()*(checkDistance*k)
                				
				if IsWall(D3DXVECTOR3(checksPos.x, checksPos.y, checksPos.z)) then
                    InsideTheWall = true
                    break
                end					
            end
			
			if InsideTheWall then
					
				if Menu.DrawCondem then
				DrawLine3D(hero.x, hero.y, hero.z, checksPos.x, checksPos.y, checksPos.z, 5, 0xFFFF0000)
				end
			else
				AllInsideWall = false
				
				if Menu.DrawCondem then
				DrawLine3D(hero.x, hero.y, hero.z, checksPos.x, checksPos.y, checksPos.z, 5, 0xFF00FF00)
				end
			end

			sumCheckDist = sumCheckDist + GetDistance(checksPos, myHero)
			
			end
			
			if AllInsideWall then
			if Menu.AutoCondem and sumCheckDist/checkCount < Menu.CondemnSettings.MaxDistance
				and GetDistance(hero) < sumCheckDist/checkCount then
				CastSpell(_E, hero)
			end
			end
			
			end
		end		
	end
	
	if Menu.AutoPush then
	for heroName, dash in pairs(dashDB) do
		if GetTick() < dash.endTime then
			if dash.endPos and GetDistance(dash.endPos, myHero) < 200 then
				local hero = GetHeroByName(heroName)
				if ValidTarget(hero, 700) then
				CastSpell(_E, hero)
				end
			end
		else
			dashDB[heroName] = nil
		end
	end
	end
	
	end
end

function GetHeroByName (name)
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)	
		if hero.name == name then
			return hero
		end			
	end
	
	return nil
end

function GetCollisionTime (targetPos, targetDir, targetSpeed, sourcePos, projSpeed )
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