Scriptname AUAFollowerQuestScript extends Quest

AUAQuestScript property AUA auto
Keyword property ActorTypeNPC auto
ReferenceAlias[] property SelfFollowerAliasRefs auto

Bool bGameLoaded = true
Bool property GameLoaded hidden
	Bool Function Get()
		if bGameLoaded
			bGameLoaded = false
			return true
		else
			return false
		endif
	EndFunction
	Function Set(bool value)
		bGameLoaded = value
		RegisterForSingleUpdate(5)
	EndFunction
EndProperty

Quest FollowerQuestSource
ReferenceAlias[] OtherFollowerAliasRefs

Import Game

Event OnInit()
	RegisterForSingleUpdate(1)
EndEvent

Event OnUpdate()
	if !IsRunning()
		return
	endif

	bool followerNotFound
	int selfFirstEmptyAliasIndex
	int selfAliasIndex
	int otherAliasIndex
	Actor FollowerRef

	; detect follower source quest and fetch follower reference aliases - only on game load
	if GameLoaded
		OtherFollowerAliasRefs = new ReferenceAlias[25]	; Create new array
		if AUA.EFFOK
			FollowerQuestSource = GetFormFromFile(0xeff, "EFFCore.esm") as Quest	; EFF - FollowerExtension quest
		else
			FollowerQuestSource = GetForm(0x000750ba) as Quest	; DialogueFollower quest
		endif
		; incrementally search for alias IDs in source quest
		ReferenceAlias sourceRefAlias
		int numAliasIDs = 30	; probe source quest for this many IDs
		int curAliasID = 0
		otherAliasIndex = 0
		while curAliasID < numAliasIDs && otherAliasIndex < OtherFollowerAliasRefs.length
			if !AUA.EFFOK && curAliasID == 1	; skip if animal follower in DialogueFollower quest
				curAliasID += 1
			endif
			sourceRefAlias = FollowerQuestSource.GetAlias(curAliasID) as ReferenceAlias
			if sourceRefAlias
				OtherFollowerAliasRefs[otherAliasIndex] = sourceRefAlias
				otherAliasIndex += 1
			endif
			curAliasID += 1
		endwhile
	endif
	
	; add recruited followers
	otherAliasIndex = 0
	while otherAliasIndex < OtherFollowerAliasRefs.length && OtherFollowerAliasRefs[otherAliasIndex]
		FollowerRef = OtherFollowerAliasRefs[otherAliasIndex].GetActorReference()
		if FollowerRef
			if FollowerRef.HasKeyword(ActorTypeNPC)
				followerNotFound = true
				selfFirstEmptyAliasIndex = -1
				selfAliasIndex = 0
				; see if there is a match
				while selfAliasIndex < SelfFollowerAliasRefs.length
					; Remember the first empty alias
					if !SelfFollowerAliasRefs[selfAliasIndex].GetActorReference() && selfFirstEmptyAliasIndex < 0
						selfFirstEmptyAliasIndex = selfAliasIndex
					endif
					; Check if actor is already assigned
					if SelfFollowerAliasRefs[selfAliasIndex].GetActorReference() == FollowerRef
						followerNotFound = false
					endif
					selfAliasIndex += 1
				endwhile
				; add new follower if no match
				if followerNotFound && selfFirstEmptyAliasIndex >= 0
					SelfFollowerAliasRefs[selfFirstEmptyAliasIndex].ForceRefTo(FollowerRef)
				endif
			endif
		endif
		otherAliasIndex += 1
	endwhile

	; remove dismissed followers
	selfAliasIndex = 0
	while selfAliasIndex < SelfFollowerAliasRefs.length
		FollowerRef = SelfFollowerAliasRefs[selfAliasIndex].GetActorReference()
		if FollowerRef
			followerNotFound = true
			otherAliasIndex = 0
			while otherAliasIndex < OtherFollowerAliasRefs.length && OtherFollowerAliasRefs[otherAliasIndex] && followerNotFound
				if OtherFollowerAliasRefs[otherAliasIndex].GetActorReference() == FollowerRef
					followerNotFound = false
				endif
				otherAliasIndex += 1
			endwhile
			if followerNotFound
				SelfFollowerAliasRefs[selfAliasIndex].Clear()
			endif
		endif
		selfAliasIndex += 1
	endwhile

	RegisterForSingleUpdate(30)
EndEvent
