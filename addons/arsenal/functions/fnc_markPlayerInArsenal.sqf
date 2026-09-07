#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Server-side: adds a client to jna_playersInArsenal - the same bookkeeping
 * jn_fnc_arsenal_requestOpen.sqf does, replicated directly here rather than
 * calling that function, since it ALSO remoteExecCalls "Open" on
 * jn_fnc_arsenal to the client - which opens the real BIS-skinned arsenal
 * display (confirmed via source; an earlier version of this addon called
 * that function directly and, as a field report caught, was silently
 * opening the vanilla arsenal alongside ACE Arsenal every time). Registered
 * against QGVAR(markInArsenal) in XEH_postInit.sqf.
 *
 * Needed at all because Antistasi's own Tab/Y keybind guard
 * (core/keybinds/fn_keyActions.sqf) checks this same server list to refuse
 * firing while a player is in the arsenal - it was never populated for this
 * addon's players since this addon opens ACE Arsenal directly, bypassing
 * jn_fnc_arsenal_requestOpen entirely.
 *
 * Arguments:
 * 0: Client owner ID <NUMBER>
 *
 * Return Value:
 * None
 */

if (!isServer) exitWith {};

params [["_clientOwner", -1, [0]]];
if (_clientOwner < 0) exitWith {};

private _players = server getVariable ["jna_playersInArsenal", []];
_players pushBackUnique _clientOwner;
server setVariable ["jna_playersInArsenal", _players, true];
