local mod	= DBM:NewMod("Grobbulus", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4154 $"):sub(12, -3))
mod:SetCreatureID(15931)
mod:SetUsedIcons(5, 6, 7, 8)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"SPELL_CAST_SUCCESS",
	"SPELL_SUMMON"
)

local warnInjection			= mod:NewTargetAnnounce(28169, 2)
local warnCloud				= mod:NewSpellAnnounce(28240, 2)

local specWarnInjection		= mod:NewSpecialWarning("SpecialWarningInjection")
local yellInjection			= mod:NewYellMe(28169, nil, false)

local timerInjection		= mod:NewTargetTimer(10, 28169)
local timerCloud			= mod:NewNextTimer(10, 28240) -- old 15
local soundCloud			= mod:NewSound3(28240, nil, mod:IsMelee() or mod:IsTank())
local enrageTimer			= mod:NewBerserkTimer(720)

local warnSlimeSprayNow		= mod:NewSpellAnnounce(54364, 2)
local warnSlimeSpraySoon	= mod:NewSoonAnnounce(54364, 1)
local slimeSprayCD			= mod:NewCDTimer(20, 54364, nil, nil, nil, 2)

mod:AddBoolOption("SetIconOnInjectionTarget", true)

local mutateIcons = {}

local function addIcon()
	for i,j in ipairs(mutateIcons) do
		local icon = 9 - i
		mod:SetIcon(j, icon)
	end
end

local function removeIcon(target)
	for i,j in ipairs(mutateIcons) do
		if j == target then
			table.remove(mutateIcons, i)
			mod:SetIcon(target, 0)
		end
	end
	addIcon()
end

function mod:OnCombatStart(delay)
	table.wipe(mutateIcons)
	enrageTimer:Start(-delay)
	soundCloud:Schedule(15-3)
	timerCloud:Start(15)
	warnSlimeSpraySoon:Schedule(5)
	slimeSprayCD:Start(10)
end

function mod:OnCombatEnd()
    for i,j in ipairs(mutateIcons) do
       mod:SetIcon(j, 0)
    end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28169) then
		warnInjection:Show(args.destName)
		timerInjection:Start(args.destName)
		if args:IsPlayer() then
			specWarnInjection:Show()
			yellInjection:Yell()
		end
		if self.Options.SetIconOnInjectionTarget then
			table.insert(mutateIcons, args.destName)
			addIcon()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(28169) then
		timerInjection:Cancel(args.destName)--Cancel timer if someone is dumb and dispels it.
		if self.Options.SetIconOnInjectionTarget then
			removeIcon(args.destName)
		end
	end
end

-- SPELL_SUMMON event on this server
function mod:SPELL_SUMMON(args)
	-- Source name Grobbulus on clouds under him
	-- For mutagen explosion clouds source name is player name for the SPELL_SUMMON event
	if args:IsSpellID(28240) and args.sourceName == "Grobbulus" then
		warnCloud:Show()
		timerCloud:Start()
		soundCloud:Schedule(10-3) -- old 15-3
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28157, 54364) then
		warnSlimeSprayNow:Show()
		warnSlimeSpraySoon:Schedule(15)
		slimeSprayCD:Start()
	end
	--[[
	if args:IsSpellID(28240) then
		warnCloud:Show()
		timerCloud:Start()
		soundCloud:Schedule(15-3)
	end
	]]
end
