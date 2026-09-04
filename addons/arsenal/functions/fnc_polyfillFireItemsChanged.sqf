#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Diffs two classname -> count HashMaps (as returned by
 * FUNC(polyfillGetLoadoutItemCounts)) and fires the literal
 * "ace_arsenal_itemsChanged" event with what actually changed, if anything
 * did - the same event name/shape ace_arsenal itself will eventually fire
 * natively (acemod/ace3 branch arsenal-selection-event), so
 * fnc_onItemsChanged.sqf doesn't care whether this polyfill or a real ACE
 * build is what's actually firing it.
 *
 * Arguments:
 * 0: Arsenal display <DISPLAY>
 * 1: Item counts before the change, classname -> count <HASHMAP>
 * 2: Item counts after the change, classname -> count <HASHMAP>
 *
 * Return Value:
 * None
 */

params [
    ["_display", displayNull, [displayNull]],
    ["_oldCounts", createHashMap, [createHashMap]],
    ["_newCounts", createHashMap, [createHashMap]]
];

private _added = +_newCounts;
{
    private _remaining = (_added getOrDefault [_x, 0]) - _y;
    if (_remaining > 0) then {_added set [_x, _remaining]} else {_added deleteAt _x};
} forEach _oldCounts;

private _removed = +_oldCounts;
{
    private _remaining = (_removed getOrDefault [_x, 0]) - _y;
    if (_remaining > 0) then {_removed set [_x, _remaining]} else {_removed deleteAt _x};
} forEach _newCounts;

if (count _added == 0 && {count _removed == 0}) exitWith {};

// [_display, _panel, _newItem (gained), _oldItem (lost)] - panel is always -1
// here (not panel-specific), since this addon's own FUNC(onItemsChanged)
// never actually reads it either way.
["ace_arsenal_itemsChanged", [_display, -1, _added, _removed]] call CBA_fnc_localEvent;
