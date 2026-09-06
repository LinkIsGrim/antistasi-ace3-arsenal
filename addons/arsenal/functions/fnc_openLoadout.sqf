#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Opens ACE Arsenal against a rebel role loadout template selected from the
 * commander menu (Ultimate/TEH only - `currentRebelLoadout`/the native
 * rebel loadout designer (SCRT_fnc_arsenal_loadoutArsenal) don't exist on
 * CE, which edits rebel loadouts through its own non-arsenal dialog
 * instead - see design-outline.md). Temporarily equips the selected role's
 * template so the arsenal reflects what a recruit of that role would
 * actually have, then saves whatever's actually equipped when the arsenal
 * closes as the new fixed loadout for that role, and restores the caller's
 * own gear (see XEH_postInit.sqf's displayClosed hook).
 *
 * Deliberately simpler than SCRT's own designer, which supports leaving
 * individual slots (down to per-weapon-attachment granularity) random
 * instead of fixed via a per-tab toggle (fn_arsenal_loadoutArsenal.sqf's
 * "OverrideTab"/"OverrideIDCs", saved as a nil in that slot for
 * A3A_fnc_equipRebel to randomize from faction defaults) - whatever's
 * equipped when this closes becomes the new loadout in full, every slot
 * fixed. No equivalent to that per-slot randomization in this addon's
 * flow.
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
GVAR(snapPool) = [player] call FUNC(playerCargoToArray);
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
