# Locale Module (`Kairo.Locale`)

Provides lightweight, zero-overhead localization with token interpolation and automatic fallback to English.

---

## 1. Registering Custom Strings

In your resource:
```lua
Kairo.Locale.Register('en', {
    ['welcome_message'] = 'Welcome, %{name}! Your balance is $%{amount}.',
    ['insufficient_funds'] = 'You need $%{amount} more to purchase this.',
})

Kairo.Locale.Register('es', {
    ['welcome_message'] = '¡Bienvenido, %{name}! Tu saldo es $%{amount}.',
    ['insufficient_funds'] = 'Necesitas $%{amount} más para comprar esto.',
})
```

---

## 2. Translating Strings (`Kairo.T` / `Kairo._t`)

```lua
-- Simple translation
local text = Kairo.T('welcome_message', { name = 'Alex', amount = 1500 })
print(text) -- "Welcome, Alex! Your balance is $1500."

-- Using the shortcut
local alert = Kairo._t('insufficient_funds', { amount = 50 })
Kairo.Notify(alert, 'error')
```

---

## 3. Changing Locale

```lua
-- Change the active language
Kairo.Locale.SetLocale('es')
```

If a string key is missing from the active language, Kairo Bridge will automatically fall back to the `'en'` definition before returning the raw key.
