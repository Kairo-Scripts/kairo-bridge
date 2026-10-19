# Services Module (`Kairo.Services`)

Aggregates emergency, municipal, and player-state systems: Dispatch, Doorlocks, Clothing/Appearance, Phones, Healthcare/Ambulance, and Incarceration/Prison.

---

## 1. Dispatch (`Kairo.Dispatch`)

Broadcasts emergency 911 / 311 alerts across `ps-dispatch`, `cd_dispatch`, `core_dispatch`, `qs-dispatch`, or standalone flashing radar blips:

```lua
Kairo.Dispatch.CreateAlert({
    code = '10-31',
    title = 'Shots Fired',
    message = 'Gunfire reported near Legion Square',
    coords = GetEntityCoords(PlayerPedId()),
    jobs = { 'police', 'sheriff' },
    sprite = 110,
    color = 1,
    scale = 1.2,
    sound = 'Lose_1st',
})
```

---

## 2. Doorlocks (`Kairo.Doorlock`)

Synchronizes lock states across `ox_doorlock`, `qb-doorlock`, `rcore_doorlock`, or standalone `GlobalState`:

```lua
-- Query lock status (true = locked)
local isLocked = Kairo.Doorlock.GetState('vangelico_main')

-- Toggle lock state
Kairo.Doorlock.SetState('vangelico_main', not isLocked)
```

---

## 3. Appearance & Clothing (`Kairo.Appearance`)

Handles wardrobe, skins, and clothing customization across `illenium-appearance`, `fivem-appearance`, `qb-clothing`, `esx_skin`, and native ped drawables:

```lua
-- Retrieve full appearance data table
local appearance = Kairo.Appearance.GetPedAppearance(PlayerPedId())

-- Apply appearance table to a ped
Kairo.Appearance.SetPedAppearance(PlayerPedId(), appearance)

-- Open clothing customization menu
Kairo.Appearance.OpenMenu('clothing')
```

---

## 4. Phone System (`Kairo.Phone`)

Integrates with `lb-phone`, `qs-smartphone`, `qb-phone`, or falls back to toast notifications:

```lua
-- Send app notification to player's phone
Kairo.Phone.SendNotification(source, {
    title = 'Maze Bank',
    content = 'Direct deposit received: $1,250.00',
    icon = 'dollar-sign',
    duration = 5000,
})

-- Add contact to player's phonebook
Kairo.Phone.AddContact(source, {
    name = 'Mechanic Benny',
    number = '555-0199',
})
```

---

## 5. Ambulance & Healthcare (`Kairo.Ambulance`)

Synchronizes medical states across `qbx_medical`, `wasabi_ambulance`, `qb-ambulancejob`, `esx_ambulancejob`, or native ped health:

```lua
-- Check if player is down or dead
if Kairo.Ambulance.IsDead(source) then
    -- Revive and clear death state
    Kairo.Ambulance.Revive(source)
end

-- Heal injuries and restore 100% health
Kairo.Ambulance.Heal(source)
```

---

## 6. Prison & Incarceration (`Kairo.Prison`)

Handles sentencing and jail time across `qbx_prison`, `qb-prison`, `rcore_prison`, `esx-qalle-jail`, or standalone Bolingbroke Penitentiary:

```lua
-- Jail player for 15 minutes
Kairo.Prison.Jail(source, 15, 'Armed Robbery')

-- Query remaining sentence in minutes
local minutesLeft = Kairo.Prison.GetRemainingTime(source)

-- Release player early
Kairo.Prison.Unjail(source)
```
