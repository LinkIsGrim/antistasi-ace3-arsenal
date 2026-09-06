#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * CE-only: builds the same JNA array shape jn_fnc_arsenal_cargoToArray's
 * _isPlayer branch produces on Ultimate/TEH, since CE's own copy of that
 * function has no such branch at all (confirmed against release tags, see
 * fnc_isCE.sqf's header) - only ever enumerates container/vehicle cargo.
 *
 * Mirrors Ultimate/TEH's _isPlayer branch command-for-command (magazinesAmmo,
 * items+assignedItems, backpack, weaponsItems with bis_fnc_baseWeapon on the
 * three weapon slots, uniform/vest/headgear/goggles), built from the same
 * low-level utilities CE does share (jn_fnc_arsenal_itemType,
 * jn_fnc_arsenal_addToArray, A3A_fnc_basicBackpack, all confirmed present
 * and compatible on CE) - not reimplementing JNA's own classification
 * logic, just supplying the "for a person" mode CE's own function never got.
 *
 * Uses assignedItems [_unit, false, false] rather than the bare/legacy
 * assignedItems _unit Ultimate/TEH use internally - the bare form defaults
 * to including the binocular (confirmed via the BIS wiki's alternate-syntax
 * doc: bare form matches [unit, false, true]), which weaponsItems below
 * already accounts for on its own. Built correctly from the start here,
 * rather than needing a separate post-hoc correction the way
 * FUNC(playerCargoToArray) has to apply for Ultimate/TEH's own (already
 * shipped, not ours to edit) implementation - see that file's header.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Array of arrays of [classname, amount], indexed by JNA tab <ARRAY>
 *
 * Example:
 * [player] call FUNC(playerCargoToArrayCE)
 */

params [["_unit", objNull, [objNull]]];

private _array = [];
for "_i" from 0 to (JNA_TAB_COUNT_BASE - 1) do {_array pushBack []};

private _fnc_add = {
    params ["_index", "_item", "_amount"];
    if (_index == -1 || {_item == ""} || {_amount == 0}) exitWith {};
    _array set [_index, [_array select _index, [_item, _amount]] call jn_fnc_arsenal_addToArray];
};

{
    _x params ["_item", "_amount"];
    [_item call jn_fnc_arsenal_itemType, _item, _amount] call _fnc_add;
} forEach (magazinesAmmo _unit);

{
    [_x call jn_fnc_arsenal_itemType, _x, 1] call _fnc_add;
} forEach ((items _unit) + (assignedItems [_unit, false, false]));

private _backpack = backpack _unit;
if (_backpack != "") then {
    [JNA_TAB_BACKPACK, _backpack call A3A_fnc_basicBackpack, 1] call _fnc_add;
};

// weaponsItems returns one array per equipped weapon slot (primary/secondary/
// handgun/binocular), each itself [classname, muzzle, pointer, optic, mag,
// mag2, bipod] with magazine slots as [classname, ammoCount] pairs - not
// flattened, matching Ultimate/TEH's own nested forEach over this exact shape.
{
    {
        if (_x isEqualType []) then {
            if (count _x > 0) then {
                _x params ["_mag", "_ammoCount"];
                [JNA_TAB_CARGOMAGALL, _mag, _ammoCount] call _fnc_add;
            };
        } else {
            if (_x != "") then {
                private _index = _x call jn_fnc_arsenal_itemType;
                private _item = _x;
                if (_index in [JNA_TAB_PRIMARYWEAPON, JNA_TAB_SECONDARYWEAPON, JNA_TAB_HANDGUN]) then {
                    _item = _x call bis_fnc_baseWeapon;
                };
                [_index, _item, 1] call _fnc_add;
            };
        };
    } forEach _x;
} forEach (weaponsItems _unit);

{
    [_x call jn_fnc_arsenal_itemType, _x, 1] call _fnc_add;
} forEach ([uniform _unit, vest _unit, headgear _unit, goggles _unit] select {_x != ""});

_array
