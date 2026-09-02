#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Checks Antistasi's own admin-forbidden-items list. A3U_forbiddenItems is
 * Ultimate/TEH's own global (populated by A3U_fnc_grabForbiddenItems from
 * the A3U>>forbiddenItems config branch) - not something antistasi-ace-arsenal
 * invented, we're just reading the same list. Absent entirely on CE (no
 * "ultimate" addon component there), hence the isNil guard.
 *
 * Arguments:
 * 0: Classname <STRING>
 *
 * Return Value:
 * Forbidden and not marked unlimited <BOOL>
 *
 * Example:
 * ["arifle_MX_F"] call FUNC(isForbidden)
 */

params [["_class", "", [""]]];

if (_class == "" || {isNil "A3U_forbiddenItems"}) exitWith {false};

if !(_class in A3U_forbiddenItems) exitWith {false};

getNumber (configFile >> "A3U" >> "forbiddenItems" >> _class >> "unlimited") == 0
