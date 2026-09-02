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
