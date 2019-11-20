-- symmetool v0.1
-- (c)2019 Nigel Garnett.

symmetool = {}
symmetool.axis_list = { "X-Axis","Y-Axis","Z-Axis","XY-Axes","YZ-Axes","XZ-Axes","XYZ-Axes" }


local l = 2
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
    local aname = string.lower(string.split(symmetool.axis_list[axis],"-")[1])
    remove_entity(pos)
    minetest.add_entity(pos, "symmetool:"..aname.."axis")
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
		payload = " Punch a node with the tool to start building"
	else
		payload = " Building with "..payload
	end
	minetest.chat_send_player(player:get_player_name(), symmetool.axis_list[a]..payload)
end

local function super_build(pos,player,node_name)
    local pmeta = player:get_meta()
    if pmeta:get_string("center") ~= "" then
        local center = minetest.deserialize(pmeta:get_string("center"))
        local axis = pmeta:get_int("axis")
        local reflect_axes = string.lower(string.split(symmetool.axis_list[axis],"-")[1])
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
			if node_name == "air" then
				local old_node_name = minetest.get_node(coord).name
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


minetest.register_node("symmetool:mirror", {
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
		local node_name = minetest.get_node(pointed_thing.under).name
		if node_name == "symmetool:mirror" then
			cycle_axis(placer)
			inform_state(placer)
			replace_node(pos,placer,"air")
			return
		end
        local pmeta = placer:get_meta()
		local payload = pmeta:get_string("payload")
		if payload ~= "" then
			print(payload)
			super_build(pos,placer,payload)
			return
		end
		local center = pmeta:get_string("center")
		if center ~= "" and payload == "" then
			local opos=minetest.deserialize(pmeta:get_string("center"))
			pickup(opos,placer)
		    remove_entity(opos)
			center = pmeta:get_string("center")
		end
		if  center == "" then
			pmeta:set_int("axis",1)
			pmeta:set_string("center",minetest.serialize(pos))
			inform_state(placer)
			show_entity(pos,1)
		end
    end,
    on_use = function(itemstack, player, pointed_thing)
        local pmeta = player:get_meta()
		if pointed_thing.type == "nothing" then
			pmeta:set_string("payload",nil)
			minetest.chat_send_player(player:get_player_name(),"Cleared.")
			inform_state(player)
		end
		if pointed_thing.type == "node" then
	        local node_name = minetest.get_node(pointed_thing.under).name
			local payload = pmeta:get_string("payload")
			if (node_name == "symmetool:mirror" and player:get_player_control().sneak) or
					( node_name == "symmetool:mirror" and payload == "" ) then
				print("spanking tool")
				pickup(pointed_thing.under,player)
			    remove_entity(pointed_thing.under)
				return
			end
			if pmeta:get_string("center") ~= "" then
				if payload == "" then
					pmeta:set_string("payload",node_name)
					minetest.chat_send_player(player:get_player_name(),"Now building with "..node_name)
				else
					pickup(pointed_thing.under,player)
					print("BOINGGGG")
				end
			else
				if payload ~= "" then
					pickup(pointed_thing.under,player)
					print("BOOB")
				end
			end
		end
    end,
-- 	after_dig_node = function(pos, oldnode, oldmetadata, digger)
-- 		if digger:get_player_name() ~= "" then
-- 			local pmeta = digger:get_meta()
-- 			pmeta:set_string("payload",nil)
-- 			pmeta:set_string("center",nil)
-- 		end
-- 		remove_entity(pos)
-- 	end,
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
    if pmeta:get_string("center") ~= "" then
        local opos=minetest.deserialize(pmeta:get_string("center"))
        pickup(opos,player)
	    remove_entity(pos)
    end
    pmeta:set_string("center",nil)
    pmeta:set_string("payload",nil)
end)

minetest.register_on_joinplayer(function(player)
    local pmeta = player:get_meta()
    pmeta:set_string("center",nil)
    pmeta:set_string("payload",nil)
end)


