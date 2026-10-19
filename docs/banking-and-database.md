# Banking & Database Modules

## 1. Banking & Society Accounts (`Kairo.Banking` / `Kairo.Society`)

Supports `Renewed-Banking`, `okokBanking`, `qb-management`, `esx_society`, and standalone KVP storage:

```lua
-- Fetch account info
local account = Kairo.Banking.GetAccount('police')
if account then
    print('Police fund balance: $' .. account.balance)
end

-- Deposit into society account
local success = Kairo.Banking.AddMoney('police', 5000, 'State grant')

-- Withdraw from society account
local success = Kairo.Banking.RemoveMoney('police', 1200, 'Equipment purchase')
```

---

## 2. Database Wrapper (`Kairo.DB` / `Kairo.Database`)

Kairo Bridge provides an oxmysql query wrapper and normalizes common database queries across ESX and QB schemas:

### Raw Queries
```lua
-- Execute
local affectedRows = Kairo.DB.Execute('UPDATE users SET firstname = ? WHERE identifier = ?', { 'John', id })

-- Scalar
local count = Kairo.DB.Scalar('SELECT COUNT(*) FROM players', {})

-- Single row
local row = Kairo.DB.Single('SELECT * FROM billing WHERE id = ?', { invoiceId })

-- Insert
local insertId = Kairo.DB.Insert('INSERT INTO logs (message) VALUES (?)', { 'Server booted' })

-- Transaction batch
local ok = Kairo.DB.Transaction({
    'UPDATE accounts SET balance = balance - 100 WHERE id = 1',
    'UPDATE accounts SET balance = balance + 100 WHERE id = 2',
})
```

### Normalized Vehicle Database Operations
```lua
-- Retrieve all player vehicles (translates table and column names automatically)
local vehicles = Kairo.DB.GetPlayerVehicles(citizenId)

-- Retrieve a vehicle by plate
local veh = Kairo.DB.GetVehicleByPlate('ABC 123')

-- Save vehicle properties
Kairo.DB.SaveVehicleProps('ABC 123', vehicleProps)

-- Update garage storage state
Kairo.DB.SetVehicleStored('ABC 123', true, 'LegionSquare')
```
