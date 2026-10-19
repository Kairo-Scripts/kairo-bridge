-- Basic name -> count inventory held by the bridge's standalone store. No metadata, no stashes.
local Log = Kairo.Log
local B = 'kairo-bridge'
local A = {}
local usable = {}

local function call(name, ...)
    local e = exports[B]
    return e[name](e, ...)
end

local function warnMeta(metadata)
    if metadata then Log.warnOnce('sa-meta', 'Standalone inventory does not support item metadata; metadata is ignored') end
end

function A.GetItemCount(src, item, metadata) warnMeta(metadata); return call('StandaloneItemCount', src, item) end
function A.AddItem(src, item, count, metadata) warnMeta(metadata); return call('StandaloneItemAdd', src, item, count) end
function A.RemoveItem(src, item, count, metadata) warnMeta(metadata); return call('StandaloneItemRemove', src, item, count) end
function A.CanCarry(src, item, count) return call('StandaloneItemCanCarry', src, item, count) end

function A.GetItems(src, item)
    local out = {}
    for name, count in pairs(call('StandaloneItemList', src) or {}) do
        if not item or name == item then
            local def = call('GetRegisteredItem', name)
            out[#out + 1] = { name = name, label = def and def.label or name, count = count, weight = def and def.weight, metadata = {} }
        end
    end
    return out
end

function A.GetItemDefinition(name) return call('GetRegisteredItem', name) end
function A.ItemExists(name) return call('GetRegisteredItem', name) ~= nil end

function A.RegisterUsableItem(item, cb) usable[item] = cb end

---Standalone has no inventory UI. Call this from your own UI/command to trigger usable callbacks.
---Consumes nothing; remove the item in your callback if it should be consumed.
function A.UseItem(src, item)
    local cb = usable[item]
    if not cb or call('StandaloneItemCount', src, item) < 1 then return false end
    Kairo.Utils.SafeCall(cb, src, { name = item, metadata = {} })
    return true
end

function A.RegisterStash()
    Log.warnOnce('sa-stash', 'Standalone inventory has no stash support')
    return false
end
function A.OpenStash() return false end

return A
