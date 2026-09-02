#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Opens the arsenal <-> container transfer dialog on a nearby container or
 * vehicle. Not routed through ace_arsenal_fnc_openBox - confirmed twice over
 * (design-outline.md section 5) that ACE arsenal's per-person data model
 * can't represent a container's stackable cargo.
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

GVAR(transferContainer) = _container;

createDialog QGVAR(TransferDialog);
