local mod	= DBM:NewMod("Anub'Rekhan", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4902 $"):sub(12, -3))
mod:SetCreatureID(15956)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_AURA_REMOVED",
	"UNIT_DIED",
	"SPELL_CAST_SUCCESS"
)

local warningLocustSoon		= mod:NewSoonAnnounce(28785, 2)
local warningLocustNow		= mod:NewSpellAnnounce(28785, 3)
local warningLocustFaded	= mod:NewAnnounce("WarningLocustFaded", 1, 28785)

local specialWarningLocust	= mod:NewSpecialWarning("SpecialLocust")

local timerLocustIn			= mod:NewCDTimer(50, 28785)
local timerLocustFade 		= mod:NewBuffActiveTimer(43, 28785) -- 40s instead of regular 20s for Locust Swarm

local warnImpaleNow			= mod:NewSpellAnnounce(56090, 1)
local warnImpaleSoon		= mod:NewSoonAnnounce(56090, 2)
local timerImpale			= mod:NewCDTimer(20, 56090, nil, nil, nil, 2)

mod:AddBoolOption("ArachnophobiaTimer", true, "timer")


function mod:OnCombatStart(delay)
	warningLocustSoon:Schedule(85 - delay)
	timerLocustIn:Start(90 - delay) -- Seems to be random from 90-115, perhaps based on spikes
	if mod:IsDifficulty("normal10") then
		warnImpaleSoon:Schedule(30 - delay)
		timerImpale:Start(35 - delay)
	else
		warnImpaleSoon:Schedule(10 - delay)
		timerImpale:Start(15 - delay)
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(28785, 54021) then  -- Locust Swarm
		warningLocustNow:Show()
		specialWarningLocust:Show()
		timerLocustIn:Stop()
		timerLocustFade:Start(43)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28783, 56090) then -- Impale
		warnImpaleNow:Show()
		 -- No idea if this event is fired on 10-man, maybe only SPELL_CAST_START like on 4 Horsemen meteor
		if mod:IsDifficulty("normal10") then
			warnImpaleSoon:Schedule(30)
			timerImpale:Start(35)
		else
			warnImpaleSoon:Schedule(15)
			timerImpale:Start()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(28785, 54021)
	and args.auraType == "BUFF" then
		warningLocustFaded:Show()
		timerLocustIn:Start()
		warningLocustSoon:Schedule(42)
		timerLocustIn:Start(47)
	end
end

function mod:UNIT_DIED(args)
	if self.Options.ArachnophobiaTimer and not DBM.Bars:GetBar(L.ArachnophobiaTimer) then
		local guid = tonumber(args.destGUID:sub(9, 12), 16)
		if guid == 15956 then		-- Anub'Rekhan
			DBM.Bars:CreateBar(1200, L.ArachnophobiaTimer)
		end
	end
end
