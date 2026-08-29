package EGASDiagrams {
    private import StandardViewDefinitions::*;
    private import SysideViews::*;
    private import EgasBaseArchitecture::*;

    view egas_system_context : InterconnectionView {
        expose EgasBaseArchitecture::EGAS_Context::*::**;
        // filter not (@ Domain) or @ ElectricalDomain;

        attribute fileName = "01_egas_system_context";
    }
} // package EGASDiagrams
