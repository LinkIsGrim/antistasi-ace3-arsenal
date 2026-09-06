#include "script_component.hpp"
/*
 * Author: LinkIsGrim
 * Wraps (not replaces) JN_fnc_arsenal_init - calls through to Antistasi's
 * own, completely unmodified implementation (captured in
 * GVAR(originalArsenalInit) before this was ever assigned, in
 * XEH_postInit.sqf). Antistasi (CE/Ultimate/TEH) calls this from both
 * fn_initServer.sqf and fn_initClient.sqf with the arsenal box object.
 *
 * TEH's own stock init (inside the call-through above) already adds its
 * "Quick resupply"/"Equip last loadout"/"Mag Service" actions itself - this
 * file used to add a second copy of each (wrapped in a jna_dataList sync
 * first) on top, which meant every one of the three showed up twice once
 * this file started calling through to the real init instead of replacing
 * it. Fixed by wrapping the three underlying JN_fnc_arsenal_quickReload/
 * JN_fnc_arsenal_loadInventory/A3A_fnc_MagConvert_open globals directly in
 * XEH_postInit.sqf instead - see that file for why. Nothing left to add
 * here.
 *
 * Deliberately NOT vendoring/reimplementing anything about the "Arsenal"
 * action, "Open Container"/driver-detected vehicle arsenal, or JNA's own
 * arsenalOpened/arsenalClosed dispatch, the way an earlier version of this
 * file did. All of that just keeps working, automatically, exactly as
 * whichever variant's own stock code already does it - because
 * JN_fnc_arsenal_handleAction is reassigned to this addon's own override
 * before the original init below ever runs. SQF evaluates an addAction's
 * script argument eagerly, at the moment addAction itself is called, not
 * as a live reference to the global variable's name - so stock's own
 * `_object addAction ["Arsenal", JN_fnc_arsenal_handleAction, ...]` call
 * captures whatever JN_fnc_arsenal_handleAction already points to at that
 * instant. Since this addon's override is already in place by then,
 * "Arsenal" ends up calling it regardless of which variant's own init code
 * added the action - zero need to track upstream's action-adding code at
 * all, on any variant, ever. Confirmed from SQF's own eager-evaluation
 * semantics (the same reasoning fnc_installItemsChangedPolyfill.sqf's
 * capture-then-reassign wrapping already relies on elsewhere in this
 * addon), not a guess.
 *
 * "Open Container"/vehicle-arsenal access - whatever form each variant's
 * own stock code gives it (an addActionSelect on Ultimate/TEH, automatic
 * driver detection on CE, neither on CE for a plain nearby container since
 * it never had one) - keeps working exactly as upstream designed, through
 * JNA's own vanilla BIS-skinned display. Untouched by this addon: ACE
 * Arsenal's per-person data model still can't represent a container's
 * stackable cargo (design-outline.md section 5), so there's nothing for
 * this addon to redirect that action to even if it wanted to.
 *
 * Arguments:
 * 0: Arsenal box object <OBJECT>
 *
 * Return Value:
 * None
 */

// Matches the original's own idempotent guard - without this, a second call
// (this file's own author, Antistasi, calls JN_fnc_arsenal_init from BOTH
// fn_initServer.sqf and fn_initClient.sqf) would exit early inside the
// wrapped original below, but that's now the only thing left in this file,
// so there is nothing left for the second call to do either way. Kept for
// clarity and in case that changes again.
if (!isNull (missionNamespace getVariable ["jna_object", objNull])) exitWith {};

_this call GVAR(originalArsenalInit);
