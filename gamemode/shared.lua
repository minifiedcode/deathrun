DeriveGamemode( "base" )

local lp = LocalPlayer

GM.Name 	= "Deathrun"
GM.Author 	= "Mr. Gash"
GM.Email 	= ""
GM.Website 	= "nonerdsjustgeeks.com"

function GM:CreateTeams()
	TEAM_DEATH = 2
	team.SetUp( TEAM_DEATH, "Death", Color( 180, 60, 60, 255 ), false )
	team.SetSpawnPoint( TEAM_DEATH, "info_player_terrorist" )

	TEAM_RUNNER = 3
	team.SetUp( TEAM_RUNNER, "Runner", Color( 60, 60, 180, 255 ), false )
	team.SetSpawnPoint( TEAM_RUNNER, "info_player_counterterrorist" )

	team.SetUp( TEAM_SPECTATOR, "Spectator", Color( 125, 125, 125, 255 ), true )
end

local meta = FindMetaTable( "Player" )

function GM:PhysgunPickup( ply, ent )
	if not ply:IsSuperAdmin() then return false end
	if not IsValid(ent) then return false end
	if not ent:IsWeapon() then return false end
	return true
end

function GM:PlayerNoClip( ply, on )
	if not ply:IsAdmin() then return false end

	if SERVER then
		PrintMessage( HUD_PRINTCONSOLE, "Admin '"..ply:Nick().."' has "..(on and "enabled" or "disabled").." noclip." )
	end
	return true
end

function GM:PlayerUse( ply )
	if not ply:Alive() then return false end

	return true
end

function GM:GetRound()
	return GetGlobalInt( "Deathrun_RoundPhase" )
end

function GM:GetRoundTime()
	return math.Round(math.max( GetGlobalInt( "Deathrun_RoundTime" ) - CurTime(), 0 ))
end

meta.OldAlive = meta.OldAlive or meta.Alive

function meta:Alive()
	if self:Team() == TEAM_SPECTATOR then return false end

	return self:OldAlive()
end

-- Thanks BlackAwps!
function string.FormattedTime( seconds, Format )
	if not seconds then seconds = 0 end
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds / 60) % 60)
	local millisecs = ( seconds - math.floor( seconds ) ) * 100
	seconds = seconds % 60
    
	if Format then
		return string.format( Format, minutes, seconds, millisecs )
	else
		return { h=hours, m=minutes, s=seconds, ms=millisecs }
	end
end

-- Credit: AzuiSleet
-- maybe.
-- It's old, I don't remember who made it. 90% sure it was AzuiSleet.
local lp, ft, ct, cap = LocalPlayer, FrameTime, CurTime
local mc, mr, bn, ba, bo, gf = math.Clamp, math.Round, bit.bnot, bit.band, bit.bor, {}
function GM:Move( ply, data )

	-- fixes jump and duck stop
	local og = ply:IsFlagSet( FL_ONGROUND )
	if og and not gf[ ply ] then
		gf[ ply ] = 0
	elseif og and gf[ ply ] then
		gf[ ply ] = gf[ ply ] + 1
		if gf[ ply ] > 4 then
			ply:SetDuckSpeed( 0.4 )
			ply:SetUnDuckSpeed( 0.2 )
		end
	end

	if og or not ply:Alive() then return end
	
	gf[ ply ] = 0
	ply:SetDuckSpeed(0)
	ply:SetUnDuckSpeed(0)

	if not IsValid( ply ) then return end
	if lp and ply ~= lp() then return end
	
	if ply:IsOnGround() or not ply:Alive() then return end
	
	local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = data:GetForwardSpeed()
	local smove = data:GetSideSpeed()
	
	if data:KeyDown( IN_MOVERIGHT ) then smove = smove + 500 end
	if data:KeyDown( IN_MOVELEFT ) then smove = smove - 500 end
	
	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local wishvel = forward * fmove + right * smove
	wishvel.z = 0

	local wishspeed = wishvel:Length()
	if wishspeed > data:GetMaxSpeed() then
		wishvel = wishvel * (data:GetMaxSpeed() / wishspeed)
		wishspeed = data:GetMaxSpeed()
	end

	local wishspd = wishspeed
	wishspd = mc( wishspd, 0, 30 )

	local wishdir = wishvel:GetNormal()
	local current = data:GetVelocity():Dot( wishdir )

	local addspeed = wishspd - current
	if addspeed <= 0 then return end

	local accelspeed = 1000 * ft() * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end
	
	local vel = data:GetVelocity()
	vel = vel + (wishdir * accelspeed)

	if ply.AutoJumpEnabled == true and GetConVar("dr_allow_autojump"):GetBool() == true and GetConVar("dr_autojump_velocity_cap"):GetFloat() ~= 0 then
		ply.SpeedCap = GetConVar("dr_autojump_velocity_cap"):GetFloat()
	else
		ply.SpeedCap = 99999
	end

	
	if ply.SpeedCap and vel:Length2D() > ply.SpeedCap and SERVER then
		local diff = vel:Length2D() - ply.SpeedCap
		vel:Sub( Vector( vel.x > 0 and diff or -diff, vel.y > 0 and diff or -diff, 0 ) )
	end
	
	data:SetVelocity( vel )
	return false
end

local band = bit.band

function GM:SetupMove( ply, data )
	if lp and ply ~= lp() then return end
	if ply.AutoJumpEnabled == false or GetConVar("dr_allow_autojump"):GetBool() == false then return end
	
	local ButtonData = data:GetButtons()
	if band( ButtonData, IN_JUMP ) > 0 then
		
		if ply:WaterLevel() < 2 and ply:GetMoveType() ~= MOVETYPE_LADDER and not ply:IsOnGround() then
			data:SetButtons( band( ButtonData, bit.bnot( IN_JUMP ) ) )
		end
	end
	
end