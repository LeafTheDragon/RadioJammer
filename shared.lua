-- Radio Jammer blocks all voice and text chat, except for
-- detectives who have radio frequency 42Hz.
-- Lasts for 30secs or until destroyed.
local config = ttt_perky_config

SWEP.Base					= "weapon_tttbase"
SWEP.HoldType				= "normal"

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo       	= "none"
SWEP.Primary.Delay 			= 1.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo     	= "none"
SWEP.Secondary.Delay 		= 1.0

SWEP.IronSightsPos = Vector( 6.05, -5, 2.4 )
SWEP.IronSightsAng = Vector( 2.2, -0.1, 0 )
SWEP.ViewModel  = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/props_lab/reciever01b.mdl"

--- TTT config values
SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_radiojammer_ttt"
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = config.radiojammer_limited_stock
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true

local throwsound = Sound( "Weapon_SLAM.SatchelThrow" )

if SERVER then
	AddCSLuaFile( "shared.lua" )
	resource.AddFile("materials/VGUI/ttt/icon_radiojammer.vmt")
end

if CLIENT then
	SWEP.PrintName = "Radio Jammer"
	SWEP.Slot      = 7 -- add 1 to get the slot number key

	SWEP.ViewModelFOV  = 10
	SWEP.ViewModelFlip = false

	-- Path to the icon material
	SWEP.Icon = "VGUI/ttt/icon_radiojammer"

	-- Text shown in the equip menu
	SWEP.EquipMenuData = {
	   type = "Weapon",
	   desc = "Place a radio jammer that blocks all \nvoice and text chat for "..config.radiojammer_duration.." seconds. \nThe radio jammer emits a loud noise and \ndetectives can talk on a different frequency!"
	}
end

function SWEP:OnDrop()
   self:Remove()
end

function SWEP:Deploy()
   self.Owner:DrawViewModel(false)
   return true
end

function SWEP:DrawWorldModel()
   return false
end

function SWEP:Initialize()
	if CLIENT then
		self:AddHUDHelp(
			"MOUSE1 Places the radio jammer",
			"",
			false
		)
	end
end

function SWEP:PrimaryAttack()
	if SERVER then
		self:RadioJammerDrop()
		self:Remove()
	end
	self:TakePrimaryAmmo( 1 )
end

function SWEP:SecondaryAttack()
	if SERVER then
		self:RadioJammerStick()
	end
	self:TakePrimaryAmmo( 1 )
end

function SWEP:RadioJammerDrop()
	   
   if SERVER then
      local ply = self.Owner
      if not IsValid(ply) then return end

      if self.Planted then return end

      local vsrc = ply:GetShootPos()
      local vang = ply:GetAimVector()
      local vvel = ply:GetVelocity()
      
      local vthrow = vvel + vang * 200

      local radio = ents.Create("ttt_radiojammer")
      if IsValid(radio) then
         radio:SetPos(vsrc + vang * 10)
         radio:SetOwner(ply)
         radio:Spawn()

         radio:PhysWake()
         local phys = radio:GetPhysicsObject()
         if IsValid(phys) then
            phys:SetVelocity(vthrow)
         end   
         self:Remove()

         self.Planted = true
      end
   end

   self.Weapon:EmitSound(throwsound)
end

function SWEP:RadioJammerStick()
   if SERVER then
      local ply = self.Owner
      if not ValidEntity(ply) then return end

      if self.Planted then return end

      local ignore = {ply, self.Weapon}
      local spos = ply:GetShootPos()
      local epos = spos + ply:GetAimVector() * 80
      local tr = util.TraceLine({start=spos, endpos=epos, filter=ignore, mask=MASK_SOLID})

      if tr.HitWorld then
         local radio = ents.Create("ttt_radiojammer")
         if ValidEntity(radio) then
            radio:PointAtEntity(ply)

            local tr_ent = util.TraceEntity({start=spos, endpos=epos, filter=ignore, mask=MASK_SOLID}, radio)

            if tr_ent.HitWorld then

               local ang = tr_ent.HitNormal:Angle()
               ang:RotateAroundAxis(ang:Up(), -180)

               radio:SetPos(tr_ent.HitPos + ang:Forward() * -2.5)
               radio:SetAngles(ang)
               radio:SetOwner(ply)
               radio:Spawn()
			   ply.radiojammer = radio

               local phys = radio:GetPhysicsObject()
               if ValidEntity(phys) then
                  phys:EnableMotion(false)
               end

               radio.IsOnWall = true
               self.Planted = true
				self:Remove()
            end
         end
      end
   end
end
