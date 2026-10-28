-- Madness release loader. Insert toggles the menu after authentication.
local environment = (getgenv and getgenv()) or _G
local slot = 'RagebotMadnessReleaseLoader'
local state = { Status = 'loading' }
environment[slot] = state
local function current() return environment[slot] == state end
local function fail(message)
    if current() then environment[slot] = nil end
    error('Madness loader: ' .. tostring(message), 0)
end
local function download(url)
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if not current() then return nil end
    if not ok or type(body) ~= 'string' or body == '' then fail('download failed') end
    return body
end
local base = 'https://raw.githubusercontent.com/Exanety/load/main/madness/'
local manifestText = download(base .. 'manifest.json')
if not manifestText then return end
local ok, manifest = pcall(function()
    return game:GetService('HttpService'):JSONDecode(manifestText)
end)
if not ok or type(manifest) ~= 'table' then fail('invalid manifest') end
if manifest.status ~= 'online' then fail(manifest.message or 'release is offline') end
if type(manifest.payload) ~= 'string'
    or not manifest.payload:match('^dist/madness%-%x+%.lua$')
    or type(manifest.payload_bytes) ~= 'number' or manifest.payload_bytes < 1 then
    fail('invalid payload metadata')
end
local payload = download(base .. manifest.payload)
if not payload then return end
if #payload ~= manifest.payload_bytes then fail('incomplete payload download') end
local chunk, problem = loadstring(payload, '@Madness-release.lua')
if not chunk then fail('release compilation failed: ' .. tostring(problem)) end
if not current() then return end
local results = table.pack(xpcall(chunk, function(message) return tostring(message) end))
if not current() then return end
if not results[1] then fail(results[2]) end
state.Status = 'loaded'
return table.unpack(results, 2, results.n)
