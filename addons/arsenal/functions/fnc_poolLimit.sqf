#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Minimum stock a non-member must leave in the pool for one classname (the
 * "guest limit" floor), mirroring the _minItemsMember helper JNA's own
 * arsenal skin uses - jna_minItemMember (set in overrides/fnc_arsenal_init.sqf,
 * client-safe - it runs on every machine) as the per-tab default, overridden
 * per-classname by A3A_arsenalLimits when present.
 *
 * Safe to call client-side for display purposes (fnc_decorate.sqf); still
 * only the server's own copy is authoritative for actual accept/refuse
 * decisions. Known gap: A3A_arsenalLimits itself is a DECLARE_SERVER_VAR,
 * so a client-side call silently falls back to the per-tab default rather
 * than any per-classname override - fine for display (it's a reasonable
 * approximation), not fine to rely on for enforcement, which is why the
 * server-side callers (fnc_serverReconcile.sqf/fnc_serverTransfer.sqf) are
 * what actually enforces this, using the server's real copy.
 *
 * Arguments:
 * 0: Classname <STRING>
 * 1: Tab index <NUMBER>
 *
 * Return Value:
 * Minimum stock to leave behind <NUMBER>
 *
 * Example:
 * ["arifle_MX_F", JNA_TAB_PRIMARYWEAPON] call FUNC(poolLimit)
 */

params [["_class", "", [""]], ["_tab", -1, [0]]];

if (_tab < 0 || {isNil "jna_minItemMember"} || {_tab >= count jna_minItemMember}) exitWith {0};

private _min = jna_minItemMember select _tab;

if (!isNil "A3A_arsenalLimits") then {
    _min = A3A_arsenalLimits getOrDefault [_class, _min];
};

_min
