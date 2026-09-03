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
// prefixes that text with a stock label. Re-opening the class (no explicit
// : ACE_alphabetically parent needed - same name in the same scope merges
// into the existing class rather than redefining it) keeps its scope/
// displayName/tabs, only the statement changes.
class ace_arsenal_sorts {
    class ACE_alphabetically {
        statement = QUOTE(call FUNC(sortStatementAlphabetical));
    };
};

// dialogues\defines.hpp already pulled in via script_component.hpp

class RscListNBox;
class RscText;
class RscEdit;
class RscButton;

#include "dialogues\transferDialog.hpp"
