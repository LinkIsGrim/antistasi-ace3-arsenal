#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Post-processes an ACE arsenal panel after it's filled, annotating each
 * row with Antistasi's own pool stock/forbidden/limit state - ACE's panels
 * have no native concept of any of this (see fnc_describeItem.sqf), so it's
 * added after the fact rather than at fill time. Hooked to
 * ace_arsenal_leftPanelFilled/rightPanelFilled in XEH_postInit.sqf, gated
 * on GVAR(snapUnit) being set so it only touches sessions we opened.
 *
 * Label is prefixed onto the item name ("[5] Rifle") rather than shown via
 * lbSetTextRight/a suffix - the right-text area wasn't rendering at all on
 * some right-panel tabs, and relying only on lbSetColor for legibility broke
 * down against ACE's row-selection highlight. A prefix is always readable
 * via the normal name text, with color as a secondary (not sole) signal.
 *
 * ARSENAL_IDC_LEFTLIST/RIGHTLIST are plain lbData listboxes; some right-side
 * tabs (cargo/misc) use the newer ARSENAL_IDC_RIGHTLISTNB (lnb) control
 * instead - both get decorated since either could be the active one.
 *
 * Arguments:
 * 0: Arsenal display <DISPLAY>
 *
 * Return Value:
 * None
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};
if (isNull (missionNamespace getVariable [QGVAR(snapUnit), objNull])) exitWith {};

private _fnc_stripPrefix = {
    params ["_name"];
    if ((_name select [0, 1]) != "[") exitWith {_name};
    private _cut = _name find "] ";
    if (_cut < 0) exitWith {_name};
    _name select [_cut + 2]
};

private _fnc_decorateLb = {
    params ["_ctrl"];
    if (isNull _ctrl) exitWith {};

    for "_i" from 0 to (lbSize _ctrl) - 1 do {
        private _class = _ctrl lbData _i;
        if (_class == "") then {continue};

        ([_class] call FUNC(describeItem)) params ["_label", "_color", "_tooltip"];

        private _name = [_ctrl lbText _i] call _fnc_stripPrefix;
        _ctrl lbSetText [_i, format ["[%1] %2", _label, _name]];
        _ctrl lbSetColor [_i, _color];
        _ctrl lbSetTooltip [_i, _tooltip];
    };
};

[_display displayCtrl ARSENAL_IDC_LEFTLIST] call _fnc_decorateLb;
[_display displayCtrl ARSENAL_IDC_RIGHTLIST] call _fnc_decorateLb;

private _ctrlNb = _display displayCtrl ARSENAL_IDC_RIGHTLISTNB;
if (!isNull _ctrlNb) then {
    private _rows = (lnbSize _ctrlNb) select 0;

    for "_i" from 0 to _rows - 1 do {
        private _class = _ctrlNb lnbData [_i, 0];
        if (_class == "") then {continue};

        ([_class] call FUNC(describeItem)) params ["_label", "_color", "_tooltip"];

        private _name = [_ctrlNb lnbText [_i, 1]] call _fnc_stripPrefix;
        _ctrlNb lnbSetText [[_i, 1], format ["[%1] %2", _label, _name]];
        _ctrlNb lnbSetColor [[_i, 1], _color];
        _ctrlNb lnbSetTooltip [[_i, 1], _tooltip];
    };
};
