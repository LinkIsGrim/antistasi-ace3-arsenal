#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: registered against ace_arsenal_itemsChanged in XEH_postInit.sqf.
 * Normalizes and tabs each changed classname, accumulates it into
 * GVAR(pendingTaken)/GVAR(pendingReturned) (tab -> classname -> amount), and
 * asks FUNC(flushReconcile) to send whatever's pending.
 *
 * Replaces the old FUNC(reconcile)'s approach of diffing two full loadout
 * snapshots to infer what changed - ace_arsenal_itemsChanged already reports
 * exactly that, sourced from ACE's own selection-change/cargo-button code
 * rather than re-derived from before/after state. That sidesteps the whole
 * class of bugs the diff-based approach hit: float precision in the stock
 * sort was unrelated, but the fast-swap "duplication" exploit and the
 * strip-mode-derailing phantom classname both came from re-deriving deltas
 * from a snapshot instead of being told them directly.
 *
 * Doesn't care whether ace_arsenal_itemsChanged is firing natively (ACE
 * branch arsenal-selection-event, not in any released build as of this
 * writing) or via FUNC(installItemsChangedPolyfill)'s wrappers around ACE's
 * real functions - same event name and payload shape either way, this file
 * just consumes it.
 *
 * Arguments:
 * 0: Arsenal display <DISPLAY> (unused)
 * 1: Panel IDC the change originated from <NUMBER> (unused)
 * 2: Items gained, classname -> count <HASHMAP>
 * 3: Items lost, classname -> count <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ace_arsenal_itemsChanged", {_this call FUNC(onItemsChanged)}] call CBA_fnc_addEventHandler
 */

params [["_display", displayNull, [displayNull]], ["_panel", -1, [0]], ["_newItem", createHashMap, [createHashMap]], ["_oldItem", createHashMap, [createHashMap]]];

if (missionNamespace getVariable [QGVAR(snapUnit), objNull] isEqualTo objNull) exitWith {};

private _fnc_accumulate = {
    params ["_items", "_bucket"];

    {
        private _class = _x call FUNC(baseClass);
        if (_class == "") then {continue};

        private _tab = _class call jn_fnc_arsenal_itemType;
        if (_tab == JNA_TAB_CARGOMAG) then {_tab = JNA_TAB_CARGOMAGALL};
        if (_tab < 0) then {continue};

        private _tabMap = _bucket getOrDefaultCall [_tab, {createHashMap}, true];
        _tabMap set [_class, (_tabMap getOrDefault [_class, 0]) + _y];
    } forEach _items;
};

[_newItem, GVAR(pendingTaken)] call _fnc_accumulate;
[_oldItem, GVAR(pendingReturned)] call _fnc_accumulate;

call FUNC(flushReconcile);
