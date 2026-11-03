// Copyright (c) 2026 Sensmetry, UAB. All Rights Reserved.
// Version 0.11.0
library package <SV> SysideViews {
    public import NavigationSteps::*;
    public import TableViewDefinitions::*;
    public import MatrixViewDefinitions::*;

    abstract view def ContentView {
        doc
        /* Generic grid view element that contains reference to exposed elements as well as three
         * custom boolean attributes that allow additional control over the content displayed in the view.
         */
        baseViewElement [0..*] {
            doc
            /* This is a Syside-specific element that represents the exposed elements after the filtering
             * (in a `HierarchicalTableView`, the definition of each tree row).
             * Used for relative navigation steps in table view columns.
             *
             * Note that it is exclusive to Syside Grid Views and has no semantic meaning in the model.
             */
        }
        attribute includeReferenceElements default false;
        attribute includeAbstractElements default false;
        attribute exposeFeaturesAndHeritage default false;
    }

    package <TVD> TableViewDefinitions {
        enum def <ColRep> Representation {
            doc
            /* What aspect of the chain's target element a column renders.
             * **Write-back**: editing is mostly determined by the representation.
             *
             * Currently editable representations:
             * - `featureValue` (for `attributeUsage` only)
             * - `specificDocumentation`
             * - `language`
             */
            declaredName {
                doc
                /* The declared name of the element. */
            }
            name {
                doc
                /* The name of the element. */
            }
            declaredShortName {
                doc
                /* The declared short name of the element. */
            }
            shortName {
                doc
                /* The short name of the element. */
            }
            qualifiedName {
                doc
                /* The qualified name of the element. */
            }
            featureValue {
                doc
                /* The value of the target element itself (the chain must land on a
                 * feature).  Read-only for features that are not attribute usages, or when
                 * the value involves units, otherwise writable.
                 */
            }
            direction {
                doc
                /* The direction of the element. */
            }
            documentation {
                doc
                /* The concatenation of all documentation comments. */
            }
            specificDocumentation {
                doc
                /* The documentation of the target element with the name given in
                 * `documentationName` (use "" for nameless docs). Writable.
                 */
                attribute documentationName default "";
            }
            'language' {
                doc
                /* The language-specific textual body of the target element, e.g. the
                 * `language "English"` body of a constraint. Writable.
                 *
                 * An empty `languageName` never matches anything: every cell
                 * degrades to the read-only column default.
                 */
                attribute languageName default "English";
            }
        }

        view def <TV> TableView :> ContentView {
            private import ScalarValues::*;
            attribute maxRowHeight : Integer default 125;
            attribute globalFilter : String default null;
            ref columnOrder :> columnViews [0..*] ordered;
            view columnViews [0..*] {
                doc
                /* Subset these views to declare table columns.
                 *
                 * The order is preserved, unless overwritten in `columnOrder`
                 */
                columnFeature [0..*] default baseViewElement {
                    doc
                    /* The feature that will be represented in the column.
                     *
                     * Example of how to set a custom feature:
                     *
                     *     ```
                     *     :>> columnFeature = SV::NS::Subject(baseViewElement);
                     *     ```
                     */
                }
                attribute featureRepresentation : ColRep :> ColRep::qualifiedName {
                    doc
                    /* Representation of the column's element.
                     *
                     * Example of how to set a custom representation:
                     *
                     *     ```
                     *     attribute :>> featureRepresentation :> ColRep::specificDocumentation {
                     *         attribute :>> documentationName = "spec";
                     *     }
                     *     ```
                     */
                }
                attribute defaultValue default "" {
                    doc
                    /* Shown when the chain reached this column's element but the
                     * representation returned nothing. A non-existent `attributeUsage`
                     * under `featureValue` also shows it, with the cell still
                     * editable — saving creates the attribute.
                     *
                     * Also shown when a `*List` column found nothing.
                     */
                }
                attribute notApplicableValue default "N/A" {
                    doc
                    /* Shown when the chain never resolved to an element (e.g. `Subject` on a part).
                     * Note that a non-existent `attributeUsage` under `featureValue` will show the
                     * `defaultValue` instead.
                     *
                     * Also shown when a `*Fan` column found nothing.
                     */
                }
                attribute columnWidth : Integer default 150;
                attribute columnFilter : String default null;
            }
        }

        view def <HTV> HierarchicalTableView :> TableView {
            filter as SysML::Definition istype SysML::Definition;
            attribute :>> exposeFeaturesAndHeritage = true;
            attribute defaultCollapse default true;
            view hierarchicalColumn :> columnViews {
                doc
                /* The column that carries the tree: its cells are indented by
                 * their depth and hold the expand/collapse control.
                 *
                 * Redefine it to choose what the tree is labelled by and what element it represents
                 *
                 *     ```
                 *     view Name :>> hierarchicalColumn {
                 *         attribute :>> featureRepresentation :> ColRep::name;
                 *     }
                 *     ```
                 *
                 * The hierarchical column is different from other columns in that:
                 *
                 *  - It is always the first column, and no `columnOrder` can
                 *    move another column ahead of it.
                 *  - It cannot be hidden
                 *  - Its `columnFeature` may not contain a `Fan` step.
                 *
                 * It declares nothing of its own, so that a column can redefine
                 * it together with an inherited column
                 * (`view Name :>> Name, hierarchicalColumn;`) without inheriting
                 * two `featureRepresentation`s.
                 */
            }
        }
    } // package <TVD> TableViewDefinitions

    package <MVD> MatrixViewDefinitions {
        enum def <Dir> MatrixTraceabilityDirection {
            enum undirected {
                doc
                /* Row can either be in source or target, and column is the other of the two.
                 * Shows "✔" if relationship fits.
                 */
            }
            enum row2col {
                doc
                /* Source is row, target is column. Shows "↗" if relationship fits. */
            }
            enum col2row {
                doc
                /* Source is column, target is row. Shows "↙" if relationship fits. */
            }
        }

        enum def <Rep> MatrixElementRepresentation {
            enum name;
            enum shortName;
            enum qualifiedName;
        }
        view def <MV> MatrixView {
            view rowView : ContentView [1] {
                doc
                /* Inside this view use `expose` and `filter` to specify what you want to see
                 * as rows in the matrix.
                 */
                attribute representation : Rep default Rep::name;
            }
            view columnView : ContentView [1] {
                doc
                /* Inside this view use `expose` and `filter` to specify what you want to see
                 * as columns in the matrix.
                 */
                attribute representation : Rep default Rep::name;
                attribute verticalColumnNames default false;
            }
            view cellView : ContentView [1] {
                doc
                /* Inside this view use `expose`, `filter`, and `direction` to specify what you want to see
                 * as cells in the matrix.
                 */
                attribute :>> includeReferenceElements default true;
                attribute direction : Dir default Dir::undirected;
                attribute showWeakTraceability default false;
                attribute portsAreTransparent default false {
                    doc
                    /* If true, connections to ports will be treated as direct connections
                     * to the port's owner. Connections only — allocations already pair at
                     * definition level and are unaffected.
                     */
                }
                filter (
                    as SysML::ConnectionUsage hastype SysML::ConnectionUsage or
                    as SysML::AllocationUsage hastype SysML::AllocationUsage or
                    @ RequirementDerivation::derivation
                );
            }
        }

        abstract view def EditableMatrixView :> MatrixView {
            view :>> rowView {
                filter as SysML::Definition istype SysML::Definition;
            }
            view :>> columnView {
                filter as SysML::Definition istype SysML::Definition;
            }
            view :>> cellView {
                attribute :>> exposeFeaturesAndHeritage = true;
            }
        }

        view def ConnectionMatrixView :> EditableMatrixView {
            view :>> cellView {
                filter (
                    as SysML::ConnectionUsage hastype SysML::ConnectionUsage and
                    not (@ RequirementDerivation::derivation)
                );
            }
        }

        view def AllocationMatrixView :> EditableMatrixView {
            view :>> cellView {
                filter as SysML::AllocationUsage hastype SysML::AllocationUsage;
            }
        }

        view def RequirementMatrixView :> EditableMatrixView {
            view :>> cellView {
                filter @ RequirementDerivation::derivation;
            }
        }
    } // package <MVD> MatrixViewDefinitions

    package <NS> NavigationSteps {
        private import AbstractNavigationSteps::*;
        private import ScalarValues::*;

        // ////////////////////////////////////////////////////////////
        // Navigation Steps used for declaring table column elements
        // For Step types, see package <NS> AbstractNavigationSteps.
        // ////////////////////////////////////////////////////////////

        abstract calc def Heritage :> Step {
            doc
            /* The types the element specializes, walked transitively up to
             * `depth` (-1 = unbounded). Explicit relationships only —
             * implicit specializations of library base types are not
             * included.
             *
             * **Applicable to:** SysML Types.
             */
            in elements [1];
            in depth : Integer default -1 {
                doc
                /* Cutoff depth for the heritage walk. Set -1 for unbounded. */
            }
            return targets [0..*];
        }
        calc def HeritageList :> Heritage, List;
        calc def HeritageFan :> Heritage, FanOut;
        calc def HeritageFirst :> Heritage, First {
            doc
            /* `depth` is bound to 1 — passing an explicit depth is an error. */
            in elements [1];
            in depth : Integer = 1;
            return targets [0..1];
        }

        abstract calc def Definitions :> Step {
            doc
            /* The definitions typing the usage.
             *
             * Only typings written in the model: the implicit library typing
             * every usage carries (`part loose;` is implicitly a
             * `Parts::Part`) are ignored.
             *
             * **Applicable to:** SysML Usages.
             */
            in elements [1];
            return targets [0..*];
        }
        calc def DefinitionsList :> Definitions, List;
        calc def DefinitionsFan :> Definitions, FanOut;
        calc def DefinitionsFirst :> Definitions, First {
            in elements [1];
            return targets [0..1];
        }

        abstract calc def Specializations :> Step {
            doc
            /* The definitions this definition directly specializes.
             *
             * **Applicable to:** SysML Definitions.
             */
            in elements [1];
            return targets [0..*];
        }
        calc def SpecializationsList :> Specializations, List;
        calc def SpecializationsFan :> Specializations, FanOut;
        calc def SpecializationsFirst :> Specializations, First {
            in elements [1];
            return targets [0..1];
        }

        calc def Owner :> Single {
            doc
            /* The direct owner of an element. 
             *
             * **Applicable to:** SysML Namespaces.
             */
        }

        abstract calc def Usages :> Step {
            doc
            /* The usage **features** of the element, owned and inherited,
             * optionally narrowed to a `UsageKind`.
             *
             * The narrowing is exact unless `includeSubtypes` is true, which
             * widens the kind to everything SysML derives from it — `itemUsage`
             * then also admits parts. `flow`, `succession`, and `bind` usages
             * fall under no kind but `usage`.
             *
             * Features declared in the standard library are excluded;
             * third-party library features are kept.
             *
             * **Applicable to:** SysML Definitions and Usages.
             */
            in elements [1];
            in kind : UsageKind default UsageKind::usage;
            in includeSubtypes : Boolean default false;
            return targets [0..*];
        }
        enum def UsageKind {
            enum usage; // any usage kind: match by name alone
            enum occurrenceUsage;
            enum attributeUsage;
            enum itemUsage;
            enum partUsage;
            enum portUsage;
            enum connectionUsage;
            enum actionUsage;
            enum constraintUsage;
            enum assertedConstraintUsage;
            enum requirementUsage;
        }
        calc def UsageList :> Usages, List;
        calc def UsageFan :> Usages, FanOut;
        calc def UsageFirst :> Usages, First {
            in elements [1];
            in kind : UsageKind default UsageKind::usage;
            in includeSubtypes : Boolean default false;
            return targets [0..1];
        }

        enum def NameType {
            enum name;
            enum shortName;
        }

        calc def NamedUsage :> First {
            doc
            /* The element's usage feature with this name — its effective name
             * under `NameType::name` (usually the declared name), its short
             * name under `NameType::shortName` — optionally narrowed to a
             * `UsageKind`.
             *
             * **Applicable to:** SysML Definitions and Usages.
             */
            in elements [1];
            in name : String;
            in nameType : NameType;
            in kind : UsageKind default UsageKind::usage;
            in includeSubtypes : Boolean default false;
            return targets [0..1];
        }

        abstract calc def RequirementConstraints :> Step {
            doc
            /* The requirement's `assume` / `require` constraints, own and
             * inherited, optionally narrowed to one of the two kinds
             * (`either`, the default, accepts both, in declaration order).
             *
             * Attachment, not metaclass: a plain or asserted constraint in
             * the requirement body is not one of these — reach those through
             * the `Usage*` family and its `UsageKind`.
             *
             * **Applicable to:** SysML Requirements.
             */
            in elements [1];
            in kind : RequirementConstraintKindSV default RequirementConstraintKindSV::either;
            return targets [0..*];
        }
        enum def RequirementConstraintKindSV {
            enum required;
            enum assumed;
            enum either;
        }
        calc def RequirementConstraintsList :> RequirementConstraints, List;
        calc def RequirementConstraintsFan :> RequirementConstraints, FanOut;
        calc def RequirementConstraintsFirst :> RequirementConstraints, First {
            in elements [1];
            in kind : RequirementConstraintKindSV default RequirementConstraintKindSV::either;
            return targets [0..1];
        }

        calc def Subject :> Single {
            doc
            /* The subject of the requirement.
             *
             * **Applicable to:** SysML Requirements.
             */
            in elements [1];
            return targets [0..1];
        }

        calc def UsageHTV :> Single {
            doc
            /* The usage feature through which the hierarchy reached this row.
             * A hierarchical table's tree is walked over usages and each row
             * shows the definition typing one; this step navigates to that
             * usage itself.
             *
             * **Applicable to:** Hierarchical Table View `baseViewElement`.
             */
            in elements [1];
            return targets [0..1];
        }

        calc def MetadataUsageTag :> Single {
            doc
            /* The element's owned metadata tag (`@Tag { … }`), selected by
             * the tag definition's name — its effective name under
             * `NameType::name`, its short name under `NameType::shortName`.
             * The tag usage's own name never matches: what `@` names is the
             * definition.
             *
             * **Applicable to:** SysML Namespace.
             */
            in elements [1];
            in name : String;
            in nameType : NameType;
            return targets [0..1];
        }
    } // package <NS> NavigationSteps

    package AbstractNavigationSteps {
        abstract calc def <Step> NavigationStep {
            doc
            /* The most generic navigation step: element in, collection out. */
            in elements [0..1];
            return targets [0..*]; // empty = navigation had no result
        }
        abstract calc def <Single> SinglevaluedStep :> Step {
            doc
            /* At most one target per input element, which may feed a further
             * step.
             */
        }
        abstract calc def <FanOut> FanOutStep :> Step {
            doc
            /* A step whose targets split the parent row into nested rows — the
             * 1:N join of the table model.
             *
             * A `*Fan` call must be the outermost call of a named view-level ref
             * (an *anchor*), never inline in a column or nested in another call:
             *
             *     ports = UsageFan(baseViewElement, UsageKind::portUsage);
             *
             * An anchor starts from `baseViewElement` or one other anchor, and
             * feeds at most one further anchor — anchors form a chain, not a
             * tree. A column then references one anchor and applies only non-Fan
             * steps to it. Declaration order does not matter, and columns sharing
             * an anchor are row-aligned.
             */
        }
        abstract calc def <List> ListElements :> Step {
            doc
            /* A terminal step: every target rendered together in one cell. Its
             * elements cannot feed another step, so a `*List` call may only be a
             * chain's LAST step. Such a column is read-only for every row.
             */
        }
        abstract calc def <First> FirstStep :> Single {
            doc
            /* For navigations that yield one target under the supported
             * modelling pattern, even though SysML permits more —
             * `DefinitionsFirst` for a usage typed by exactly one definition.
             * Not a way to take the head of a list: if more targets exist the
             * model deviates from the pattern, and the cell renders the first one
             * read-only, with a note.
             */
        }
    } // package AbstractNavigationSteps
} // library package <SV> SysideViews
