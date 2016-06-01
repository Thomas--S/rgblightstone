rgblightstone = {}

if type(minetest.colorize) == "function" then
	rgblightstone.colorize = minetest.colorize
else
	rgblightstone.colorize = function(color,text)
		return text
	end
end

function rgblightstone.autofill(pos,player)
	local meta = minetest.get_meta(pos)
	if (not meta:get_string("channel")) or meta:get_string("channel")=="" then
		local pos_above = {x=pos.x,y=pos.y+1,z=pos.z}
		local node_above = minetest.get_node(pos_above)
		local meta_above = minetest.get_meta(pos_above)
		if string.match(node_above.name,"rgblightstone") and
		meta_above:get_string("channel") and
		tonumber(meta_above:get_string("addrx")) and
		tonumber(meta_above:get_string("addry")) then
			local channel = meta_above:get_string("channel")
			local addrx = meta_above:get_string("addrx")
			local addry = tostring(1+tonumber(meta_above:get_string("addry")))
			meta:set_string("channel",channel)
			meta:set_string("addrx",addrx)
			meta:set_string("addry",addry)
			minetest.chat_send_player(player:get_player_name(),rgblightstone.colorize("#55FF55","Success: ").."Auto-filled with channel "..rgblightstone.colorize("#00FFFF",channel)..", X address "..rgblightstone.colorize("#00FFFF",addrx)..", and Y address "..rgblightstone.colorize("#00FFFF",addry)..".")
			meta:set_string("infotext","")
		else
			minetest.chat_send_player(player:get_player_name(),rgblightstone.colorize("#FF0000","ERROR: ").."Node above is not RGB Lightstone or is not configured correctly!")
		end
	end
end

minetest.register_entity("rgblightstone:entity",{
	hp_max = 1,
	physical = false,
	collisionbox = {0,0,0,0,0,0},
	visual_size = {x=1.003, y=1.003},
	visual = "cube",
	is_visible = true
})

minetest.register_node("rgblightstone:rgblightstone", {
	tiles = {"jeija_lightstone_darkgray_off.png^[colorize:#000000FF"},
	groups = {cracky=2},
	sunlight_propagates = true,
	paramtype = "light",
	description = "RGB Lightstone",
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[8,5;]field[1,1;6,2;channel;Channel;${channel}]field[1,2;2,2;addrx;X Address;${addrx}]field[5,2;2,2;addry;Y Address;${addry}]button_exit[2.25,3;3,1;submit;Save]button_exit[2.25,4;3,1;autofill;Auto-Fill From Node Above]label[3,2;Leave address blank\nfor individual mode]")
		meta:set_string("infotext","Not configured! Right-click to set up manually, or punch to auto-fill from the node above.")
		meta:set_string("color","000000")
	end,
	on_destruct = function(pos)
		local objs = minetest.get_objects_inside_radius(pos,0.5)
		for _,obj in ipairs(objs) do
			if obj:get_luaentity().name == "rgblightstone:entity" then
				obj:remove()
			end
		end
	end,
	on_punch = function(pos, node, player, pointed_thing)
		rgblightstone.autofill(pos,player)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if fields.autofill then
			rgblightstone.autofill(pos,sender)
		else
			if fields.channel then
				meta:set_string("channel", fields.channel)
				meta:set_string("infotext","")
			end
			if fields.addrx then meta:set_string("addrx",fields.addrx) end
			if fields.addry then meta:set_string("addry",fields.addry) end
		end
	end,
	light_source = 0,
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local meta = minetest.get_meta(pos)
				local setchan = meta:get_string("channel")
				if channel ~= setchan then
					return
				end

				local addrx = tonumber(meta:get_string("addrx"))
				local addry = tonumber(meta:get_string("addry"))

				if type(msg) == "table" then
					if not (addrx and addry and type(msg[addry]) == "table" and msg[addry][addrx]) then
						return
					end
					msg = msg[addry][addrx]
				end

				--Validation starts here
				if type(msg) ~= "string" then
					return
				end
				msg = string.upper(msg)
				--Drop a leading # if present (e.g. "#FF55AA")
				if string.sub(msg,1,1) == "#" then
					msg = string.sub(msg,2)
				end
				--Check length
				if string.len(msg) ~= 6 then
					return
				end
				--Make sure there aren't any invalid chars
				local acceptable_chars = {["0"]=true,["1"]=true,["2"]=true,["3"]=true,["4"]=true,["5"]=true,["6"]=true,["7"]=true,["8"]=true,["9"]=true,["A"]=true,["B"]=true,["C"]=true,["D"]=true,["E"]=true,["F"]=true}
				for i = 1,6,1 do
					if not acceptable_chars[string.sub(msg,i,i)] then
						return
					else
					end
				end
				--Should be a valid hex color by this point
				
				--Remove old entity, if present
				local objs = minetest.get_objects_inside_radius(pos,0.5)
				for _,obj in ipairs(objs) do
					if obj:get_luaentity().name == "rgblightstone:entity" then
						obj:remove()
					end
				end

				--Create a new entity
				local obj = minetest.add_entity(pos,"rgblightstone:entity")
				
				--Set to the correct color
				meta:set_string("color",msg)
				local tex = "jeija_lightstone_darkgray_off.png^[colorize:#"..msg.."FF"
				obj:set_properties({textures = {tex,tex,tex,tex,tex,tex}})
			end
		}
	}
})

minetest.register_lbm({
	name = "rgblightstone:reset_entities",
	nodenames = {"rgblightstone:rgblightstone"},
	run_at_every_load = true,
	action = function(pos)
		local objs = minetest.get_objects_inside_radius(pos,0.5)
		for _,obj in ipairs(objs) do
			if obj:get_luaentity().name == "rgblightstone:entity" then
				obj:remove()
			end
		end
		local meta = minetest.get_meta(pos)
		local color = meta:get_string("color")
		if color == "" then
			return
		end
		local tex = "jeija_lightstone_darkgray_off.png^[colorize:#"..color.."FF"
		local obj = minetest.add_entity(pos,"rgblightstone:entity")
		obj:set_properties({textures = {tex,tex,tex,tex,tex,tex}})
	end
})


minetest.register_craft({
	output = "rgblightstone:lightstone",
	recipe = {
		{"","mesecons_lightstone:lightstone_green_off",""},
		{"mesecons_lightstone:lightstone_red_off","mesecons_luacontroller:luacontroller0000","mesecons_lightstone:lightstone_blue_off"},
		{"","digilines:wire_std_00000000",""}
	}
})
