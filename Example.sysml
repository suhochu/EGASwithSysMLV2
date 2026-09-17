package TableViewExample {
    requirement def ExampleRequirements {
        requirement requirement1 : MyRequirements::Requirement1;
        requirement requirement2 : MyRequirements::Requirement2;
    }
} // package TableViewExample
package FlatTableViewExample {
    private import SysideViews::*;
    private import TableViewExample::*;

    view myRequirementsTable : SV::TVD::TableView {
        expose ExampleRequirements::*;
        filter hastype SysML::RequirementDefinition;

        attribute :>> exposeFeaturesAndHeritage = true;
        attribute :>> maxRowHeight = 300;

        view ID :> columnViews {
            attribute :>> featureToRender = CT::declaredShortName;
            attribute :>> defaultValue = "missing_id";
            attribute :>> columnWidth = 100;
        }
        view 'Summary Name' :> columnViews {
            attribute :>> featureToRender = CT::declaredName;
            attribute :>> columnWidth = 220;
        }
        view Description :> columnViews {
            attribute :>> featureToRender = CT::attributeValue {
                attribute attributeName = "description";
            }
            attribute :>> defaultValue = "n/a";
            attribute :>> columnWidth = 304;
        }
        view Documentation :> columnViews {
            attribute :>> featureToRender = CT::specificDocumentation {
                attribute documentationName = "";
            }
            attribute :>> defaultValue = "n/a";
            attribute :>> columnWidth = 231;
        }
    }
} // package FlatTableViewExample
package MyRequirements {
    requirement def <'REQ-01'> Requirement1 {
        doc
        /* Documentation for the first requirement */
        attribute description = "Description of the first requirement";

        requirement subrequirement1 : Requirement3;
    }
    requirement def <'REQ-02'> Requirement2 {
        doc
        /* Documentation for the second requirement */
        attribute description = "Description of the second requirement";

        requirement subrequirement1 : Requirement4;
    }
    requirement def <'REQ-03'> Requirement3 {
        doc
        /* Documentation for the third requirement */
        attribute description = "Description of the third requirement";
    }
    requirement def <'REQ-04'> Requirement4 {
        doc
        /* Documentation for the fourth requirement */
        attribute description = "Description of the fourth requirement";
    }
} // package MyRequirements
package DroneRequirements {
    // Definitions carry the data shown in each row
    requirement def <'MISS-001'> MissionPerformance {
        doc
        /* The drone shall complete the delivery mission. */
    }

    requirement def <'SYS-001'> CruisingSpeed {
        doc
        /* The drone shall reach a cruising speed of at least 60 km/h. */
    }
    requirement def <'SYS-002'> OperationalRange {
        doc
        /* The drone shall have a minimum operational range of 30 km. */
        requirement battery : BatteryCapacity;
    }

    requirement def <'SUB-001'> MotorPower {
        doc
        /* Each motor shall output at least 150 W continuously. */
    }
    requirement def <'SUB-002'> BatteryCapacity {
        doc
        /* The battery shall store at least 1 500 Wh of usable energy. */
    }

    // Usage hierarchy: nesting depth determines row indentation level
    item def RequirementContext {
        requirement droneSystem : MissionPerformance {
            requirement speed : CruisingSpeed {
                requirement motor : MotorPower;
            }
            requirement range : OperationalRange {}
        }
    }
} // package DroneRequirements

package HierarchicalTableViewExample {
    private import SysideViews::*;
    private import DroneRequirements::*;

    view myHierarchicalRequirementsTable : SV::TVD::HTV {
        expose DroneRequirements::RequirementContext;
        filter hastype SysML::RequirementDefinition or hastype SysML::ItemDefinition;

        attribute :>> defaultCollapse = false;
        attribute :>> maxRowHeight = 125;

        view ID :> columnViews {
            attribute :>> featureToRender = CT::declaredShortName;
            attribute :>> defaultValue = "—";
            attribute :>> columnWidth = 110;
        }
        view Name :> columnViews {
            attribute :>> featureToRender = CT::declaredName;
            attribute :>> columnWidth = 220;
        }
        view Description :> columnViews {
            attribute :>> featureToRender = CT::specificDocumentation {
                attribute documentationName = "";
            }
            attribute :>> defaultValue = "n/a";
            attribute :>> columnWidth = 350;
        }
    }
} // package HierarchicalTableViewExample
