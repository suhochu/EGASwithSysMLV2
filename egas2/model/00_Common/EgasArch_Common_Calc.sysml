package EgasArch_Common_Calc {
    private import ScalarValues::*;
    calc def isInState {
        doc
        /* Returns true when the given state occurrence is active. */
        in targetState : States::StateAction [0..*];
        return : Boolean = SequenceFunctions::notEmpty(targetState);
    }
} // package EgasArch_Common_Calc
