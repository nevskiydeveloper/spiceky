local R,C,N="nevskiydeveloper/spiceky","core.luau",os.time()..math.random(1000000,9999999)
local Q=syn and syn.request or http and http.request or http_request or request
local U="https://raw.githubusercontent.com/"..R.."/refs/heads/main/"..C.."?cb="..N
local function F(u)local k,r=pcall(Q,{Url=u,Method="GET",FollowRedirects=true,Headers={Accept="application/vnd.github.raw"}})if k and type(r)=="string" then return r end if k and type(r)=="table" and tonumber(r.StatusCode or r.Status or 200)==200 then return r.Body or r.body end end
local s=F("https://api.github.com/repos/"..R.."/contents/"..C.."?ref=main&cb="..N)or F(U)or F("https://github.com/"..R.."/raw/refs/heads/main/"..C.."?cb="..N)
if not s then local k,r=pcall(game.HttpGet,game,U)if k then s=r end end
assert(s,"spiceky: download failed")
return(loadstring or load)(s)()
-- THIS IS JUST A LOADER WITHOUT CDN COOKIE (HASH)!!!!!!!!!!!!!
