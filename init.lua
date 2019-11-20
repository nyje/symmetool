-- symmetool v0.1
-- (c)2019 Nigel Garnett.

symmetool = {}
symmetool.axis_list = { "X-Axis","Y-Axis","Z-Axis","XY-Axes","YZ-Axes","XZ-Axes","XYZ-Axes" }


local l = 32
local boxen = {}
    boxen.x =   { {-.05, -(l+.05), -(l+.05), .05, (l+.05), (l+.05)} }
    boxen.y =   { {-(l+.05), -.05, -(l+.05), (l+.05), .05, (l+.05)} }
    boxen.z =   { {-(l+.05), -(l+.05), -.05, (l+.05), (l+.05), .05} }
    boxen.xy =  { {-.05, -(l+.05), -(l+.05), .05, (l+.05), (l+.05)},
                  {-(l+.05), -.05, -(l+.05), (l+.05), .05, (l+.05)} }
    boxen.yz =  { {-(l+.05), -.05, -(l+.05), (l+.05), .05, (l+.05)},
                  {-(l+.05), -(l+.05), -.05, (l+.05), (l+.05), .05} }
    boxen.xz =  { {-.05, -(l+.05), -(l+.05), .05, (l+.05), (l+.05)},
                  {-(l+.05), -(l+.05), -.05, (l+.05), (l+.05), .05} }
    boxen.xyz = { {-.05, -(l+.05), -(l+.05), .05, (l+.05), (l+.05)},
                  {-(l+.05), -.05, -(l+.05), (l+.05), .05, (l+.05)},
                  {-(l+.05), -(l+.05), -.05, (l+.05), (l+.05), .05} }

local axis = 1
local order = 2

local function remove_entity(pos)
    local aobj = minetest.get_objects_inside_radius(pos,1)
    if aobj then
        for _,obj in ipairs(aobj) do
            if obj then
                if not obj:is_player() then
                    obj:remove()
                end
            end
        end
    end
end

local function show_entity(pos,axis)
    local aname = string.lower(string.split(symmetool.axis_list[axis],"-")[1])
    remove_entity(pos)
    minetest.add_entity(pos, "symmetool:"..aname.."axis")
end

local function remove_node(pos)
    if pos then
        minetest.set_node(pos,{name="air"})
    end
end

local function cycle_axis(pos)
    local meta = minetest.get_meta(pos)
    axis = meta:get_int("axis") + 1
    if axis == 8 then axis = 1 end
    meta:set_int("axis",axis)
    show_entity(pos,axis)
end

local function cycle_order(pos)
    local meta = minetest.get_meta(pos)
    order = meta:get_int("order") + 1
    if order == 7 then order = 2 end
    meta:set_int("order",order)
end

local function inform_state(placer,pos)
    local meta = minetest.get_meta(pos)
    local a = meta:get_int("axis")
    local o = meta:get_int("order")
    local pmeta = placer:get_meta()
    local pload = pmeta:get_string("load")
    if pload == "" then
        pload = "Punch a node with the tool to start building"
    else
        pload = "Building with "..pload
    end
    minetest.chat_send_player(placer:get_player_name(), symmetool.axis_list[a].."("..o..") "..pload)
end

local function pickup(puncher,pos)
    remove_node(pos)
    remove_entity(pos)
    local inv = puncher:get_inventory()
    if not (creative and creative.is_enabled_for
            and creative.is_enabled_for(puncher:get_player_name()))
            or not inv:contains_item("main", "symmetool:rotation") then
        local leftover = inv:add_item("main", "stmmetool:rotation")
        if not leftover:is_empty() then
            minetest.add_item(self.object:get_pos(), leftover)
        end
    end
end

local function flip(pos,center,axis)
    local new_pos = {x = pos.x, y = pos.y, z = pos.z }
    local r = pos[axis] - center[axis]
    new_pos[axis] = pos[axis] - 2*r
    return new_pos
end

local function super_build(player,pos,pload)
    local pmeta = player:get_meta()
    if pmeta:get_string("pos") ~= "" then
        local center = minetest.deserialize(pmeta:get_string("pos"))
        local meta = minetest.get_meta(center)
        local axis = meta:get_int("axis")
        local reflect_axes = string.lower(string.split(symmetool.axis_list[axis],"-")[1])
        local coords = { pos }
        for i = 1,#reflect_axes do
            local this_axis = string.sub(reflect_axes,i,i)
            for _,coord in pairs(coords) do
                coords[#coords+1] = flip(coord,center,this_axis)
            end
        end
        for _,coord in pairs(coords) do
            minetest.set_node(coord,{name=pload})
        end
    end
end

local function load_or_build(player,pointed_thing)
    local pmeta = player:get_meta()
    if pointed_thing.type == "node" then
        local nodename = minetest.get_node(pointed_thing.under).name
        if nodename == "symmetool:rotation" then
            if player:get_player_control().sneak then
                pickup(player,pointed_thing.under)
            else
                cycle_order(pointed_thing.under)
                inform_state(player,pointed_thing.under)
            end
        else
            local pload = pmeta:get_string("load")
            if pload == "" then
                pmeta:set_string("load",nodename)
                minetest.chat_send_player(player:get_player_name(),"Now building with "..nodename)
            else
                super_build(player,pointed_thing.above,pload)
            end
        end
    end
    if pointed_thing.type == "nothing" then
        pmeta:set_string("load",nil)
        minetest.chat_send_player(player:get_player_name(),"Punch a block to choose material")
    end
end

minetest.register_node("symmetool:rotation", {
    description = "Circular Symmetry Tool",
    drawtype = "mesh",
    mesh = "mymeshnodes_sphere.obj",
    tiles = {"symmetool_plain.png^[colorize:#ff00ff:100"},
    is_ground_content = false,
    selection_box = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    stack_max = 1,
    light_source = core.LIGHT_MAX,
    sunlight_propagates = 1,
    groups = {cracky = 3, snappy = 3, crumbly = 3},
    on_blast = function() end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local pmeta = placer:get_meta()
        if pmeta:get_string("pos") ~= "" then
            local opos=minetest.deserialize(pmeta:get_string("pos"))
            pickup(placer,opos)
        end
        local meta = minetest.get_meta(pos)
        meta:set_int("axis",1)
        meta:set_int("order",2)
        inform_state(placer,pos)
        show_entity(pos,1)
        pmeta:set_string("pos",minetest.serialize(pos))
    end,
    on_punch = function(pos, node, puncher, pointed_thing)
        if puncher:get_player_control().sneak then
            pickup(puncher,pos)
        else
            cycle_order(pos)
            inform_state(puncher,pos)
        end
        return true
    end,
    on_dig = function() end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if node.name == "symmetool:rotation" then
            cycle_axis(pos)
            inform_state(clicker,pos)
        else
            load_or_build(player,pointed_thing)
        end
        return false
    end,
    on_use = function(itemstack, player, pointed_thing)
        load_or_build(player,pointed_thing)
    end,
--     can_dig = function(pos,player)
--         return true
--     end,
})

for _,axis in pairs(symmetool.axis_list) do
    local aname = string.lower(string.split(axis,"-")[1])
    local box = boxen[aname]
    minetest.register_entity("symmetool:"..aname.."axis", {
        physical = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
        visual = "wielditem",
        -- wielditem seems to be scaled to 1.5 times original node size
        visual_size = {x = 0.33, y = 0.33},
        textures = {"symmetool:"..aname.."_axis_node"},
        timer = 0,
        glow = 10,
    })
    minetest.register_node("symmetool:"..aname.."_axis_node", {
        tiles = {"symmetool_wall.png"},
        --use_texture_alpha = true,
        walkable = false,
        light_source = core.LIGHT_MAX,
        drawtype = "nodebox",
        node_box = {
            type = "fixed",
            fixed = box,
        },
        selection_box = {
            type = "regular",
        },
        paramtype = "light",
        groups = {dig_immediate = 3, },
        drop = "",
    })
end
--not_in_creative_inventory = 1

minetest.register_on_leaveplayer(function(player)
    local pmeta = player:get_meta()
    if pmeta:get_string("pos") ~= "" then
        local opos=minetest.deserialize(pmeta:get_string("pos"))
        pickup(player,opos)
    end
    pmeta:set_string("pos",nil)
    pmeta:set_string("load",nil)
end)

minetest.register_on_joinplayer(function(player)
    local pmeta = player:get_meta()
    pmeta:set_string("pos",nil)
    pmeta:set_string("load",nil)
end)


