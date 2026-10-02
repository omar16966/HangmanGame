-- Minimal in-memory replacement for love.filesystem, so the save system can
-- be tested with plain LuaJIT. Behaves like the real one where it matters:
-- writing into a folder that was never created fails.

local Fake = {}

function Fake.install()
    local files, dirs = {}, { [""] = true }
    Fake.files, Fake.dirs = files, dirs
    Fake.failWrites = false          -- simulate a full disk
    Fake.failWriteTo = nil           -- fail only for names containing this text
    Fake.writes = 0

    local function parent(name)
        return name:match("^(.*)/[^/]+$") or ""
    end

    love = love or {}
    love.filesystem = {
        write = function(name, data)
            Fake.writes = Fake.writes + 1
            if Fake.failWrites or (Fake.failWriteTo and name:find(Fake.failWriteTo, 1, true)) then
                return false, "simulated write failure"
            end
            if not dirs[parent(name)] then
                return false, "directory does not exist: " .. parent(name)
            end
            files[name] = data
            return true
        end,
        read = function(name)
            local data = files[name]
            if data == nil then return nil, "not found" end
            return data, #data
        end,
        getInfo = function(name)
            if files[name] then return { type = "file", size = #files[name] } end
            if dirs[name] then return { type = "directory" } end
            return nil
        end,
        remove = function(name)
            if files[name] then files[name] = nil return true end
            return false
        end,
        createDirectory = function(name)
            local p = ""
            for part in name:gmatch("[^/]+") do
                p = (p == "") and part or (p .. "/" .. part)
                dirs[p] = true
            end
            return true
        end,
        getDirectoryItems = function(dir)
            local out = {}
            local prefix = (dir == "" or dir == "/") and "" or (dir .. "/")
            for name in pairs(files) do
                if name:sub(1, #prefix) == prefix and not name:sub(#prefix + 1):find("/") then
                    out[#out + 1] = name:sub(#prefix + 1)
                end
            end
            return out
        end,
    }
    return Fake
end

return Fake
