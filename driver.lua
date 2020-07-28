
UIBUTTON = 5001;

MODE_OFF = 0;
MODE_COOL = 1;
MODE_COOLX = 2;
MODE_HEAT = 3;
MODE_HEATX = 4;

CurrentMode = MODE_OFF;

LastChangedTime = os.time();
ApplyTimer = -1;
HoldTime = 0;

function ReceivedFromProxy(id, cmd, tParams)

	if ( id == UIBUTTON and cmd == "SELECT" ) then
		NextMode();
		return;
	end

	if ( id < 20 and cmd == "DO_PUSH") then
		HoldTime = os.time();
	end

	if ( id < 20 and ( cmd == "DO_CLICK" or cmd == "DO_RELEASE" )) then

		local pressTime = os.time() - HoldTime;
		local target = MODE_COOL;
		if ( id < 10 ) then target = MODE_HEAT end

		print ( "press time is " .. pressTime)
		if ( cmd == "DO_RELEASE" and pressTime > 1 ) then

			print ( "long press detected" )

			if ( target == MODE_COOL ) then target = MODE_COOLX end
			if ( target == MODE_HEAT ) then target = MODE_HEATX end

		elseif ( CurrentMode ~= MODE_OFF ) then

			if ( CurrentMode == target or CurrentMode == target + 1 ) then target = MODE_OFF end

		end

		CurrentMode = target;

		ApplyColors();
		ApplyBacklight()

		ApplyModeDebounced();

	end

	print( "ReceivedFromProxy " .. id .. ":" .. cmd );

end


function OnDriverInit ()
	UpdateButtonColors();
	ApplyColors();
	C4:SendToProxy(UIBUTTON, "ICON_CHANGED", {icon = "mode" .. CurrentMode })
end


function OnPropertyChanged(strProperty)

	print( "OnPropertyChanged " .. strProperty );

	UpdateButtonColors();
end

function NextMode()

	CurrentMode = CurrentMode + 1;
	if ( CurrentMode > MODE_HEATX ) then CurrentMode = MODE_OFF end
	if ( os.time() - LastChangedTime > 6 and CurrentMode > MODE_OFF+1 ) then CurrentMode = MODE_OFF end

	ApplyModeDebounced();
	ApplyColors();

end

function ApplyModeDebounced()
	
	ApplyTimer = -1;

	LastChangedTime = os.time();
	C4:SendToProxy(UIBUTTON, "ICON_CHANGED", {icon = "mode" .. CurrentMode })
	ApplyColors();

	ApplyTimer = C4:AddTimer( 5, "SECONDS", false )

end

function OnTimerExpired( id )

	print( "OnTimerExpired " .. id );

	if ( id == ApplyTimer ) then 
		ApplyTimer = -1;
		ApplyMode();
	end

end

function ApplyMode()


	print( os.time() .. ": ApplyMode " .. CurrentMode );

	local mode = "Off";
	local temp = 21;

	if ( CurrentMode == MODE_COOL ) then

		mode = "Cool";
		temp = Properties["Cool Temperature"];

	elseif ( CurrentMode == MODE_COOLX ) then

		mode = "Cool";
		temp = Properties["ExtraCool Temperature"];

	elseif ( CurrentMode == MODE_HEAT ) then

		mode = "Heat";
		temp = Properties["Heat Temperature"];

	elseif ( CurrentMode == MODE_HEATX ) then

		mode = "Heat";
		temp = Properties["ExtraHeat Temperature"];

	end

	local thermostats = Properties["Targets"]:gmatch( "([^,]+)" )

	ApplyBacklight();

	for deviceid in thermostats do

		C4:SendToDevice( deviceid, "SET_MODE_FAN", { MODE = "High" } )
		C4:SendToDevice( deviceid, "SET_MODE_HVAC", { MODE = mode } )
		C4:SendToDevice( deviceid, "SET_SETPOINT_SINGLE", { CELSIUS = temp } )

	end

	print( os.time() .. ": Finished ApplyMode " .. CurrentMode );

end


function UpdateButtonColors()

	local heatcolor = RGB2HEX( Properties["Heat Button Color"] )
	local coolcolor = RGB2HEX( Properties["Cool Button Color"] )

	for t=1,5 do
		C4:SendToProxy (t, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = heatcolor}, OFF_COLOR = {COLOR_STR = '000000'}}, "NOTIFY")
	end

	for t=10,14 do
		C4:SendToProxy (t, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = coolcolor}, OFF_COLOR = {COLOR_STR = '000000'}}, "NOTIFY")
	end

end

function ApplyColors()

	local cooling = '0';
	local heating = '0';

	if ( CurrentMode == MODE_COOLX or CurrentMode == MODE_COOL ) then
		cooling = '1'
	end

	if ( CurrentMode == MODE_HEAT or CurrentMode == MODE_HEATX ) then
		heating = '1'
	end

	for t=1,5 do
		C4:SendToProxy (t, 'MATCH_LED_STATE', {STATE = heating})
	end

	for t=10,14 do
		C4:SendToProxy (t, 'MATCH_LED_STATE', {STATE = cooling})
	end

end

backlightColor = '';

function ApplyBacklight()

	local keypads = Properties["Keypads To Color"]:gmatch( "([^,]+)" )
	local color = RGB2HEX( Properties["Normal Keypad Color"] )

	if ( CurrentMode == MODE_COOLX ) then color = RGB2HEX( Properties["CoolX Keypad Color"] ) end
	if ( CurrentMode == MODE_HEATX ) then color = RGB2HEX( Properties["HeatX Keypad Color"] ) end

	if ( backlightColor == color ) then
		return;
	end

	backlightColor = color;

	for deviceid in keypads do
		C4:SendToDevice( deviceid, "SET_BACKLIGHT_COLOR", { COLOR = color } )
	end

end


function RGB2HEX (rgb)
	local hex = ''
	for color in string.gmatch(rgb, "%d+") do
		hex = hex .. string.format ('%02x', color)
	end
	return hex
end