#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Strips fnc_decorate.sqf's "[label] " prefix from a row's text if present,
 * returning the underlying item name. Shared between fnc_decorate.sqf
 * (re-decorating without doubling up the prefix) and the
 * ace_arsenal_fnc_sortPanel wrapper (XEH_postInit.sqf - stripping before
 * the native sort runs, since it and ACE's own tie-break both read the
 * row's literal rendered text).
 *
 * Arguments:
 * 0: Row text, possibly prefixed <STRING>
 *
 * Return Value:
 * Unprefixed name <STRING>
 *
 * Example:
 * ["[5] Rifle"] call FUNC(cleanName)
 */

params [["_text", "", [""]]];

if ((_text select [0, 1]) != "[") exitWith {_text};

private _cut = _text find "] ";
if (_cut < 0) exitWith {_text};

_text select [_cut + 2]
