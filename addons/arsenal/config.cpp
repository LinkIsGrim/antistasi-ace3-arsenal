#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "skuaa3aa_main",
            "ace_arsenal",
            "A3A_jeroen_arsenal" // CE, Ultimate and TEH all patch the JNA component under this same name
        };
        author = "LinkIsGrim";
        skipWhenMissingDependencies = 1;
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

// Redirects ACE's native alphabetical sort to our own statement instead of
// adding a separate duplicate entry - its statement is empty (returns nil,
// ACE_Arsenal_Sorts.hpp: statement = QUOTE({})), a sentinel meaning "sort
// the control's own rendered row text", which breaks once fnc_decorate.sqf
// prefixes that text with a stock label.
//
// MUST restate ": sortBase" explicitly even though the class already exists
// with that exact parent - confirmed from the RPT ("Updating base class
// 'sortBase'->''") that omitting it doesn't merge into the existing class
// the way same-PBO config re-opens normally do; across PBOs it severed the
// inheritance link entirely instead. ACE_alphabetically doesn't declare its
// own "condition" (relies on inheriting sortBase's condition = QUOTE(true)),
// so losing that inheritance left it an uncompiled string, which threw a
// type error in fnc_fillSort.sqf and emptied the entire sort dropdown for
// every tab - not just this one entry - and cascaded into the arsenal's own
// camera cleanup (fnc_onArsenalClose.sqf) failing too.
class ace_arsenal_sorts {
    class sortBase; // external forward declaration - lives in ace_arsenal's own config.bin
    class ACE_alphabetically: sortBase {
        statement = QUOTE(call FUNC(sortStatementAlphabetical));
    };
};

// dialogues\defines.hpp already pulled in via script_component.hpp

class RscListNBox;
class RscText;
class RscEdit;
class RscButton;

#include "dialogues\transferDialog.hpp"
