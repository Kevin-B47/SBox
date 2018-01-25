include("shared.lua")

local white = Color(255,255,255)
local black = Color(0,0,0)

function ENT:Initialize()
	self.txtPos = {}
	self.nextPos = -70
	self.Txt = ""
	self.Tbl = {}
	self.NextCheck = 0
	self.goodToGo = false
	// 76561198005432357
end

function ENT:RebuildTxtTbl()
	if self.didCall then
		table.Empty(self.txtPos)
		self.nextPos = -70
		for k,v in ipairs(self.Tbl) do
			self.txtPos[k] = {char = v, pos = self.nextPos, length = GetSugarTextSize(v,"Default"), completed = false, visible = false}
			self.nextPos = self.nextPos - self.txtPos[k].length
		end
		self.didCall = false
		self.goodToGo = true
	end
end

function ENT:Draw()
	self:DrawModel()
	if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 62000 then return end
	
	local angs = self:GetAngles()
	angs:RotateAroundAxis(angs:Up(),90)
	angs:RotateAroundAxis(angs:Forward(),90)
	
	if self.NextCheck < CurTime() then
		self.NextCheck = CurTime() + .2
		local songName = self.SongName
		if songName and songName != self.Txt then
			self.Txt = songName
			self.didCall = true
			self.goodToGo = false
			self.Tbl = table.Reverse(string.ToTable(self.Txt))
			self:RebuildTxtTbl()
		end
	end
	
	
	if !self.goodToGo then return end
	cam.Start3D2D(self:GetPos()+self:GetUp()*4.1+self:GetForward()*3.8, angs, 0.08)
		local completed = 0
		for k,v in ipairs(self.txtPos) do
			if v.visible then
				draw.SimpleTextOutlined(v.char, "Default", v.pos, -6, white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, black)
			elseif v.pos >= -70 then
				v.visible = true
			end
			if v.pos >= 75 then
				v.completed = true
				completed = completed + 1
				v.visible = false
			else
				v.pos = v.pos + FrameTime()*45
			end
			if #self.txtPos > 0 and completed == #self.txtPos then
				self.didCall = true
				self:RebuildTxtTbl()
				break
			end
		end
	cam.End3D2D()
end
