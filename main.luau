-- THIS IS JUST A LOADER WITHOUT CDN COOKIE (HASH)!!!!!!!!!!!!!
local REPO = "nevskiydeveloper/spiceky"
local BRANCH = "main"
local FILE = "core.luau"

local nonce = tostring(os.time()) .. "-" .. tostring(math.random(1000000, 9999999))

local function getRequestFunction()
    if type(request) == "function" then
        return request
    end
    if type(http_request) == "function" then
        return http_request
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return syn.request
    end
    if type(http) == "table" and type(http.request) == "function" then
        return http.request
    end
    return nil
end

local REQUEST = getRequestFunction()

local function httpGet(url, headers)
    if REQUEST then
        local ok, response = pcall(REQUEST, {
            Url = url,
            Method = "GET",
            FollowRedirects = true,
            Headers = headers or {},
        })
        if ok and type(response) == "string" and response ~= "" then
            return response
        end
        if ok and type(response) == "table" then
            local status = tonumber(response.StatusCode or response.Status or response.statusCode or 200) or 0
            if status == 200 then
                local body = response.Body or response.body or response.Data
                if type(body) == "string" and body ~= "" then
                    return body
                end
            end
        end
    end
    local ok, fallback = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(fallback) == "string" and fallback ~= "" then
        return fallback
    end
    return nil
end

local apiUrl = "https://api.github.com/repos/" .. REPO .. "/contents/" .. FILE .. "?ref=" .. BRANCH .. "&cb=" .. nonce
local rawUrl = "https://raw.githubusercontent.com/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. FILE .. "?cb=" .. nonce
local mirrorUrl = "https://github.com/" .. REPO .. "/raw/refs/heads/" .. BRANCH .. "/" .. FILE .. "?cb=" .. nonce

local source = nil
local sourceFrom = nil

source = httpGet(apiUrl, { ["Accept"] = "application/vnd.github.raw" })
if source then
    sourceFrom = "api"
end

if not source then
    source = httpGet(rawUrl)
    if source then
        sourceFrom = "raw"
    end
end

if not source then
    source = httpGet(mirrorUrl)
    if source then
        sourceFrom = "mirror"
    end
end

if not source then
    error("spiceky: could not download " .. FILE .. " (api, raw and mirror all failed)", 0)
end

print("[spiceky] " .. FILE .. " " .. tostring(#source) .. " bytes via " .. tostring(sourceFrom))

local chunk, compileError = (loadstring or load)(source)
if not chunk then
    error("spiceky: compile error in " .. FILE .. ": " .. tostring(compileError), 0)
end

return chunk()
