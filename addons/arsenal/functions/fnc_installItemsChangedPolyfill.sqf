#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side, called once from XEH_postInit.sqf: wraps ACE arsenal's own
 * ace_arsenal_fnc_onSelChangedLeft/onSelChangedRight/buttonCargo/
 * buttonClearAll/buttonLoadoutsLoad/buttonImport - every place items can
 * move in or out of the arsenal - to fire "ace_arsenal_itemsChanged", an
 * event not in any released ACE build yet (acemod/ace3 branch
 * arsenal-selection-event) but ACE releases are infrequent enough not to
 * wait on. See fnc_onItemsChanged.sqf for the consumer, which doesn't care
 * whether this polyfill or a real ACE build is what fires the event.
 *
 * Deliberately a wrap, not a copy: each wrapper captures a reference to
 * ACE's real, currently-compiled function and calls straight through to it,
 * unmodified, passing back whatever it returns - it only observes loadout
 * state before and after via FUNC(polyfillGetLoadoutItemCounts). Nothing
 * here reimplements or freezes any of ACE's own selection-change/cargo-
 * button logic, so there's nothing here that can drift out of sync with
 * however that logic changes - only the six function names being wrapped
 * and the getUnitLoadout array indices in FUNC(polyfillGetLoadoutItemCounts)
 * are things that could ever need updating.
 *
 * Not guarded against a real ace_arsenal_itemsChanged already existing in
 * the installed ACE build - an accepted, explicit tradeoff (a doubled-up
 * delta if that ever overlaps), not an oversight.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call FUNC(installItemsChangedPolyfill)
 */

private _fnc_wrap = {
    params ["_globalName", "_fnc_getDisplay"];

    private _original = missionNamespace getVariable _globalName;
    if (isNil "_original") exitWith {
        diag_log text format ["[skuaa3aa_arsenal] Can't polyfill itemsChanged: %1 not found.", _globalName];
    };

    missionNamespace setVariable [_globalName, {
        private _display = call _fnc_getDisplay;
        private _oldCounts = call FUNC(polyfillGetLoadoutItemCounts);

        private _result = _this call _original;

        private _newCounts = call FUNC(polyfillGetLoadoutItemCounts);
        [_display, _oldCounts, _newCounts] call FUNC(polyfillFireItemsChanged);

        _result
    }];
};

// onSelChangedLeft/onSelChangedRight take the control, not the display.
private _fnc_displayFromControl = {ctrlParent (_this select 0)};
// buttonCargo/buttonClearAll/buttonLoadoutsLoad/buttonImport all take the
// display directly as their first argument.
private _fnc_displayFromFirstArg = {_this select 0};

["ace_arsenal_fnc_onSelChangedLeft", _fnc_displayFromControl] call _fnc_wrap;
["ace_arsenal_fnc_onSelChangedRight", _fnc_displayFromControl] call _fnc_wrap;
["ace_arsenal_fnc_buttonCargo", _fnc_displayFromFirstArg] call _fnc_wrap;
["ace_arsenal_fnc_buttonClearAll", _fnc_displayFromFirstArg] call _fnc_wrap;
["ace_arsenal_fnc_buttonLoadoutsLoad", _fnc_displayFromFirstArg] call _fnc_wrap;
["ace_arsenal_fnc_buttonImport", _fnc_displayFromFirstArg] call _fnc_wrap;
