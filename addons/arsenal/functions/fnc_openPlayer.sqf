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
GVAR(snapPool) = [player, true] call jn_fnc_arsenal_cargoToArray;
GVAR(snapLoadout) = player call CBA_fnc_getLoadout;

// Fresh per session - fnc_reconcile.sqf populates these from its snapshot diff
// and calls FUNC(flushReconcile) to send whatever's pending.
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
