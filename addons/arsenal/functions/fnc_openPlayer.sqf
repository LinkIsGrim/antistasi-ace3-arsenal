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

private _items = [] call FUNC(poolFlat);

// TODO(perf): this strips and re-adds every virtual item on every open. Fine for
// correctness, but see fnc_poolFlat.sqf's note - once pool reconciliation is live
// (fnc_reconcileCargoChanged), skip this when the pool hasn't changed since the
// box's last open instead of paying the full round-trip every time.
[_box, true, false] call ace_arsenal_fnc_removeVirtualItems;
[_box, _items, false] call ace_arsenal_fnc_addVirtualItems;

GVAR(activeBox) = _box;

[_box, player] call ace_arsenal_fnc_openBox;
