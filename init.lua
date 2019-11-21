-- Symmetool v1.0
-- (c)2019 Nigel Garnett.


-- ======================================= --
-- User Settings
-- ======================================= --
local max_range		= 50
local marker_length = 2
local axis_colors	= { x = "#FF0000", y = "#00FF00", z = "#0000FF" }
local default_axis	= 6  -- (XZ Axes - good for towers & castles)


-- ======================================= --
-- Main vars
-- ======================================= --
--symmetool = {}
local axis_list = { "X-Axis","Y-Axis","Z-Axis","XY-Axes","YZ-Axes","XZ-Axes","XYZ-Axes" }
local boxen = {}
    boxen.x =   { {-.05, -(marker_length+.05), -(marker_length+.05), .05, (marker_length+.05), (marker_length+.05)} }
    boxen.y =   { {-(marker_length+.05), -.05, -(marker_length+.05), (marker_length+.05), .05, (marker_length+.05)} }
    boxen.z =   { {-(marker_length+.05), -(marker_length+.05), -.05, (marker_length+.05), (marker_length+.05), .05} }

-- ======================================= --
-- Local functions
-- ======================================= --

local function flip(pos,center,axis)
    local new_pos = {x = pos.x, y = pos.y, z = pos.z }
    local r = pos[axis] - center[axis]
    new_pos[axis] = pos[axis] - 2*r
    return new_pos
end

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
    local aname = string.lower(string.split(axis_list[axis],"-")[1])
    remove_entity(pos)
    for i = 1,#aname do
        minetest.add_entity(pos, "symmetool:"..string.sub(aname,i,i).."axis")
    end
end

local function replace_node(pos,player,node_name)
    if pos then
		if not minetest.is_protected(pos,player:get_player_name()) then
			minetest.set_node(pos,{name=node_name})
		end
    end
end

local function cycle_axis(player)
    local pmeta = player:get_meta()
	if pmeta:get_string("center") ~= "" then
		local center = minetest.deserialize(pmeta:get_string("center"))
		local axis = pmeta:get_int("axis") + 1
		if axis == 8 then axis = 1 end
		pmeta:set_int("axis",axis)
		show_entity(center,axis)
	end
end

local function inform_state(player)
    local pmeta = player:get_meta()
    local a = pmeta:get_int("axis")
    local payload = pmeta:get_string("payload")
	if payload == "" then
		payload = minetest.colorize('#F55'," Punch a node with the tool to start building")
	else
		payload = minetest.colorize('#F5F'," Building with ")..minetest.colorize('#9FF',payload)
	end
	minetest.chat_send_player(player:get_player_name(), minetest.colorize('#5F5', axis_list[a])..payload)
end

local function super_build(pos,player,node_name)
    local pmeta = player:get_meta()
    if pmeta:get_string("center") ~= "" then
        local center = minetest.deserialize(pmeta:get_string("center"))
        local axis = pmeta:get_int("axis")
        local reflect_axes = string.lower(string.split(axis_list[axis],"-")[1])
        local coords = { pos }
        for i = 1,#reflect_axes do
            local this_axis = string.sub(reflect_axes,i,i)
			local new_coords = {}
            for _,coord in pairs(coords) do
				new_coords[#new_coords+1] = coord
				new_coords[#new_coords+1] = flip(coord,center,this_axis)
            end
			coords = new_coords
        end
        for _,coord in pairs(coords) do
			local old_node_name = minetest.get_node(coord).name
			if node_name == "air" and old_node_name ~= "air" then
				local inv = player:get_inventory()
				if not (creative and creative.is_enabled_for
						and creative.is_enabled_for(player:get_player_name()))
						or not inv:contains_item("main", old_node_name) then
					local leftover = inv:add_item("main", old_node_name)
					if not leftover:is_empty() then
						minetest.add_item(pos, leftover)
					end
				end
			end
			replace_node(coord,player,node_name)
        end
    else
		replace_node(pos,player,node_name)
	end
end

local function pickup(pos,player)
	local node_name = minetest.get_node(pos).name
	if node_name == "symmetool:mirror" then
		local pmeta = player:get_meta()
		pmeta:set_string("payload",nil)
		pmeta:set_string("center",nil)
		remove_entity(pos)
	end
    super_build(pos,player,"air")
end

-- ======================================= --
-- Symmetool Mirror Node definition
-- ======================================= --

minetest.register_node("symmetool:mirror", {
    description = "Mirror Symmetry Tool",
    --drawtype = "mesh",
    --mesh = "symmetool_miror.obj",
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = { {-0.125, -0.5, -0.5, 0.125, 0.5, 0.5},
				  {-0.5, -0.125, -0.5, 0.5, 0.125, 0.5},
				  {-0.5, -0.5, -0.125, 0.5, 0.5, 0.125},
				}
	},
    tiles = {"symmetool_mirror.png^[colorize:#00ffff:100"},
    is_ground_content = false,
    selection_box = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    stack_max = 1,
	visual_size = {x = 2, y = 2},
    light_source = core.LIGHT_MAX,
    sunlight_propagates = 1,
    groups = {cracky = 3, snappy = 3, crumbly = 3},
    on_blast = function() end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local pmeta = placer:get_meta()
		local center_string = pmeta:get_string("center")
		local payload = pmeta:get_string("payload")
		local node_name = minetest.get_node(pointed_thing.under).name
		if node_name == "symmetool:mirror" and payload == "" then
			cycle_axis(placer)
			inform_state(placer)
			replace_node(pos,placer,"air")
			return
		end
		if payload ~= "" then
            local center_pos = minetest.deserialize( center_string)
            if (center_string ~= "") and
                    (vector.distance( center_pos, pointed_thing.under) > max_range) then
                minetest.chat_send_player(placer:get_player_name(),
										  minetest.colorize("#FFF", "Too far from center, marker removed."))
                pickup(center_pos,placer)
                remove_entity(center_pos)
    			replace_node(pos,placer,"air")
                return
            end
			super_build(pos,placer,payload)
			return
		end
		if center_string ~= "" and payload == "" then
			local center_pos=minetest.deserialize(pmeta:get_string("center"))
			pickup(center_pos,placer)
		    remove_entity(center_pos)
			center_string = pmeta:get_string("center")
		end
		if  center_string == "" then
			pmeta:set_int("axis",default_axis)
			pmeta:set_string("center",minetest.serialize(pos))
			inform_state(placer)
			show_entity(pos,default_axis)
		end
    end,
    on_use = function(itemstack, player, pointed_thing)
        local pmeta = player:get_meta()
		local center_string = pmeta:get_string("center")
		if pointed_thing.type == "nothing" and center_string ~= "" then
			pmeta:set_string("payload",nil)
			minetest.chat_send_player(player:get_player_name(), minetest.colorize("#F5F", "Cleared."))
			inform_state(player)
		end
		if pointed_thing.type == "node" then
	        local node_name = minetest.get_node(pointed_thing.under).name
			local payload = pmeta:get_string("payload")
			if (node_name == "symmetool:mirror" and player:get_player_control().sneak) or
					( node_name == "symmetool:mirror" and payload == "" ) then
				pickup(pointed_thing.under,player)
			    remove_entity(pointed_thing.under)
				return
			end
			if center_string ~= "" then
				if payload == "" then
					pmeta:set_string("payload",node_name)
					minetest.chat_send_player(player:get_player_name(), minetest.colorize("#F5F", "Now building with ")..
																		minetest.colorize("#9FF", node_name))
				else
                    local center_pos = minetest.deserialize( center_string)
                    if vector.distance( center_pos, pointed_thing.under) > max_range then
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize("#FFF", "Too far from center, marker removed."))
                        pickup(center_pos,player)
                        remove_entity(center_pos)
                        return
                    end
					pickup(pointed_thing.under,player)
				end
			else
				if payload ~= "" then
					pickup(pointed_thing.under,player)
				end
			end
		end
    end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if digger:get_player_name() ~= "" then
            if oldnode.name == "symmetool:mirror" then
                local pmeta = digger:get_meta()
                pmeta:set_string("payload",nil)
                pmeta:set_string("center",nil)
            end
		end
		remove_entity(pos)
	end,
})

-- ======================================= --
-- 3 axis (X,Y,Z) entity & model node definition
-- ======================================= --

for axis_name,axis_color in pairs(axis_colors) do
    local box = boxen[axis_name]
    minetest.register_entity("symmetool:"..axis_name.."axis", {
        physical = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
        visual = "wielditem",
        -- wielditem seems to be scaled to 1.5 times original node size
        --visual_size = {x = 0.67, y = 0.67},
        textures = {"symmetool:"..axis_name.."_axis_node"},
        timer = 0,
        glow = 14,
    })
    minetest.register_node("symmetool:"..axis_name.."_axis_node", {
        tiles = {"symmetool_wall.png^[colorize:"..axis_color.."60"},
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

-- ======================================= --
-- Registrations
-- ======================================= --

minetest.register_on_leaveplayer(function(player)
    local pmeta = player:get_meta()
    if pmeta:get_string("center") ~= "" then
        local opos=minetest.deserialize(pmeta:get_string("center"))
        pickup(opos,player)
	    remove_entity(opos)
    end
    pmeta:set_string("center",nil)
    pmeta:set_string("payload",nil)
end)

-- minetest.register_on_joinplayer(function(player)
--     local pmeta = player:get_meta()
--     pmeta:set_string("center",nil)
--     pmeta:set_string("payload",nil)
-- end)
