#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Opens ACE Arsenal against a rebel role loadout template selected from the
 * commander menu (Ultimate/TEH only - `currentRebelLoadout`/the rebel
 * loadout designer don't exist on CE, see design-outline.md). Temporarily
 * equips the selected role's template so the arsenal reflects what a
 * recruit of that role would actually have, then restores the caller's own
 * gear when the arsenal closes (see XEH_postInit.sqf's displayClosed hook).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call FUNC(openLoadout)
 */

if (!hasInterface) exitWith {};
if (!(missionNamespace getVariable ["arsenalInit", false])) exitWith {};

private _box = missionNamespace getVariable ["jna_object", objNull];
if (isNull _box) exitWith {
    currentRebelLoadout = nil;
    ["Arsenal is not initialised yet."] call BIS_fnc_error;
};

if (isNil "currentRebelLoadout") exitWith {
    ["No rebel role selected."] call BIS_fnc_error;
};

["SaveTFAR"] call jn_fnc_arsenal;

GVAR(loadoutBackup) = getUnitLoadout player;

if (backpack player != "") then {removeBackpack player};

private _loadout = (missionNamespace getVariable ["rebelLoadouts", createHashMap]) get currentRebelLoadout;

player setUnitLoadout (configFile >> "EmptyLoadout");
[player, 0, currentRebelLoadout] call A3A_fnc_equipRebel;
if (!isNil "_loadout") then {
    player setUnitLoadout +_loadout;
};

GVAR(snapUnit) = player;
GVAR(snapLoadout) = player call CBA_fnc_getLoadout;
GVAR(loadoutMode) = true;

GVAR(pendingTaken) = createHashMap;
GVAR(pendingReturned) = createHashMap;
GVAR(busy) = false;
GVAR(stripDepth) = 0;

[{
    private _box = missionNamespace getVariable ["jna_object", objNull];
    if (isNull _box) exitWith {};
    [_box] call FUNC(syncPool);
    [_box, player] call ace_arsenal_fnc_openBox;
}] call FUNC(requestDataListSync);
