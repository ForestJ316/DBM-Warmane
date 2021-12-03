local mod	= DBM:NewMod("Loatheb", "DBM-Naxx", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2568 $"):sub(12, -3))
mod:SetCreatureID(16011)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS",
	"SPELL_DAMAGE",
	"SWING_DAMAGE",
	"SPELL_SUMMON",
	"SPELL_AURA_APPLIED"
)

local warnSporeNow	= mod:NewSpellAnnounce(32329, 2)
local warnSporeSoon	= mod:NewSoonAnnounce(32329, 1)
local warnDoomNow	= mod:NewSpellAnnounce(29204, 3)
local warnHealSoon	= mod:NewAnnounce("WarningHealSoon", 4, 48071)
local warnHealNow	= mod:NewAnnounce("WarningHealNow", 1, 48071, false)


local timerSpore	= mod:NewNextTimer(12, 32329)
local timerDoom		= mod:NewNextTimer(30, 29204)
local timerAura		= mod:NewBuffActiveTimer(17, 55593)

mod:AddBoolOption("SporeDamageAlert", false)

local doomCounter	= 0

function mod:OnCombatStart(delay)
	local subZone = GetSubZoneText()
	if subZone == "The Necrotic Vault" then -- Fix for Loatheb timers appearing on other bosses
		doomCounter = 0
		timerSpore:Start(-delay)
		warnSporeSoon:Schedule(7-delay)
		timerDoom:Start(30 - delay, doomCounter + 1)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	--[[
	if args:IsSpellID(29234) then
		timerSpore:Start(12)
		warnSporeNow:Show()
		warnSporeSoon:Schedule(sporeTimer - 5)
	end
	]]
	if args:IsSpellID(29204, 55052) then  -- Inevitable Doom
		doomCounter = doomCounter + 1
		warnDoomNow:Show(doomCounter)
		timerDoom:Start(30, doomCounter + 1)
	--[[
	elseif args:IsSpellID(55593) then -- Necrotic aura
		timerAura:Start()
		warnHealSoon:Schedule(14)
		warnHealNow:Schedule(17)
	]]
	end
end

-- No SPELL_CAST_SUCCESS on this server for Necrotic Aura,
-- only SPELL_AURA_APPLIED and SPELL_AURA_REMOVED
function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(55593) and args:IsPlayer() then -- Necrotic aura
		timerAura:Start()
		warnHealSoon:Schedule(14)
		warnHealNow:Schedule(17)
	end
end

-- SPELL_SUMMON for spore on this server
function mod:SPELL_SUMMON(args)
	if args:IsSpellID(29234) then
		timerSpore:Start()
		warnSporeNow:Show()
		warnSporeSoon:Schedule(7)
	end
end

--Spore loser function. Credits to Forte guild and their old discontinued dbm plugins. Sad to see that guild disband, best of luck to them!
function mod:SPELL_DAMAGE(_, sourceName, _, _, destName, _, spellId, _, _, amount)
	if self.Options.SporeDamageAlert and destName == "Spore" and spellId ~= 62124 and self:IsInCombat() then
		SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "RAID_WARNING")
		SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "WHISPER", nil, sourceName)
	end
end

function mod:SWING_DAMAGE(_, sourceName, _, _, destName, _, _, _, _, amount)
	if self.Options.SporeDamageAlert and destName == "Spore" and self:IsInCombat() then
		SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "RAID_WARNING")
		SendChatMessage(sourceName..", You are damaging a Spore!!! ("..amount.." damage)", "WHISPER", nil, sourceName)
	end
end