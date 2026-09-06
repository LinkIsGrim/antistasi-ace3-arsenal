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
 * CE-only: defers to GVAR(originalArsenalHandleAction) (the real, unmodified
 * handler, captured in XEH_postInit.sqf before this was ever assigned) when
 * the player is driving. CE's own "Arsenal" click, while driving, opens a
 * vehicle-cargo arsenal instead of the personal one - confirmed via source,
 * that branching isn't in handleAction itself, it's in the arsenalOpened
 * scripted event dispatch the original init registers (which this addon's
 * own wrapped fnc_arsenal_init.sqf already lets run, unmodified). So calling
 * through here for this one case is enough to get CE's own driver-detected
 * vehicle-arsenal skinning back correctly, without vendoring any of that
 * driver-check/skinning logic itself. Ultimate/TEH have no such branch in
 * their own stock handleAction - not deferred there, since there's nothing
 * upstream to defer to.
 *
 * Arguments:
 * Same as any addAction handler
 *
 * Return Value:
 * None
 */

if (!(missionNamespace getVariable ["arsenalInit", false])) exitWith {};

if ([] call FUNC(isCE) && {!isNull objectParent player} && {driver (vehicle player) == player}) exitWith {
    _this call GVAR(originalArsenalHandleAction);
};

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
