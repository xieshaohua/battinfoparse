#!/usr/bin/lua

local logfile = "./batt123.log"
local xlsfile = ""
local battinfo_tbl = {}
local item_number = 0;
local line_counter = 0;
local parse_state = 0;
local match_start = false

--[[
	test if it is the timestamp line
--]]
function find_timestamp(l)
	if string.find(l, "%d+-%d+-%d+%s+%d+:%d+:%d+") ~= nil then
		return true
	else
		return false
	end
end

--[[
	store the timestamp data to the item table
--]]
function match_timestamp(t, l)
	local year, month, day, hour, minute, second = string.match(l, "(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)")
	-- print(year .. ":" .. month .. ":" .. day .. ":" .. hour .. ":" .. minute .. ":" .. second)
	t.year = tonumber(year)
	t.month = tonumber(month)
	t.day = tonumber(day)
	t.hour = tonumber(hour)
	t.minute = tonumber(minute)
	t.second = tonumber(second)
end

--[[
	calculate how many lines span between items
--]]
function test_itemspan(filename)
	local start_flag = false
	local count = 0;
	
	f = io.open (filename, "r")
	if f == nil then
		return nil
	end
	
	for line in f:lines() do		
		if find_timestamp(line) then
			if start_flag == false then
				start_flag = true
			else
				io.close(f)
				return count - 1
			end
		end
		if start_flag == true then
			count = count + 1
		end
	end
	io.close(f)
	return nil
end

--[[
	store the battery info data to the item table
--]]
function match_battinfomation(t, s)
	t.status = string.match(s, "POWER_SUPPLY_STATUS=(.-)|")
	t.charging_enabled = tonumber(string.match(s, "POWER_SUPPLY_CHARGING_ENABLED=(%d+)"))
	t.capacity = tonumber(string.match(s, "POWER_SUPPLY_CAPACITY=(%d+)"))
	t.health = string.match(s, "POWER_SUPPLY_HEALTH=(.-)|")
	t.current_now = tonumber(string.match(s, "POWER_SUPPLY_CURRENT_NOW=(-?%d+)"))
	t.voltage_now = tonumber(string.match(s, "POWER_SUPPLY_VOLTAGE_NOW=(%d+)"))
	t.temp = tonumber(string.match(s, "POWER_SUPPLY_TEMP=(-?%d+)"))
	t.charge_type = string.match(s, "POWER_SUPPLY_CHARGE_TYPE=(.-)|")
end

--[[
	dispaly the items data
--]]
function display_items(t, n)
	print("total item number is " .. n)
	for i = 1, n do
		print(string.format("%.4d-%.2d-%.2d %.2d:%.2d:%.2d\t%12s\t%1d\t%3d%%\t%12s\t%8d\t%8d\t%4d\t%8s",
					battinfo_tbl[i].year,
					battinfo_tbl[i].month,
					battinfo_tbl[i].day,
					battinfo_tbl[i].hour,
					battinfo_tbl[i].minute,
					battinfo_tbl[i].second,
					battinfo_tbl[i].status,
					battinfo_tbl[i].charging_enabled,
					battinfo_tbl[i].capacity,
					battinfo_tbl[i].health,
					battinfo_tbl[i].current_now,
					battinfo_tbl[i].voltage_now,
					battinfo_tbl[i].temp,
					battinfo_tbl[i].charge_type))
	end
end

local str_span = ""
local item_span = test_itemspan(logfile)
assert(item_span, "Can't calculate item span, please check the log file integrity")
print("Calculated item span is " .. item_span)

for line in io.lines(logfile) do
	if match_start == false then
		if find_timestamp(line) then
			item_number = item_number + 1
			battinfo_tbl[item_number] = {}
			match_timestamp(battinfo_tbl[item_number], line)
			parse_state = 0
			str_span = ""
			line_counter = 0
			match_start = true
		end
	else
		assert(find_timestamp(line) == false, string.format("Log fatal error at line %d",
							item_number * item_span + line_counter))
		str_span = string.format("%s%s|", str_span, line)
		line_counter = line_counter + 1
		if line_counter == item_span then
			--print(str_span)
			match_battinfomation(battinfo_tbl[item_number], str_span)
			--print(battinfo_tbl[item_number].capacity)
			match_start = false
		end
	end
end

display_items(battinfo_tbl, item_number)
