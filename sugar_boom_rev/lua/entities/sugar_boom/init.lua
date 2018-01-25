AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/boombox/boombox_01.mdl")
	self:PhysicsInit(SOLID_VPHYSICS) 
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	phys:Wake()
	phys:SetMass(100)
	self.StopTime = 0
	self.HealthMe = 200
	self:SetSkin(1)
end

function ENT:Use(activator,caller)
	if self.StopTime > CurTime() or (self.Locked and IsValid(self:Getowning_ent()) and self:Getowning_ent() != activator) then return false end
	if IsValid(activator) then
		self.StopTime = CurTime() + 1
		local canOpen = hook.Call("canOpenBoomboxmenu",GAMEMODE,self,activator)
		if canOpen then
			// 76561198005432357
			net.Start("sugar_boom_mod")
			net.WriteUInt(2,2)
			net.WriteEntity(self)
			net.Send(activator)
		end
	end
end

function ENT:OnRemove()
	net.Start("sugar_boom_mod")
    net.WriteUInt(0,2)
	net.WriteEntity(self)
    net.Broadcast()
end

function ENT:OnTakeDamage(dmg)
	if self.HealthMe - dmg:GetDamage() > 0 then
		self.HealthMe = self.HealthMe - dmg:GetDamage()
	elseif !self.Explode then
		self.Explode = true
		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetMagnitude(10)
		effectdata:SetScale(10)
		self:EmitSound( "weapon_AWP.Single", 400, 400 )
		util.Effect( "Explosion", effectdata )
		self:Remove()
	end
end
