
local state = false;

function ReceivedFromProxy( id, cmd, tParams )

	print( "ReceivedFromProxy " .. id .. ":" .. cmd );

	if ( id >= 100 and id <= 200 ) then

		if ( cmd == "OPENED" or cmd == "CLOSED" ) then 
			local deviceId = C4:GetBoundProviderDevice( 0, id )
			DeviceTrigger( deviceId )
		end

	end

	if ( id == 5001 and cmd == "SELECT" ) then

		local mode = "Off";
		if ( Properties["Mode"] ~= "Armed" ) then mode = "Armed" end

		C4:UpdateProperty( "Mode", mode );
		C4:SendToProxy( 5001, "ICON_CHANGED", {icon = mode })

	end

end

function OnDriverInit ()

	for i=0, 50 do
		C4:AddDynamicBinding( 100 + i, "CONTROL", false, "Contact Sensor " .. i, "CONTACT_SENSOR", false, false )
	end

	C4:AddVariable( "EVENT_TEXT", "NONE", "STRING", true, false )
	C4:AddVariable( "EVENT_DEVICE", "NONE", "STRING", true, false )
	C4:AddVariable( "EVENT_ROOM", "NONE", "STRING", true, false )

	DoBinds();

end


function OnPropertyChanged( strProperty )
	
	DoBinds();
	C4:SendToProxy( 5001, "ICON_CHANGED", {icon = Properties["Mode"] })

end

local LastUsedBinding = 100;

function BindDevice( deviceId )

	print( deviceId );

	local model = C4:GetDeviceData( deviceId, "model" );

	if ( model == "Motion Sensor" ) then
		C4:RegisterVariableListener( deviceId, 1000 ); -- ContactState
		return 1;
	end

	print( C4:GetDeviceData( deviceId) );

	return 0;

end

function DoBinds()
	
	local devices = Properties["Watch Devices"]:gmatch( "([^,]+)" )

	for deviceid in devices do
		if ( BindDevice( deviceid ) == 0 ) then
			print ( "Couldn't Bind Device ("..deviceid..")");
		end
	end

end

function DeviceTrigger( deviceId )
	
	if ( Properties["Mode"] ~= "Armed" ) then return end

	local deviceInfo = C4:GetDevices( { deviceIds = deviceId } )[deviceId];
	local deviceName = deviceInfo.deviceName;
	local roomName = deviceInfo.roomName ;

	local msg = "\"" .. deviceName .. "\" in " .. roomName .. " status changed";

	C4:SetVariable( "EVENT_TEXT", msg );
	C4:SetVariable( "EVENT_DEVICE", deviceName );
	C4:SetVariable( "EVENT_ROOM", roomName );

	C4:UpdateProperty( "Last Message", msg );

	print( msg );

	C4:FireEvent( "Triggered" );

end

function OnWatchedVariableChanged( idDevice, idVariable, strValue )
	DeviceTrigger( idDevice );
end



OnDriverInit ()