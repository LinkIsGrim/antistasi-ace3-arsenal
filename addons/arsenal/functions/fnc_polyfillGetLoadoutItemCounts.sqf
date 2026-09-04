#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Flattens ACE_arsenal's own display unit's current loadout into a
 * classname -> count HashMap - every weapon, attachment, magazine, worn
 * container's contents, and assigned/linked item. Used by
 * FUNC(installItemsChangedPolyfill)'s wrappers to diff ACE's arsenal state
 * before and after calling through to ACE's real, unmodified function.
 *
 * Same logic as the equivalent function written directly into ACE arsenal
 * for acemod/ace3 branch arsenal-selection-event - kept here too as a
 * polyfill since that isn't in any released ACE build yet and ACE releases
 * are infrequent. Reads ace_arsenal_center directly (ACE's own internal
 * global) rather than anything from this addon - this file has no
 * dependency on jna_dataList, this addon's own pool, or anything else
 * Antistasi-specific.
 *
 * Deliberately does not include cosmetic-only slots (face, voice, insignia) -
 * they aren't part of getUnitLoadout's return and don't pull from the
 * virtual item pool the way everything else here does.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Classname -> count <HASHMAP>
 *
 * Example:
 * call FUNC(polyfillGetLoadoutItemCounts)
 */

private _unit = missionNamespace getVariable ["ace_arsenal_center", objNull];
if (isNull _unit) exitWith {createHashMap};

private _counts = createHashMap;

private _fnc_add = {
    params [["_class", "", [""]], ["_amount", 1, [0]]];
    if (_class == "" || {_amount == 0}) exitWith {};
    _counts set [_class, (_counts getOrDefault [_class, 0]) + _amount];
};

// Weapon-format slot: [type, muzzle, pointer, optic, [primary mag, ammo],
// [secondary mag, ammo], bipod] - shared by primary/secondary/handgun/binocular.
private _fnc_addWeaponSlot = {
    params [["_slot", [], [[]]]];
    _slot params [
        ["_weapon", "", [""]], ["_muzzle", "", [""]], ["_pointer", "", [""]],
        ["_optic", "", [""]], ["_primaryMag", [], [[]]], ["_secondaryMag", [], [[]]],
        ["_bipod", "", [""]]
    ];
    [_weapon] call _fnc_add;
    [_muzzle] call _fnc_add;
    [_pointer] call _fnc_add;
    [_optic] call _fnc_add;
    [_primaryMag param [0, ""]] call _fnc_add;
    [_secondaryMag param [0, ""]] call _fnc_add;
    [_bipod] call _fnc_add;
};

// Uniform/vest/backpack slots: [type, [[item, count], [item, count], ...]]
private _fnc_addContainerSlot = {
    params [["_slot", [], [[]]]];
    _slot params [["_container", "", [""]], ["_items", [], [[]]]];
    [_container] call _fnc_add;
    {
        _x params [["_itemClass", "", [""]], ["_itemAmount", 1, [0]]];
        [_itemClass, _itemAmount] call _fnc_add;
    } forEach _items;
};

// getUnitLoadout's return is a fixed, engine-documented array shape - indices
// below match it directly (ACE's own IDX_LOADOUT_* macros for these aren't
// something this addon has access to, being private to ace_arsenal's PBO).
private _loadout = getUnitLoadout _unit;

[_loadout select 0] call _fnc_addWeaponSlot;  // primary weapon
[_loadout select 1] call _fnc_addWeaponSlot;  // secondary weapon
[_loadout select 2] call _fnc_addWeaponSlot;  // handgun
[_loadout select 8] call _fnc_addWeaponSlot;  // binocular (same weapon-format shape)
[_loadout select 3] call _fnc_addContainerSlot; // uniform
[_loadout select 4] call _fnc_addContainerSlot; // vest
[_loadout select 5] call _fnc_addContainerSlot; // backpack
[_loadout select 6] call _fnc_add; // headgear
[_loadout select 7] call _fnc_add; // goggles

{
    [_x] call _fnc_add;
} forEach (_loadout select 9); // assigned/linked items (NVG, map, compass, watch, radio, GPS)

_counts
