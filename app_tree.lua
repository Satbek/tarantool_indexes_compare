box.cfg{
    work_dir = 'tmp/tree',
    listen = 3301,
}

box.schema.create_space('test', {
    format = {
        {name = 'id', type = 'string', is_nullable = false},
        {name = 'name', type = 'string', is_nullable = false},
        {name = 'data', type = 'any', is_nullable = false},
    },
    if_not_exists = true,
})

box.space.test:create_index('pk', {parts = {'id'}, unique = true, type = 'TREE', if_not_exists = true})
box.space.test:create_index('secondary', {parts = {'name'}, type = 'TREE', unique = true, if_not_exists = true})
box.schema.user.grant('guest', 'read,write,execute', 'universe', nil, {if_not_exists = true})

local function replace(record)
    return box.space.test:replace(record)
end

local function get_by_pk(id)
    return box.space.test:get({id})
end

local function get_by_secondary(name)
    return box.space.test.index.secondary:get({name})
end

rawset(_G, 'replace', replace)
rawset(_G, 'get_by_pk', get_by_pk)
rawset(_G, 'get_by_secondary', get_by_secondary)
