-- kairo-bridge configuration
-- NOTE: this file is streamed to clients. Never put secrets in here.
return {
    Debug = false,

    -- 'auto' detects what is running. Force one with the ids below.
    Framework = 'auto', -- 'auto' | 'esx' | 'qb' | 'qbox' | 'standalone'
    Inventory = 'auto', -- 'auto' | 'ox' | 'qb' | 'ps' | 'qs' | 'codem' | 'core' | 'tgiann' | 'none'
    Target      = 'auto', -- 'auto' | 'ox' | 'qb' | 'sleepless' | 'none'
    UI          = 'auto', -- 'auto' | 'ox_lib' | 'qb' | 'esx' | 'standalone'
    Fuel        = 'auto', -- 'auto' | 'ox' | 'cdn' | 'ps' | 'legacy' | 'standalone'
    VehicleKeys = 'auto', -- 'auto' | 'qbx' | 'qb' | 'wasabi' | 'renewed' | 'cd' | 'standalone'
    Banking     = 'auto', -- 'auto' | 'renewed' | 'okok' | 'qb' | 'esx' | 'standalone'
    PlateFormat = '11AAA111', -- '1' = digit, 'A' = uppercase letter, ' ' = space
    Dispatch    = 'auto', -- 'auto' | 'ps' | 'cd' | 'core' | 'qs' | 'standalone'
    Doorlock    = 'auto', -- 'auto' | 'ox' | 'qb' | 'rcore' | 'standalone'
    Appearance  = 'auto', -- 'auto' | 'illenium' | 'fivem-appearance' | 'qb' | 'esx' | 'standalone'
    Phone       = 'auto', -- 'auto' | 'lb' | 'qs' | 'qb' | 'standalone'
    Ambulance   = 'auto', -- 'auto' | 'qbx' | 'wasabi' | 'qb' | 'esx' | 'standalone'
    Prison      = 'auto', -- 'auto' | 'qbx' | 'qb' | 'rcore' | 'esx' | 'standalone'
    Locale      = 'en',

    -- NUI image templates per inventory. %s receives the item's image file name (with extension).
    -- Fill in / correct these for your inventory version. Empty = no image path available.
    ImagePaths = {
        ox = 'nui://ox_inventory/web/images/%s',
        qb = 'nui://qb-inventory/html/images/%s',
        ps = 'nui://ps-inventory/html/images/%s',
        qs = 'nui://qs-inventory/html/images/%s',
        codem = 'nui://codem-inventory/html/itemimages/%s',
        tgiann = 'nui://inventory_images/images/%s', -- needs the inventory_images resource; webp items must carry their extension
        core = 'nui://core_inventory/html/img/%s',
        esx = '', standalone = '',
    },

    -- Heartbeat (heartbeat.re) usage API, server-side only. The API key is NEVER stored here (this file is streamed
    -- to clients). Put it in server.cfg:   set kairo_heartbeat_key "your-key"     (`set`, not `setr`)
    Heartbeat = {
        -- The spec's own `servers` entry is a localhost placeholder, so this is derived from the site domain + the
        -- spec's /api/v1 prefix. Verify it against your key's dashboard / the docs and change it if they differ.
        BaseUrl = 'https://heartbeat.re/api/v1',
        CacheSeconds = 300, -- min 30. Data only changes per census, so caching keeps you well inside the rate limit.
    },

    -- Optional: URL returning {"version": "1.2.3"}. Leave empty to disable.
    VersionCheckUrl = '',

    -- Used only when the framework is 'standalone'
    Standalone = {
        MaxWeight = 0, -- grams, 0 = unlimited (uses registered item weights)
        StartingMoney = { cash = 500, bank = 5000, black = 0 },
        DefaultJob = { name = 'unemployed', label = 'Unemployed', grade = 0, gradeLabel = 'Unemployed' },
        -- Optional job definitions so labels / boss grades resolve properly
        Jobs = {
            police = { label = 'Police', bossGrade = 3, grades = { [0] = 'Cadet', [1] = 'Officer', [2] = 'Sergeant', [3] = 'Chief' } },
        },
    },
}
