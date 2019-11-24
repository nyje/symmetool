-- ======================================= --
-- Symmetool Mirror v1.2
-- (c)2019 Nigel Garnett.
-- ======================================= --
-- User Settable Variables
-- ======================================= --
local max_range = 50
local length = 2
local axis_colors = {x = "#FF0000", y = "#00FF00", z = "#0000FF"}
local axis_timer = 10
local default_axis = 6  -- (XZ Axes - good for towers & castles)


-- ======================================= --
-- Main vars
-- ======================================= --
m_node = "symmetool:mirror"
local axis_list = {"X-Axis","Y-Axis","Z-Axis","XY-Axes","YZ-Axes","XZ-Axes","XYZ-Axes"}
local boxen = {}
boxen.x = {{-.05, -(length+.05), -(length+.05), .05, (length+.05), (length+.05)}}
boxen.y = {{-(length+.05), -.05, -(length+.05), (length+.05), .05, (length+.05)}}
boxen.z = {{-(length+.05), -(length+.05), -.05, (length+.05), (length+.05), .05}}


-- ======================================= --
-- Local functions
-- ======================================= --
local function flip(pos, center, axis)
    local new_pos = {x = pos.x, y = pos.y, z = pos.z}
    local r = pos[axis] - center[axis]
    new_pos[axis] = pos[axis] - 2 * r
    return new_pos
end


local function remove_entities(pos)
    local aobj = minetest.get_objects_inside_radius(pos, 1)
    for _, obj in ipairs(aobj) do
        if obj then
            if not obj:is_player() then
                obj:remove()
            end
        end
    end
end


local function add_entities(pos, axis)
    local aname = string.lower(string.split(axis_list[axis], "-")[1])
    remove_entities(pos)
    for i = 1, #aname do
        minetest.add_entity(pos, "symmetool:"..string.sub(aname, i, i).."axis")
    end
end


local function replace_node(pos, player, node_name)
    if pos then
		if not minetest.is_protected(pos, player:get_player_name()) then
			minetest.set_node(pos, {name = node_name})
            minetest.check_for_falling(pos)
		end
    end
end


local function cycle_axis(player)
    local pmeta = player:get_meta()
	if pmeta:get_string("center") ~= "" then
		local center = minetest.deserialize(pmeta:get_string("center"))
		local axis = pmeta:get_int("axis") + 1
		if axis == 8 then axis = 1 end
		pmeta:set_int("axis", axis)
		add_entities(center, axis)
	end
end


local function inform_state(player)
    local pmeta = player:get_meta()
    local axis = pmeta:get_int("axis")
	local payload = pmeta:get_string("payload")
	local msg
	if payload == "" then
		msg = minetest.colorize('#F55', " Punch a node with the tool to start building")
	else
		msg = minetest.colorize('#F5F', " Building with ")..
				minetest.colorize('#9FF',payload)
	end
	msg = minetest.colorize('#5F5', axis_list[axis])..msg
	minetest.chat_send_player(player:get_player_name(), msg)

	local center = minetest.deserialize(pmeta:get_string("center"))
	local meta = minetest.get_meta(center)
	meta:set_string("infotext", "Mirroring in "..axis_list[axis])
end


local function super_build(pos, player, node_name)
    local pmeta = player:get_meta()
    if pmeta:get_string("center") ~= "" then
        local center = minetest.deserialize(pmeta:get_string("center"))
        local axis = pmeta:get_int("axis")
        local reflect_axis = string.lower(string.split(axis_list[axis], "-")[1])
        local coords = {pos}
        for i = 1, #reflect_axis do
            local this_axis = string.sub(reflect_axis, i, i)
			local new_coords = {}
            for _, coord in pairs(coords) do
				new_coords[#new_coords + 1] = coord
				new_coords[#new_coords + 1] = flip(coord, center, this_axis)
            end
			coords = new_coords
        end
        for _, coord in pairs(coords) do
			local old_node = minetest.get_node(coord)
			if old_node.name ~= "air"  and node_name == "air" then
                minetest.node_dig(coord,old_node,player)
			end
			replace_node(coord, player, node_name)
        end
    else
		replace_node(pos, player, node_name)
	end
end


local function pickup(pos, player)
	local node = minetest.get_node(pos)
    minetest.node_dig(pos,node,player)
	if node.name == m_node then
		local pmeta = player:get_meta()
		pmeta:set_string("payload", nil)
		pmeta:set_string("center", nil)
		remove_entities(pos)
	end
end


-- ======================================= --
-- Symmetool Mirror Node definition
-- ======================================= --
minetest.register_node(m_node, {
    description = "Mirror Symmetry Tool",
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
					{-0.125, -0.5, -0.5, 0.125, 0.5, 0.5},
					{-0.5, -0.125, -0.5, 0.5, 0.125, 0.5},
					{-0.5, -0.5, -0.125, 0.5, 0.5, 0.125},
		}
	},
    tiles = {"symmetool_mirror.png^[colorize:#00ffff:100"},
    is_ground_content = false,
    stack_max = 1,
    light_source = core.LIGHT_MAX,
    sunlight_propagates = 1,
    groups = {cracky = 1, snappy = 1, crumbly = 1},

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local pmeta = placer:get_meta()
		local center_string = pmeta:get_string("center")
		local payload = pmeta:get_string("payload")
		local node_name = minetest.get_node(pointed_thing.under).name

		if node_name == m_node and payload == "" then
			replace_node(pos, placer, "air")
			cycle_axis(placer)
			inform_state(placer)
			return
		end

		if payload ~= "" then
            local center_pos = minetest.deserialize(center_string)
            if (center_string ~= "") and
                    (vector.distance( center_pos, pointed_thing.under) > max_range) then
    			replace_node(pos, placer, "air")
                minetest.chat_send_player(placer:get_player_name(), minetest.colorize(
						"#FFF", "Too far from center, symmetry marker removed."))
                pickup(center_pos, placer)
                return
            end
			super_build(pos, placer, payload)
			return
		end

		if center_string ~= "" and payload == "" then
			local center_pos = minetest.deserialize(pmeta:get_string("center"))
			pickup(center_pos, placer)
			center_string = pmeta:get_string("center")
		end

		if  center_string == "" then
			pmeta:set_int("axis", default_axis)
			pmeta:set_string("center", minetest.serialize(pos))
			inform_state(placer)
			add_entities(pos, default_axis)
		end
    end,

    on_use = function(itemstack, player, pointed_thing)
		local pname = player:get_player_name()
        local pmeta = player:get_meta()
		local center_string = pmeta:get_string("center")

		if pointed_thing.type == "nothing" and center_string ~= "" then
			pmeta:set_string("payload", nil)
			minetest.chat_send_player(pname, minetest.colorize("#F5F", "Cleared."))
			inform_state(player)
		end

		if pointed_thing.type == "node" then
	        local node_name = minetest.get_node(pointed_thing.under).name
			local payload = pmeta:get_string("payload")

			if (node_name == m_node and player:get_player_control().sneak) or
					( node_name == m_node and payload == "" ) then
				pickup(pointed_thing.under,player)
				return
			end

			if center_string ~= "" then
				if payload == "" then
					pmeta:set_string("payload",node_name)
					local msg = minetest.colorize("#F5F", "Now building with ")..
						minetest.colorize("#9FF", node_name)
					minetest.chat_send_player(pname, msg)
				else
                    local center_pos = minetest.deserialize(center_string)

                    if vector.distance(center_pos, pointed_thing.under) > max_range then
                        minetest.chat_send_player(pname, minetest.colorize("#FFF",
								"Too far from center, symmetry marker removed."))
                        pickup(center_pos, player)
                        return
                    end
					super_build(pointed_thing.under, player,"air")
				end
			else
				super_build(pointed_thing.under, player,"air")
			end
		end
    end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if digger:get_player_name() ~= "" then
            local pmeta = digger:get_meta()
            pmeta:set_string("payload", nil)
            pmeta:set_string("center", nil)
		end
		remove_entities(pos)
	end,
})


-- ======================================= --
-- 3 axis (X,Y,Z) entity & model node definition. based on Protector redo by TenPlus1
-- ======================================= --
for axis_name,axis_color in pairs(axis_colors) do
    local box = boxen[axis_name]

    minetest.register_entity("symmetool:"..axis_name.."axis", {
        physical = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
        visual = "wielditem",
        textures = {"symmetool:"..axis_name.."_axis_node"},
        timer = 0,
        glow = 14,
		on_step = function(self, dtime)
			self.timer = self.timer + dtime
			if self.timer > axis_timer then
				self.object:remove()
			end
		end,
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
        local opos = minetest.deserialize(pmeta:get_string("center"))
        pickup(opos, player)
    end
    pmeta:set_string("center", nil)
    pmeta:set_string("payload", nil)
end)
