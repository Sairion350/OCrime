ScriptName OCrimeScript extends Quest

import OUtils

OsexIntegrationMain ostim
ODatabaseScript odatabase
actor playerref
spell CrimeSpell
spell SoundSpell

 

bool property bountySet auto

int Property bountyPrice
	int Function Get()
		return StorageUtil.GetIntValue(none, "ocrime.bounty")
	EndFunction
EndProperty

bool Property IsCrimeAggressive
	bool Function Get()
		if ostim.AnimationRunning()
			return ostim.IsSceneAggressiveThemed()
		else 
			return aggressiveOverride
		endif 
	EndFunction
EndProperty

Event OnInit()
	ostim = GetOStim()
	if ostim.GetAPIVersion() < 16
		debug.MessageBox("Your OStim version is out of date. OCrime requires a newer version.")
		return
	endif
	CrimeSpell = game.GetFormFromFile(0x00802, "Ocrime.esp") as spell

	bountyset = false
	gotNaked = false 
	playerref = game.GetPlayer()

	RegisterForModEvent("ostim_start", "Ostimstart")
	ostim.RegisterForGameLoadEvent(self)
	OUtils.RegisterForOUpdate(self)

	StorageUtil.SetIntValue(none, "ocrime.bounty", 200)


	load()

	Debug.Notification("OCrime installed")
EndEvent

bool gotNaked
actor dom
int volume
Event Ostimstart(string eventName, string strArg, float numArg, Form sender)
	console("OCrime recieved start event")

	gotNaked = false 
	bountySet = False

	bool aggressive = ostim.IsSceneAggressiveThemed()

	if !aggressive
		if ostim.IsBed(ostim.GetBed())
			console("OCrime: scene is taking place on a bed. assuming legal & exiting")
			return
		endif

		volume = 40
		dom = ostim.GetDomActor()
	else 
		dom = ostim.GetAggressiveActor()
		volume = 90
	endif 

	actor[] acts = ostim.GetActors()
	int i = 0
	int l = acts.Length
	while i < l
		if acts[i].IsGuard()
			Console("Scene contains a guard, ocrime closing")
			return 
		endif 

		i += 1
	EndWhile


	
	RegisterForSingleUpdate(5)
EndEvent


Event OnUpdate()
	if ostim.AnimationRunning()
		RunOCrime(dom, volume)

		RegisterForSingleUpdate(5)
	Else
		console("Closing OCrime")
	endif 
EndEvent

bool aggressiveOverride
Function RunOCrime(actor MainActor, int loudness, bool SpecialCall = false)
	if SpecialCall
		bountySet = false
		aggressiveOverride = True
	Else
		aggressiveOverride = false
	endif

	MainActor.CreateDetectionEvent(MainActor, loudness)
	if gotNaked || ostim.IsNaked(MainActor) || SpecialCall
		gotNaked = true
		CrimeSpell.Cast(MainActor)
	endif 
EndFunction

Function AttemptReportCrime(actor guard, actor criminal, bool agg = true)
	{Callback for the magic effect}

	if ostim.IsActorInvolved(guard)
		Return 
	endif

	bool aggressive 
	if ostim.AnimationRunning()
		aggressive = ostim.IsSceneAggressiveThemed()
	else 
		aggressive = agg
	endif 

	if !bountySet
		bountyset = true

		if criminal == playerref
			;console("Setting crime bounty")
			
			
			int bounty
			if aggressive
				bounty = bountyPrice * 4 
			else 
				bounty = bountyPrice
			endif 

			AddBounty(bounty, guard.GetCrimeFaction(), violent = aggressive)	

		endif

		if !aggressive
			InterruptScene(guard, criminal)
		endif 
	endif

	if aggressive
		guard.StartCombat(criminal)
	endif 

EndFunction

Function InterruptScene(actor guard, actor criminal)
	ReferenceAlias criref = (self.GetNthAlias(1) as ReferenceAlias)
	ReferenceAlias guardref = (self.GetNthAlias(2) as ReferenceAlias)
	criref.ForceRefTo(criminal)
	guardref.ForceRefTo(guard)

	while (ostim.AnimationRunning()) && (guard.GetDistance(criminal) > 400)
		Utility.Wait(1)
	endwhile

	if ostim.AnimationRunning() 
		debug.SendAnimationEvent(guard, "IdleWave")
		utility.wait(1)
		; guard is here, end it
		ostim.EndAnimation(false)
		if ostim.IsPlayerInvolved()
			debug.Notification(OSANative.GetDisplayName(guard) + " is breaking things up")
		endif 
	endif 

	criref.Clear()
	guardref.clear()
EndFunction

Function AddBounty(int amount, Faction crimeFaction, bool silent = false, bool violent = true)

	crimeFaction.ModCrimeGold(amount, violent)

	if !silent
		Debug.Notification(amount + " bounty added to " + OSANative.GetName(crimeFaction))
	endif

	console(amount + " bounty added to " + OSANative.GetName(crimeFaction))

EndFunction

Event CustomCrime(form criminal, bool violent)
	RunOCrime(criminal as actor, 90, true)
EndEvent

Event OnGameLoad()
	load()
EndEvent

Function load()
	console("Using OCrime cosave fix")
	RegisterForModEvent("ostim_start", "Ostimstart")
	RegisterForModEvent("ocrime_crime", "CustomCrime")
EndFunction

