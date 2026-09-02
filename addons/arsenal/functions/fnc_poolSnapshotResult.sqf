#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Client-side: stores a server-sourced pool snapshot and refreshes the
 * transfer dialog if it's currently open.
 *
 * Arguments:
 * 0: Snapshot, [[tab, class, count], ...] <ARRAY>
 *
 * Return Value:
 * None
 */

params [["_snapshot", [], [[]]]];

GVAR(transferPool) = _snapshot;

if (!isNull (findDisplay IDD_TRANSFER)) then {
    ["fill"] call FUNC(transferDialog);
};
