ESX = nil
local _PlayerPedId, inWork, listening, write, cam
local buffer = ''
local params = {}

Citizen.CreateThread(function()

    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    _PlayerPedId = PlayerPedId()

    local x, y, z, coord, camX, camY, camZ
    local forward = {}
    local hfov, vfov = 90.0, 50.0

    local camZDist, camDist1, camDist2, headingMod

    params = {
        xDistance = 7.5,
        yDistance = 5.0,
        xLine = 5,
        yLine = 3,
        heading = GetEntityHeading(_PlayerPedId)
    }


    while true do

        Citizen.Wait(0)

        if inWork then

            coord = GetEntityCoords(_PlayerPedId)

            forward.x = math.sin(math.rad(params.heading))
            forward.y = math.cos(math.rad(params.heading))

            camX = coord.x - forward.x * params.xDistance * (params.xLine - 1) / 2 + forward.y * params.yDistance * (params.yLine - 1) / 2
            camY = coord.y + forward.y * params.xDistance * (params.xLine - 1) / 2 + forward.x * params.yDistance * (params.yLine - 1) / 2

            if params.xDistance * params.xLine > params.yDistance * params.yLine then

                camDist1 = params.xLine / 2 * params.xDistance / math.tan(math.rad(hfov / 2))
                camDist2 = params.yLine / 2 * params.yDistance / math.tan(math.rad(vfov / 2))

                headingMod = 90.0
            else

                camDist1 = params.xLine / 2 * params.xDistance / math.tan(math.rad(vfov / 2))
                camDist2 = params.yLine / 2 * params.yDistance / math.tan(math.rad(hfov / 2))

                headingMod = 0.0
            end

            camZDist = camDist1 > camDist2 and camDist1 or camDist2

            if camZDist < 2.0 then camZDist = 2.0 end

            if cam then

                SetCamCoord(cam, camX, camY, camZ + camZDist )
                SetCamRot(cam, -90.0, 0.0, params.heading + headingMod, 2)
            end

            camZ = 0

            for i = 1, params.xLine do

                x = coord.x - forward.x * (i - 1) * params.xDistance
                y = coord.y + forward.y * (i - 1) * params.xDistance

                for j = 1, params.yLine do

                    _, z = GetGroundZFor_3dCoord_2(x, y, coord.z + 20.0, 0)

                    if camZ < z then camZ = z end

                    if write then

                        buffer = buffer .. ("{ ID, vector3(%s, %s, %s) },\n"):format(FormatCoord(x), FormatCoord(y), FormatCoord(z + 1))
                    end

                    DrawMarker(28, x, y, z + 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 0, 255, false, false, 2, false, false, false, false)

                    x = x + forward.y * params.yDistance
                    y = y + forward.x * params.yDistance
                end
            end

            if write then

                TriggerServerEvent('sowing:saveCoord', buffer)

                SendNUIMessage({
                    subject = 'SAVE_TO_CLIPBOARD',
                    data = buffer
                })

                write = nil
                buffer = ''
            end

        else

            Citizen.Wait(1000)
        end
    end
end)


RegisterCommand('sowing', function(source, args, raw)

    _PlayerPedId = PlayerPedId()

    if inWork then

        inWork = false
        listening = false

        SetNuiFocus(false, false)
        SendNUIMessage({
            subject = 'CLOSE'
        })

    else

        inWork = true
        listening = true

        SendNUIMessage({
            subject = 'OPEN',
            data = params
        })

        TriggerEvent("eco_sowing:listening")
    end
end)


AddEventHandler('eco_sowing:control', function()

    _PlayerPedId = PlayerPedId()

    inWork = true


    SetNuiFocus(true, true)
    SendNUIMessage({
        subject = 'OPEN',
        data = params
    })


    if not cam then

        local curCam = GetRenderingCam()
        local camPos = GetCamCoord(curCam)

        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camPos.x, camPos.y, camPos.z + 100.0, -90.0, 0.0, params.heading, 60.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, 1, 1000, 1, 1);
        SetCamActiveWithInterp(curCam, cam, 1, 1000, 1)
    end
end)


AddEventHandler('eco_sowing:listening', function()

    Citizen.CreateThread(function()

        while listening do

            Citizen.Wait(0)

            if IsControlJustPressed(0, 36) then -- LEFT CTRL

                TriggerEvent("eco_sowing:control")
                listening = false
            end
        end
    end)
end)


RegisterNUICallback('paramSet', function(data, cb)

    params[data.key] = tonumber(data.value) + 0.0
    cb('ok')
end)


RegisterNUICallback('saveCoords', function(data, cb)

    write = true
    cb('ok')
end)


RegisterNUICallback('exit', function(data, cb)

    SetCamActive(cam, false)
    DestroyCam(cam, true)
    RenderScriptCams(false, 1, 1000, 1, 1);
    cam = nil

    SetNuiFocus(false, false)

    if data.inWork == 'off' then

        inWork = false
    else

        listening = true
        TriggerEvent("eco_sowing:listening")
    end

    cb('ok')
end)


FormatCoord = function(coord)

    if coord == nil then return "unknown" end

    return tonumber(string.format("%.2f", coord))
end