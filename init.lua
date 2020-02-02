--
-- Created by IntelliJ IDEA.
-- User: Art-dell
-- Date: 1/3/2020
-- Time: 11:21 AM
-- To change this template use File | Settings | File Templates.
--
wifi_connected = false
mac = ""
config = {}
Pin = 0



print('!!! START NODE !!!')
if not tmr.create():alarm(10000, tmr.ALARM_SINGLE, function()
        dofile("wifi.lc")
        print("return to main application")
    end)
then
    print("!!! WARNING !!!")
end
collectgarbage()


maintimer = tmr.create()
maintimer:alarm(60000, tmr.ALARM_AUTO, function() sendStatus() end)


function sendStatus()
    if wifi_connected == true then
        print("SEND STATUS to SERVER")
        local pocket = {}
        pocket["mac"] = mac
        pocket["valuetype"] = "relay"
        pocket["value"] = gpio.read(Pin)
        pocket["unit"] = "ON(1)/OFF(0)"
        print(sjson.encode(pocket))
        http.post('http://ahome.tech/sensors_data',
            'Content-Type: application/json\r\n',
            sjson.encode(pocket),
            function(code, data)
                if (code < 0) then
                    print("HTTP request failed")
                else
                    print(code, data)
                end
            end)

        --                    GPIO 0 = 5 pin
        --                    GPIO 2 = 3 pin
    else
        print("Wifi not connected ?")
    end
end
