#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Opens the player's ACE Arsenal on Antistasi's arsenal box, syncing the
 * box's virtual items from the current jna_dataList pool first.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call FUNC(openPlayer)
 */

if (!hasInterface) exitWith {};

private _box = missionNamespace getVariable ["jna_object", objNull];
if (isNull _box) exitWith {
    ["Arsenal is not initialised yet."] call BIS_fnc_error;
};

if (!alive player) exitWith {};

// No-ops internally if TFAR isn't loaded (A3A_hasTFAR check lives in jn_fnc_arsenal
// itself) - reused as-is rather than reimplemented, identical across CE/Ultimate/TEH.
["SaveTFAR"] call jn_fnc_arsenal;

GVAR(snapUnit) = player;
GVAR(snapLoadout) = player call CBA_fnc_getLoadout;

// Fresh per session - FUNC(onItemsChanged)/FUNC(flushReconcile) accumulate and
// send off these, not a loadout snapshot diff (see fnc_flushReconcile.sqf's
// header), so there's no equivalent "seed the baseline" step needed here.
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
