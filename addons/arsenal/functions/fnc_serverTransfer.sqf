#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: authoritative transfer of one classname between the arsenal
 * pool and a real container's physical cargo. Registered against
 * QGVAR(transferRequest) in XEH_postInit.sqf.
 *
 * Known simplification: doesn't check the container's own maxLoad here -
 * Arma's cargo-add commands don't enforce capacity for scripted adds (only
 * the gear-drag UI does), so this is a v1 gap, not a v1 feature - overfilling
 * a crate isn't a resource-economy problem the way unchecked arsenal
 * withdrawal is, so it's lower priority than the stock/forbidden/member
 * checks below, but still a real gap to close later.
 *
 * Arguments:
 * 0: Requesting unit <OBJECT>
 * 1: Target container <OBJECT>
 * 2: Classname <STRING>
 * 3: Amount <NUMBER>
 * 4: "toContainer" or "toPool" <STRING>
 *
 * Return Value:
 * None
 */

if (!isServer) exitWith {};

params [
    ["_unit", objNull, [objNull]],
    ["_container", objNull, [objNull]],
    ["_class", "", [""]],
    ["_amount", 0, [0]],
    ["_direction", "", [""]]
];

private _fnc_report = {
    params ["_msg"];
    [QGVAR(transferResult), [_msg], _unit] call CBA_fnc_targetEvent;
};

if (isNull _unit || {isNull _container} || {_class == ""} || {_amount <= 0}) exitWith {};

_class = _class call FUNC(baseClass);

private _tab = _class call jn_fnc_arsenal_itemType;
if (_tab == JNA_TAB_CARGOMAG) then {_tab = JNA_TAB_CARGOMAGALL};
if (_tab < 0) exitWith {["Can't identify that item."] call _fnc_report};

private _isMag = _tab == JNA_TAB_CARGOMAGALL;
private _isWeapon = _tab in [JNA_TAB_PRIMARYWEAPON, JNA_TAB_SECONDARYWEAPON, JNA_TAB_HANDGUN, JNA_TAB_BINOCULARS];
private _isBackpack = _tab == JNA_TAB_BACKPACK;
private _isThrowPut = _tab in [JNA_TAB_CARGOTHROW, JNA_TAB_CARGOPUT];

private _fnc_addToContainer = {
    params ["_amount"];
    switch (true) do {
        case _isBackpack: {_container addBackpackCargoGlobal [_class, _amount]};
        case _isWeapon: {_container addWeaponCargoGlobal [_class, _amount]};
        case (_isMag || _isThrowPut): {_container addMagazineCargoGlobal [_class, _amount]};
        default {_container addItemCargoGlobal [_class, _amount]};
    };
};

if (_direction == "toContainer") exitWith {
    if (_class call FUNC(isForbidden)) exitWith {
        [format ["%1 is off-limits.", getText (configFile >> "CfgWeapons" >> _class >> "displayName")]] call _fnc_report;
    };

    (_class call FUNC(poolFind)) params ["_foundTab", "_stock", "_foundClass"];
    if (_foundTab < 0) exitWith {["Not enough in the arsenal."] call _fnc_report};

    if (_stock != -1) then {
        if (_stock < _amount) exitWith {["Not enough in the arsenal."] call _fnc_report};

        if (!(_unit call A3A_fnc_isMember) && {_stock - _amount < ([_foundClass, _foundTab] call FUNC(poolLimit))}) exitWith {
            ["Only members can take that much."] call _fnc_report;
        };
    };

    [_amount] call _fnc_addToContainer;
    [_foundTab, _foundClass, _amount] call jn_fnc_arsenal_removeItem;

    [QGVAR(poolChanged), []] call CBA_fnc_globalEvent;
    [_unit] call FUNC(serverSyncDataList);
    ["Moved into the container."] call _fnc_report;
};

if (_direction == "toPool") exitWith {
    private _cargo = _container call jn_fnc_arsenal_cargoToArray;
    private _have = 0;
    if (_tab < count _cargo) then {
        private _entry = (_cargo select _tab) findIf {(_x select 0) == _class};
        if (_entry >= 0) then {_have = _cargo select _tab select _entry select 1};
    };

    if (_have < _amount) exitWith {["Not enough in the container."] call _fnc_report};

    [-_amount] call _fnc_addToContainer;
    [_tab, _class, _amount] call jn_fnc_arsenal_addItem;

    [QGVAR(poolChanged), []] call CBA_fnc_globalEvent;
    [_unit] call FUNC(serverSyncDataList);
    ["Moved into the arsenal."] call _fnc_report;
};
