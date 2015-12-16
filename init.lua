rgblightstone = {}
rgblightstone.colors = {"off","black","blue","brown","cyan","darkblue","darkcyan","darkgray","darkgreen","darkmagenta","darkred","gray","green","magenta","red","white","yellow"}
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
			minetest.chat_send_player(player:get_player_name(),"Successfully auto-filled with channel "..channel..", X address "..addrx..", and Y address "..addry..".")
			meta:set_string("infotext","")
		else
			minetest.chat_send_player(player:get_player_name(),"Node above is not RGB Lightstone or is not configured correctly!")
		end
	end
end

function rgblightstone.add(name)
	minetest.register_node("rgblightstone:lightstone_" .. name, {
		tiles = name == "off" and {"jeija_lightstone_darkgray_off.png"} or {"rgblightstone_"..name..".png"},
		drop = "rgblightstone:lightstone_off",
		groups = name == "off" and {cracky=2} or {cracky=2,not_in_creative_inventory=1},
		description="RGB Lightstone ("..name..")",
		sounds = default.node_sound_stone_defaults(),
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", "size[8,5;]field[1,1;6,2;channel;Channel;${channel}]field[1,2;2,2;addrx;X Address;${addrx}]field[5,2;2,2;addry;Y Address;${addry}]button_exit[2.25,3;3,1;submit;Save]button_exit[2.25,4;3,1;autofill;Auto-Fill From Node Above]label[3,2;Leave address blank\nfor individual mode]")
			meta:set_string("infotext","Not configured! Right-click to set up manually, or punch to auto-fill from the node above.")
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
		light_source = name~= "off" and default.LIGHT_MAX-2 or 0,
		digiline = {
			receptor = {},
			effector = {
				action = function(pos, node, channel, msg)
					local channel_set = minetest.get_meta(pos):get_string("channel")
					local xaddr = minetest.get_meta(pos):get_string("addrx")
					local yaddr = minetest.get_meta(pos):get_string("addry")
					if channel==channel_set and msg ~= nil then
						if xaddr ~= nil and xaddr ~= "" and yaddr ~= nil and yaddr ~= "" and type(msg) == "table" then
							for _,color in ipairs(rgblightstone.colors) do
								if msg[tonumber(yaddr)] ~= nil and msg[tonumber(yaddr)][tonumber(xaddr)] ~= nil and msg[tonumber(yaddr)][tonumber(xaddr)] == color and msg[tonumber(yaddr)][tonumber(xaddr)] ~= minetest.get_node(pos).color then
									minetest.swap_node(pos, {name = "rgblightstone:lightstone_"..color})
								end
							end
						elseif type(msg) == "string" then
							for _,color in ipairs(rgblightstone.colors) do
								if msg == color and msg ~= minetest.get_node(pos).color then
									minetest.swap_node(pos, {name = "rgblightstone:lightstone_"..color})
								end
							end
						end
					end
				end
			}
		}
	})
end
for _,i in ipairs(rgblightstone.colors) do rgblightstone.add(i) end
if minetest.get_modpath("mesecons_luacontroller") and minetest.get_modpath("digilines") then
	minetest.register_craft({
		output = "rgblightstone:lightstone_off",
		recipe = {
			{"","mesecons_lightstone:lightstone_green_off",""},
			{"mesecons_lightstone:lightstone_red_off","mesecons_luacontroller:luacontroller0000","mesecons_lightstone:lightstone_blue_off"},
			{"","digilines:wire_std_00000000",""}
		}
	})
else
        minetest.register_craft({
                output = "rgblightstone:lightstone_off",
                recipe = {
                        {"","mesecons_lightstone:lightstone_green_off",""},
                        {"mesecons_lightstone:lightstone_red_off","group:mesecon_conductor_craftable","mesecons_lightstone:lightstone_blue_off"},
                        {"","group:mesecon_conductor_craftable",""}
                }
        })
end
