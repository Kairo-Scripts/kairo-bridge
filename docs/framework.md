# Framework Module (`Kairo.Framework`)

Provides a unified player object and server/client helpers across **ESX**, **QB-Core**, **Qbox**, and **Standalone**.

---

## 1. Getting a Player Object (Server-side)

```lua
local player = Kairo.Framework.GetPlayer(source)
if not player then return end

print('Identifier:', player.GetIdentifier())
print('Name:', player.GetName())
print('Job:', player.GetJob().name, 'Grade:', player.GetJob().grade)
```

### Available Methods on `KairoPlayer`

| Method | Parameters | Return | Description |
|---|---|---|---|
| `GetIdentifier()` | None | `string` | Citizen ID, hex license, or unique identifier. |
| `GetName()` | None | `string` | Character full name. |
| `GetJob()` | None | `table` | `{ name, label, grade, gradeLabel }` |
| `GetGang()` | None | `table` | `{ name, label, grade, gradeLabel }` |
| `GetMoney(account)` | `account?: string` | `number` | Balance for 'cash', 'bank', 'black', or custom account. |
| `AddMoney(amount, account?, reason?)` | `number, string?, string?` | `boolean` | Adds money to account. |
| `RemoveMoney(amount, account?, reason?)` | `number, string?, string?` | `boolean` | Deducts money if balance is sufficient. |
| `SetJob(name, grade?)` | `string, number?` | `boolean` | Updates player job and grade. |
| `Notify(message, type?, duration?)` | `string, string?, number?` | `void` | Sends a toast notification to the player. |

---

## 2. Direct Framework Module Functions

You can also call methods directly via `Kairo.Framework` by passing `source`:

```lua
-- Money
local cash = Kairo.Framework.GetMoney(source, 'cash')
Kairo.Framework.AddMoney(source, 250, 'cash', 'Store payment')
Kairo.Framework.RemoveMoney(source, 50, 'cash', 'Bought coffee')

-- Job
local job = Kairo.Framework.GetJob(source)
if job.name == 'police' and job.grade >= 2 then
    -- Supervisor logic
end

-- Permissions
if Kairo.Framework.HasPermission(source, 'admin') then
    print('Player is admin!')
end
```

---

## 3. Money-Change Event Listener

Kairo Bridge provides a unified listener for balance changes, firing whether the money was modified via Kairo Bridge or native framework events:

```lua
Kairo.Framework.OnMoneyChange(function(source, account, newAmount, diff, reason)
    print(('[MONEY CHANGE] Player %d: %s changed by $%d (new balance: $%d) reason: %s'):format(
        source, account, diff, newAmount, reason or 'unspecified'
    ))
end)
```
