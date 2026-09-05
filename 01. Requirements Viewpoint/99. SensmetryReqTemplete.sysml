package SensmetryRequirementTemplates {
    private import ScalarValues::*;
    doc
    /* Sensmetry Requirement Templates (공식 제약 조건 템플릿) */

    requirement def OverrideRequirement {
        doc
        /* When both {primaryInputActive} and {overrideInputActive} are true, the {outputValue} must be limited to {safeLimit}. */
        attribute primaryInputActive : Boolean;
        attribute overrideInputActive : Boolean;
        attribute outputValue : Real;
        attribute safeLimit : Real;

        assume constraint {
            safeLimit >= 0.0
        }
        require constraint {
            (primaryInputActive and overrideInputActive) implies outputValue <= safeLimit
        }
    }

    requirement def RedundancyDeviationRequirement {
        doc
        /* If the absolute difference between {channel1} and {channel2} exceeds {maxDeviation}, {faultFlag} must be asserted true. */
        attribute channel1 : Real;
        attribute channel2 : Real;
        attribute maxDeviation : Real;
        attribute faultFlag : Boolean;

        assume constraint {
            maxDeviation > 0.0
        }
        require constraint {
            (channel1 - channel2 > maxDeviation or channel2 - channel1 > maxDeviation) implies
            faultFlag == true
        }
    }

    requirement def PerformanceTimingRequirement {
        doc
        /* The {process} shall complete within {maxResponseTime}. */
        attribute executionTime : Real;
        attribute maxResponseTime : Real;

        assume constraint {
            maxResponseTime > 0.0
        }
        require constraint {
            executionTime <= maxResponseTime
        }
    }
} // package SensmetryRequirementTemplates
