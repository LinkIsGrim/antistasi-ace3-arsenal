#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Replaces JN_fnc_arsenal_handleAction (assigned in XEH_postInit.sqf) - the
 * click handler for the "Arsenal" action added in overrides/fnc_arsenal_init.sqf.
 *
 * Branches to the rebel-loadout-designer path (FUNC(openLoadout)) when
 * called from the commander menu with a role selected - confirmed present
 * under identical naming (currentRebelLoadout, SCRT_fnc_ui_*) on both
 * Ultimate and TEH, confirmed absent entirely on CE (no scrt addon at all).
 * The isNil guards mean this whole branch is simply dead code on CE, not a
 * naming mismatch to work around.
 *
 * Arguments:
 * Same as any addAction handler
 *
 * Return Value:
 * None
 */

if (!(missionNamespace getVariable ["arsenalInit", false])) exitWith {};

private _fromCommanderMenu = (missionNamespace getVariable ["isMenuOpen", false])
    && {!isNil "SCRT_fnc_ui_toggleCommanderMenu"};

if (_fromCommanderMenu) then {
    [] call SCRT_fnc_ui_toggleCommanderMenu;

    {
        private _display = findDisplay _x;
        if (!isNull _display) then {_display closeDisplay 1};
    } forEach [60000, 120000];

    if (!isNil "SCRT_fnc_ui_toggleMenuBlur") then {
        ["off"] call SCRT_fnc_ui_toggleMenuBlur;
    };

    call FUNC(openLoadout);
} else {
    call FUNC(openPlayer);
};
