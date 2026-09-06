package EgasDiagrams {
    private import StandardViewDefinitions::*;
    private import SysideViews::*;

    view egas_system_context : InterconnectionView {
        expose EgasSystemContext::EgasContext::*::**;
        // filter not (@ Domain) or @ ElectricalDomain;

        attribute fileName = "01_egas_system_context";
    }
} // package EgasDiagrams
