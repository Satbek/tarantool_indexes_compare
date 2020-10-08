local fio = require('fio')
local json = require('json')

local tree_index_type = "tree"
local hash_index_type = "hash"

local function get_pk(idx)
    return "pk" .. tostring(idx)
end

local function get_secondary(idx)
    return "name" .. tostring(idx)
end

local function generate_replace_ammo(count, index_type)
    local fh = fio.open("replace_" .. index_type .. ".txt", {'O_WRONLY', 'O_CREAT'})
    for i = 1, count do
        local record = {}
        record.Type = index_type
        record.Method = "replace"
        record.Params = {{get_pk(i), get_secondary(i), "some data"}}
        fh:write(json.encode(record) .. "\n")
    end
end

local function generate_get_by_pk_ammo(count, index_type)
    local fh = fio.open("get_by_pk_" .. index_type.. ".txt", {'O_WRONLY', 'O_CREAT'})
    for i = 1, count do
        local record = {}
        record.Type = index_type
        record.Method = "get_by_pk"
        record.Params = {get_pk(i)}
        fh:write(json.encode(record) .. "\n")
    end
end

local function generate_get_by_secondary_ammo(count, index_type)
    local fh = fio.open("get_by_secondary_" .. index_type.. ".txt", {'O_WRONLY', 'O_CREAT'})
    for i = 1, count do
        local record = {}
        record.Type = index_type
        record.Method = "get_by_secondary"
        record.Params = {get_secondary(i)}
        fh:write(json.encode(record) .. "\n")
    end
end


generate_replace_ammo(300000, tree_index_type)
generate_replace_ammo(300000, hash_index_type)
generate_get_by_pk_ammo(300000, tree_index_type)
generate_get_by_pk_ammo(300000, hash_index_type)
generate_get_by_secondary_ammo(300000, tree_index_type)
generate_get_by_secondary_ammo(300000, hash_index_type)
