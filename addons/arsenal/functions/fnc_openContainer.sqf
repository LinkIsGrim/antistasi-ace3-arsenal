#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Opens ACE Arsenal on a nearby container/vehicle so its cargo can be
 * filled/emptied against the arsenal pool, same virtual-item translation
 * as the player arsenal (see design notes: routing container fill through
 * ace_arsenal_fnc_openBox rather than a bespoke transfer dialog).
 *
 * Arguments:
 * 0: Container to open, defaults to cursorObject/cursorTarget <OBJECT> (default: objNull)
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorObject] call FUNC(openContainer)
 */

params [["_container", objNull, [objNull]]];

if (!hasInterface) exitWith {};

if (isNull _container) then {_container = cursorObject};
if (isNull _container) then {_container = cursorTarget};

if (isNull _container) exitWith {
    ["Look at a vehicle or container first."] call BIS_fnc_error;
};

if (player distance _container > 50) exitWith {
    ["That's too far away."] call BIS_fnc_error;
};

private _cfg = configOf _container;
private _canHold = (getNumber (_cfg >> "transportMaxBackpacks") > 0)
    || {getNumber (_cfg >> "transportMaxMagazines") > 0}
    || {getNumber (_cfg >> "transportMaxWeapons") > 0};

if (!_canHold) exitWith {
    ["That can't hold equipment."] call BIS_fnc_error;
};

private _items = [] call FUNC(poolFlat);

// See fnc_openPlayer.sqf's TODO(perf) - same full-resync-on-open tradeoff applies here.
[_container, true, false] call ace_arsenal_fnc_removeVirtualItems;
[_container, _items, false] call ace_arsenal_fnc_addVirtualItems;

GVAR(activeBox) = _container;

[_container, player] call ace_arsenal_fnc_openBox;
