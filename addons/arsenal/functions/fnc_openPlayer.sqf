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

private _items = [] call FUNC(poolFlat);

// TODO(perf): this strips and re-adds every virtual item on every open. Fine for
// correctness, but see fnc_poolFlat.sqf's note - skip this when the pool hasn't
// changed since the box's last open instead of paying the full round-trip every time.
[_box, true, false] call ace_arsenal_fnc_removeVirtualItems;
[_box, _items, false] call ace_arsenal_fnc_addVirtualItems;

GVAR(snapUnit) = player;
GVAR(snapPool) = [player, true] call jn_fnc_arsenal_cargoToArray;
GVAR(snapLoadout) = getUnitLoadout player;

[_box, player] call ace_arsenal_fnc_openBox;
