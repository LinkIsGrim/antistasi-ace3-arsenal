#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Removes every instance of the given magazine classnames from a unit
 * (loaded or in cargo) - the soft-fail correction fnc_reconcile.sqf applies
 * when a magazine specifically was refused, instead of reverting the whole
 * loadout over one over-drawn magazine type.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Magazine classnames to strip <ARRAY of STRINGS>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, ["30Rnd_65x39_caseless_mag"]] call FUNC(stripMagazines)
 */

params [["_unit", objNull, [objNull]], ["_classes", [], [[]]]];

if (isNull _unit || {_classes isEqualTo []}) exitWith {};

{
    private _class = _x;
    while {_class in magazines _unit} do {
        _unit removeMagazine _class;
    };
} forEach _classes;
