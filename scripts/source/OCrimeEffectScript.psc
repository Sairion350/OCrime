Scriptname OCrimeEffectScript extends activemagiceffect  

OCrimeScript ocrime


Event OnEffectStart(Actor akTarget, Actor akCaster)

	

	if akCaster.IsDetectedBy(akTarget) || (akCaster.GetDistance(akTarget) < 512)
		;OUtils.Console("Spotted by NPC: " + akTarget.GetDisplayName())

		akTarget.SetLookAt(akCaster)
		if !((akTarget).GetCrimeFaction() as Bool)
			;OUtils.Console("Observing NPC has no crime faction")
			return
		endif

		ocrime = game.GetFormFromFile(0x000801, "OCrime.esp") as OCrimeScript
		if akTarget.IsGuard()
			(ocrime).AttemptReportCrime(akTarget, akcaster)
			if ocrime.IsCrimeAggressive
				akTarget.StartCombat(akCaster) 
			endif 
		elseif ocrime.IsCrimeAggressive
			if (akTarget.GetActorValue("Confidence") > 0) && (!outils.AppearsFemale(akTarget) || (akTarget.GetLevel() > 9))	&& !akTarget.IsPlayerTeammate()
				akTarget.StartCombat(akCaster)
			endif 
		endif
	endif
endevent