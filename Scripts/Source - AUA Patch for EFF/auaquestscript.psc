Scriptname AUAQuestScript extends Quest

Import Game
Import Debug

ReferenceAlias property Alias_Ammo auto

GlobalVariable property AUACustomAmmoClear auto
GlobalVariable property AUAEquipSetsClear auto

FormList property AUAArrowList auto
FormList property AUABoltList auto
FormList property AUAOtherList auto

FormList property AUACustomArrowList auto
FormList property AUACustomBoltList auto
FormList property AUACustomOtherList auto

FormList[] property FullAmmoList auto

Message property AUAAmmoClassificationMenu auto
Message property AUAInvalidEntryNotification auto
Message property AUAAmmoPurgeNotification auto
Message property AUAEquipSetPurgeNotification auto

Bool property SkyUIOK auto hidden
Bool property DawnguardOK auto hidden
Bool property DragonbornOK auto hidden
Bool property EFFOK auto hidden

Bool bGameLoaded = true
Bool property GameLoaded hidden
	Bool Function Get()
		if bGameLoaded
			Trace("========== Auto Unequip Ammo: Scanning for supported plugins...")
			Trace("========== ERRORS RELATED TO MISSING FILES SHOULD BE IGNORED!")
			SkyUIOK = (GetFormFromFile(0x814, "SkyUI.esp") as Quest) as Bool	; SKI_MainInstance
			DawnguardOK = (GetFormFromFile(0x2c09, "Dawnguard.esm") as Quest) as Bool	; DLC1Init
			DragonbornOK = (GetFormFromFile(0x16e02, "Dragonborn.esm") as Quest) as Bool	; DLC2Init
			EFFOK = (GetFormFromFile(0xeff, "EFFCore.esm") as Quest) as Bool	; FollowerExtension
			Trace("========== Auto Unequip Ammo: Scan complete.")

			bGameLoaded = false
			return true
		else
			return false
		endif
	EndFunction
	Function Set(bool value)
		bGameLoaded = value
		RegisterForSingleUpdate(0)
	EndFunction
EndProperty

Weapon[] EquipSetWeapons
Ammo[] EquipSetAmmo
int EquipSetIndexCursor


Event OnInit()
	if IsRunning()
		DefineEquipSetArrays()
	endif

	RegisterForSingleUpdate(1)
EndEvent

Event OnUpdate()
	if !IsRunning()
		return
	endif

	if GameLoaded
		InitializeExternalResources()
		if !CheckCustomAmmo(true)
			RevertCustomAmmo(true)
		endif
	endif
	
	if AUACustomAmmoClear.GetValueInt()
		RevertCustomAmmo(true)
		AUACustomAmmoClear.SetValueInt(0)
	endif

	if AUAEquipSetsClear.GetValueInt()
		DefineEquipSetArrays(true)
		AUAEquipSetsClear.SetValueInt(0)
	endif
	
	if !SkyUIOK
		RegisterForSingleUpdate(5)
	endif
EndEvent

Function DefineEquipSetArrays(bool abShowNotification = false)
	EquipSetWeapons = new Weapon[50]
	EquipSetAmmo = new Ammo[50]
	EquipSetIndexCursor = 0
	if abShowNotification
		AUAEquipSetPurgeNotification.Show()
	endif
EndFunction

Function RevertCustomAmmo(bool abShowNotification = false)
	AUACustomArrowList.Revert()
	AUACustomBoltList.Revert()
	AUACustomOtherList.Revert()
	if abShowNotification
		AUAAmmoPurgeNotification.Show()
	endif
EndFunction

Function InitializeExternalResources()
	; Reset all formlists
	AUAArrowList.Revert()
	AUABoltList.Revert()
	AUAOtherList.Revert()
	
	; Dawnguard resources
	if DawnguardOK
		AUAArrowList.AddForm(GetFormFromFile(0x98a0, "Dawnguard.esm"))	; DLC1ElvenArrowBlood
		AUAArrowList.AddForm(GetFormFromFile(0x98a1, "Dawnguard.esm"))	; DLC1ElvenArrowBlessed
		AUAArrowList.AddForm(GetFormFromFile(0x176f4, "Dawnguard.esm"))	; DLC1DragonboneArrow

		AUABoltList.AddForm(GetFormFromFile(0xd099, "Dawnguard.esm"))	; DLC1BoltDwarven
		AUABoltList.AddForm(GetFormFromFile(0xf1b1, "Dawnguard.esm"))	; DLC1BoltDwarvenExplodingFire
		AUABoltList.AddForm(GetFormFromFile(0xf1b7, "Dawnguard.esm"))	; DLC1BoltDwarvenExplodingIce
		AUABoltList.AddForm(GetFormFromFile(0xf1b9, "Dawnguard.esm"))	; DLC1BoltDwarvenExplodingShock
		AUABoltList.AddForm(GetFormFromFile(0xbb3, "Dawnguard.esm"))	; DLC1BoltSteel
		AUABoltList.AddForm(GetFormFromFile(0xf1a0, "Dawnguard.esm"))	; DLC1BoltSteelExplodingFire
		AUABoltList.AddForm(GetFormFromFile(0xf1bb, "Dawnguard.esm"))	; DLC1BoltSteelExplodingIce
		AUABoltList.AddForm(GetFormFromFile(0xf1bc, "Dawnguard.esm"))	; DLC1BoltSteelExplodingShock

		AUAOtherList.AddForm(GetFormFromFile(0x1a958, "Dawnguard.esm"))	; DLC1ElderScrollBack
		AUAOtherList.AddForm(GetFormFromFile(0xff03, "Dawnguard.esm"))	; DLC1SoulCairnKeeperArrow
		AUAOtherList.AddForm(GetFormFromFile(0x590c, "Dawnguard.esm"))	; TestDLC1Bolt
	endif

	; Dragonborn resources
	if DragonbornOK
		AUAArrowList.AddForm(GetFormFromFile(0x17720, "Dragonborn.esm"))	; DLC2RieklingSpearThrown
		AUAArrowList.AddForm(GetFormFromFile(0x26239, "Dragonborn.esm"))	; DLC2StalhrimArrow
		AUAArrowList.AddForm(GetFormFromFile(0x2623b, "Dragonborn.esm"))	; DLC2NordicArrow

		AUAOtherList.AddForm(GetFormFromFile(0x1aecf, "Dragonborn.esm"))	; DLC2BloodskalAmmo
		AUAOtherList.AddForm(GetFormFromFile(0x339a1, "Dragonborn.esm"))	; DLC2DwarvenBallistaBolt
	endif
EndFunction

Bool Function CheckCustomAmmo(bool abShowNotification = false)
	int index
	bool IsAmmoValid = true

	; Check for invalid arrow entries
	index = 0
	while index < AUACustomArrowList.GetSize() && IsAmmoValid
		if !AUACustomArrowList.GetAt(index)
			IsAmmoValid = false
		endif
		index += 1
	endwhile

	; Check for invalid bolt entries
	index = 0
	while index < AUACustomBoltList.GetSize() && IsAmmoValid
		if !AUACustomBoltList.GetAt(index)
			IsAmmoValid = false
		endif
		index += 1
	endwhile

	; Check for invalid other entries
	index = 0
	while index < AUACustomOtherList.GetSize() && IsAmmoValid
		if !AUACustomOtherList.GetAt(index)
			IsAmmoValid = false
		endif
		index += 1
	endwhile
	
	if !IsAmmoValid && abShowNotification
		AUAInvalidEntryNotification.Show()
	endif
	
	return IsAmmoValid
EndFunction

Function CreateEquipSet(Weapon akWeapon, Ammo akAmmo)
	; find existing weapon
	bool WeaponExists
	int index
	while index < EquipSetWeapons.length && !WeaponExists
		if EquipSetWeapons[index] == akWeapon
			WeaponExists = true
		else
			index += 1
		endif
	endwhile
	; if weapon is not found then use cursor position
	if !WeaponExists
		index = EquipSetIndexCursor
		; move the cursor
		EquipSetIndexCursor = (EquipSetIndexCursor + 1) % EquipSetWeapons.length
	endif
	; store references
	EquipSetWeapons[index] = akWeapon
	EquipSetAmmo[index] = akAmmo
EndFunction

Ammo Function GetEquipSetAmmo(Weapon akWeapon)
	ammo FoundAmmo
	int index
	; search array for passed in weapon and find matching ammo
	while index < EquipSetWeapons.length && !FoundAmmo ;&& EquipSetWeapons[index]
		if EquipSetWeapons[index] == akWeapon
			FoundAmmo = EquipSetAmmo[index]
		endif
		index += 1
	endwhile
	return FoundAmmo
EndFunction

Ammo Function GetEquippedAmmo(Actor Subject)
	if !Subject
		return None
	endif

	int ArrayIndex
	int FormListIndex

	; search all formlists one by one until equipped ammo is found
	while ArrayIndex < FullAmmoList.length
		FormListIndex = 0
		while FormListIndex < FullAmmoList[ArrayIndex].GetSize()
			if Subject.IsEquipped(FullAmmoList[ArrayIndex].GetAt(FormListIndex))
				return FullAmmoList[ArrayIndex].GetAt(FormListIndex) as Ammo
			endif
			FormListIndex += 1
		endwhile
		ArrayIndex += 1
	endwhile

	return None
EndFunction

Int Function GetAmmoType(Ammo akAmmo)
	; Return types: 0 - Other, 1 - Arrows, 2 - Bolts
	; Asks user to classify ammo if unknown type
	if AUAArrowList.HasForm(akAmmo) || AUACustomArrowList.HasForm(akAmmo)
		return 1
	elseif AUABoltList.HasForm(akAmmo) || AUACustomBoltList.HasForm(akAmmo)
		return 2
	elseif AUAOtherList.HasForm(akAmmo) || AUACustomOtherList.HasForm(akAmmo)
		return 0
	else
		ObjectReference TempAmmo = GetPlayer().PlaceAtMe(akAmmo, 1, false, true)
		Alias_Ammo.ForceRefTo(TempAmmo)
		int Button = AUAAmmoClassificationMenu.Show()
		Alias_Ammo.Clear()
		TempAmmo.Delete()

		if Button == 0	; Arrows
			AUACustomArrowList.AddForm(akAmmo)
			return 1
		elseif Button == 1	; Bolts
			AUACustomBoltList.AddForm(akAmmo)
			return 2
		else	; Other
			AUACustomOtherList.AddForm(akAmmo)
			return 0
		endif
	endif
EndFunction


; ***** SKSE functions - Called from MCM

String[] Function GetEquipSetNames()
	String[] EquipSetNames = new string[50]
	int EquipSetIndex
	int NameIndex
	while EquipSetIndex < EquipSetWeapons.length
		if EquipSetWeapons[EquipSetIndex] && EquipSetAmmo[EquipSetIndex]
			EquipSetNames[NameIndex] = "[" + EquipSetWeapons[EquipSetIndex].GetName() + "] + [" + EquipSetAmmo[EquipSetIndex].GetName() + "]"
			NameIndex += 1
		endif
		EquipSetIndex += 1
	endwhile
	if NameIndex == 0
		EquipSetNames[0] = "$AUA_ListEmpty"
	endif
	return EquipSetNames
EndFunction

String[] Function GetAmmoNamesByType(int aiAmmoType)
	FormList PresetAmmoList
	FormList CustomAmmoList
	if aiAmmoType == 1
		PresetAmmoList = AUAArrowList
		CustomAmmoList = AUACustomArrowList
	elseif aiAmmoType == 2
		PresetAmmoList = AUABoltList
		CustomAmmoList = AUACustomBoltList
	else
		PresetAmmoList = AUAOtherList
		CustomAmmoList = AUACustomOtherList
	endif

	String[] AmmoNames = new string[100]
	Form BaseAmmo
	int AmmoNamesIndex
	int FormListIndex

	while FormListIndex < PresetAmmoList.GetSize() && AmmoNamesIndex < AmmoNames.Length
		BaseAmmo = PresetAmmoList.GetAt(FormListIndex)
		AmmoNames[AmmoNamesIndex] = BaseAmmo.GetName() + " [" + GetModName(Math.RightShift(BaseAmmo.GetFormID(), 24)) + "]"
		AmmoNamesIndex += 1
		FormListIndex += 1
	endwhile

	FormListIndex = 0

	while FormListIndex < CustomAmmoList.GetSize() && AmmoNamesIndex < AmmoNames.Length
		BaseAmmo = CustomAmmoList.GetAt(FormListIndex)
		AmmoNames[AmmoNamesIndex] = "[*] " + BaseAmmo.GetName() + " [" + GetModName(Math.RightShift(BaseAmmo.GetFormID(), 24)) + "]"
		AmmoNamesIndex += 1
		FormListIndex += 1
	endwhile

	if AmmoNamesIndex == 0
		AmmoNames[0] = "$AUA_ListEmpty"
	elseif AmmoNamesIndex == AmmoNames.Length
		AmmoNames[AmmoNamesIndex - 1] = "$AUA_ListOverflow"
	endif

	return AmmoNames
	
EndFunction
