ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "BoomBox"
ENT.Author = "Sugar"
ENT.Spawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Entity",0,"owning_ent")
end