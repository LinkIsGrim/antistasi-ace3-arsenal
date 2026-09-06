#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Detects whether the loaded Antistasi variant is Community Edition, i.e.
 * whether jn_fnc_arsenal_cargoToArray only supports container/vehicle cargo
 * (no _isPlayer mode at all) and the rebel loadout designer
 * (SCRT_fnc_arsenal_loadoutArsenal) doesn't exist.
 *
 * Confirmed against actual release tags, not dev branches - CE 3.11.1's
 * fn_arsenal_cargoToArray.sqf takes `_this` directly as the container
 * (`_container = _this;`, no params call at all), while Ultimate v11.9.12
 * and TEH both declare `params ["_container", ["_isPlayer", false]]`. Every
 * one of CE's own call sites (fn_arsenal_cargoToArsenal.sqf,
 * fn_vehicleArsenal.sqf) pass a bare object, never [object, true] - CE
 * genuinely has no "give me a person's own gear in JNA's array shape" mode,
 * not just a different way of asking for it. See FUNC(playerCargoToArray).
 *
 * SCRT_fnc_arsenal_loadoutArsenal's presence is the detection signal, not
 * cargoToArray's own signature directly - SQF can't inspect a compiled
 * function's parameter list, so this proxies off something that reliably
 * differs the same way (confirmed absent from CE, present on both Ultimate
 * and TEH, same as fnc_isTEH.sqf does for the bullet-pile system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Antistasi Community Edition is loaded <BOOL>
 *
 * Example:
 * [] call FUNC(isCE)
 */

isNil "SCRT_fnc_arsenal_loadoutArsenal"
