--
-- Created by IntelliJ IDEA.
-- User: Art-dell
-- Date: 1/3/2020
-- Time: 11:24 AM
-- To change this template use File | Settings | File Templates.
--
local attempt_count = 0
local max_attempt_count = 100
local waiting_time = 60000

local in_json = {}

print("-- SETUP WIFI --")
local files = file.list()
if files['wifi.json'] then
    file.open('wifi.json', "r")
    repeat
        local _line = file.readline()
        if _line ~= "" then
            if _line ~= nil then
                print(_line)
                in_json = sjson.decode(_line)

--                dofile("actions.lua")

--                resp_json = cjson.decode('{"type":"responce"}');
            end
        end
    until _line==nil
else

    -- send information about problemm (setting not found)

end

--wifi.sta.setip(cfg)
wifi_connected = false


if in_json~=nil then
    print('Wifi net name = '..in_json['SSID'])
    print('Wifi password = '..in_json['P'])
    --cfg = in_json["cfg"]
    wifi.setmode(wifi.STATION)

    local station_cfg={}
    station_cfg.ssid=in_json["SSID"]
    station_cfg.pwd=in_json["P"]
    station_cfg.save=false
    wifi.sta.config(station_cfg)

    local mytimer = tmr.create()

    mytimer:alarm(1000, tmr.ALARM_AUTO, function()
--    repeat
--        tmr.delay(2000000)
        if wifi.sta.getip() == nil then
            attempt_count = attempt_count + 1;
            print("Attempt "..attempt_count.." Connecting to AP...".."mode "..wifi.getmode())
            if attempt_count >= max_attempt_count then
--                tmr.stop(0)
                print ("Wifi unreacheble, switch to access point mode")
                print ("Will try to connect within "..(waiting_time/60000).." min")
                print ("You can adjust WiFi settings")

                wifi.setmode(wifi.SOFTAP)
                local cfg={}
                cfg.ssid="ESP_8266_"..node.chipid()
                cfg.pwd="MyCleaverHouse"
                wifi.ap.config(cfg)
                print("Access point mode enabled")
                print("WiFi net name \t\t"..cfg.ssid)
                print("WiFi net name \t\t"..cfg.pwd)
                print(wifi.ap.getip())

                do
                    print("\n  Default SoftAP configuration:")
                    for k,v in pairs(wifi.ap.getdefaultconfig(true)) do
                        print("   "..k.." :",v)
                    end
                end
--                mytimer1 = tmr.create()
--                mytimer1:alarm(waiting_time, 1, function() dofile("setup_wifi.lua") end)
--                if loc_json["server_started"] == false then
--                    loc_json["work_mode"]="wifi_setup_only"
----                    dofile("web_server.lua")
--                end

            end
        else
            mytimer:stop()
            print("wifi is connected")
            mac = wifi.sta.getmac()
            wifi_connected = true

            print("timer is stopt MAC : "..mac)
            local url = "http://ahome.tech/board_settings?mac="..mac
            http.get(url, nil, function(code, data)
                if (code < 0) then
                    print("HTTP request failed")
                else
                    print(code, data)
                    print(type(data))
                    local config = sjson.decode(data)
                    print('============================')
                    for k, v in pairs(config) do
                        print(k,v)
                        print('============================')
                        if k == "entity" then
                            for a, b in pairs(v) do
                                for e, r in pairs(b) do
                                    print(e, r)
                                    print('--------')
                                end
                                Pin = b['Pin']
                                tmr.create():alarm(b['Interval'], tmr.ALARM_AUTO, function()
                                    print("\n\n")
                                    local url = "http://ahome.tech/todo?mac="..mac
                                    http.get(url, nil, function(code, data)
                                        if (code < 0) then
                                            print("HTTP request failed")
                                        else
                                            print(code, data)
                                            local command = sjson.decode(data)
--                                            #######################
                                            for k1, v1 in pairs(command) do
                                                print(k1,v1)
                                                print('============================')
                                                if k1 == "entity" then
                                                    for a1, b1 in pairs(v1) do

                                                        print("Pin", Pin)
                                                        gpio.mode(Pin, gpio.OUTPUT)
                                                        print(gpio.read(Pin))
                                                        print(b1['Command'])
                                                        print(b1['SubCommand'])
                                                        if b1['Command'] == "RELAY" then
                                                            if b1['SubCommand'] == "switch" then
                                                                print("DO SWITCH")
                                                                if gpio.read(Pin) == gpio.HIGH then
                                                                    gpio.write(Pin, gpio.LOW)
                                                                else
                                                                    gpio.write(Pin, gpio.HIGH)
                                                                end
                                                            elseif b1['SubCommand'] == "on" then
                                                                print("DO ON")
                                                                gpio.write(Pin, gpio.HIGH)
                                                            elseif b1['SubCommand'] == "off" then
                                                                print("DO OFF")
                                                                gpio.write(Pin, gpio.LOW)
                                                            end
                                                        elseif b1['Command'] == "BOARD" then
                                                            if b1['SubCommand'] == "reset" then
                                                                tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() node.restart() end)
                                                            end
                                                        end
                                                        print(gpio.read(Pin))

                                                        local Obj = {}
                                                        Obj['CommandHash'] = b1['CommandHash']
                                                        Obj['CommandDone'] = true
                                                        Obj['CommandStatus'] = 'SUCCESSFUL'

                                                        http.request("http://ahome.tech/todo", "PATCH", 'Content-Type: text/plain\r\n', sjson.encode(Obj),
                                                            function(code, data)
                                                                if (code < 0) then
                                                                    print("HTTP request failed")
                                                                else
                                                                    print(code, data)
                                                                end
                                                            end)

                                                    end
                                                end
                                            end

--                                            #########################
                                        end
                                        collectgarbage()
                                    end)
                                end)
                            end
                        end
                    end
                end
            end)

            attempt_count = 0;
        end
    end)
--    until (wifi_connected)

    collectgarbage()
else
    print("!!! IN JSON - EMPTY !!!")
end
collectgarbage()
