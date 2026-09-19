package RV_ViewsAndViewpoints {
    private import SysideViews::*;
    private import ScalarValues::*;
    private import StandardViewDefinitions::*;

    // 이전에 정의된 모델 패키지들을 가져옵니다.
    private import RV_ContextModel::*;
    private import RV_StakeHolderModel::*;
    private import RV_StakeholderRequirementModel::*;
    private import RV_StakeholderReqValidationModel::*;
    private import RV_UseCases::*;
    private import ViewAndViewpintCommon::*;
    private import RV_StakeHolderConcernModel::*;

    // ==========================================
    // 1. Viewpoint 정의 (관심사 및 목적 프레이밍)
    // ==========================================

    viewpoint def StakeholderPerspective {
        doc
        /* [이해관계자 뷰포인트]
         * 시스템의 핵심 이해관계자와 그들의 우선순위, 역할(카테고리)을 한눈에 파악하기 위한 목적을 가집니다.
         */
    }

    viewpoint def RequirementTraceabilityPerspective {
        doc
        /* [요구사항 추적성 뷰포인트]
         * 이해관계자 요구사항(SHR)이 시스템의 유스케이스(UC)와 검증 케이스(Verification)에 
         * 어떻게 할당(Allocate/Satisfy)되고 검증(Verify)되는지 누락 없이 추적하기 위한 목적입니다.
         */
    }

    // 01. Objectives Table

    view egas_objective_table : TVD::TableView {
        viewpoint stakeholderPerspective : StakeholderPerspective;
        satisfy stakeholderPerspective;

        // 대상 요소 지정: RV_StakeHolderModel 패키지 내부의 모든 요소
        expose RV_Objectives::*;
        filter @ SysML::RequirementDefinition;

        view Name :> columnViews { attribute :>> featureToRender = CT::name; }
        view Doc :> columnViews { attribute :>> featureToRender = CT::documentation; }
        view Heritage :> columnViews { attribute :>> featureToRender = CT::heritage; }
        view Owner :> columnViews { attribute :>> featureToRender = CT::owner; }
        attribute :>> includeLibraryElements = true;

        :>> TableViewDefinitions::TableView::columnOrder = (Name, Doc, Heritage, Owner);
    }

    // 02-1 시스템 컨텍스트
    view egas_system_context : InterconnectionView {
        expose RV_ContextModel::EgasContext::*;
        filter not (@ NotShownInView);

        attribute fileName = "02_1_egas_system_context";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    view egas_system : GeneralView {
        expose RV_ContextModel::*;

        attribute fileName = "02_1_egas_system";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    view egas_system_main_action : ActionFlowView {
        expose RV_ContextModel::EgasSystem::EgasMainContinuousOperation::*;
        // filter not (@ NotShownInView);

        attribute fileName = "02_1_egas_system_main_action";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    view egas_system_state : StateTransitionView {
        expose RV_ContextModel::EgasSystem::egasBehavior::*::**;
        // filter not (@ NotShownInView);

        attribute fileName = "02_1_egas_system_state";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    // 02-2 Actors
    view egas_system_actors : GeneralView {
        expose RV_ActorModel::*;
        filter not (@ NotShownInView);

        attribute fileName = "02_1_egas_system_actors";
        attribute depth = 2;
        attribute fileType = "png";
        render Views::asTreeDiagram;
    }

    view egas_system_interfaces : GeneralView {
        expose RV_InterfaceModel::*;
        filter not (@ NotShownInView);

        attribute fileName = "02_1_egas_system_interfaces";
        attribute depth = 2;
        attribute fileType = "png";
        render Views::asTreeDiagram;
    }

    // 03-1 Stakeholder Concerns
    view egas_stakeholder_concern_table : TVD::TableView {
        viewpoint stakeholderPerspective : StakeholderPerspective;
        satisfy stakeholderPerspective;

        // 대상 요소 지정: RV_StakeHolderModel 패키지 내부의 모든 요소
        expose RV_StakeHolderConcernModel::*;
        filter @ SysML::ConcernDefinition;

        view Name :> columnViews { attribute :>> featureToRender = CT::name; }
        view Doc :> columnViews { attribute :>> featureToRender = CT::documentation; }
        view Heritage :> columnViews { attribute :>> featureToRender = CT::heritage; }
        view Owner :> columnViews { attribute :>> featureToRender = CT::owner; }

        attribute :>> includeLibraryElements = true;

        :>> TableViewDefinitions::TableView::columnOrder = (Name, Doc, Owner, Heritage);
    }

    view egas_stakeholder_requirement_table : TVD::TableView {
        viewpoint stakeholderPerspective : StakeholderPerspective;
        satisfy stakeholderPerspective;

        // 대상 요소 지정: RV_StakeHolderModel 패키지 내부의 모든 요소
        expose RV_StakeholderRequirementModel::stakeholderRequirementSet::*;
        filter hastype SysML::RequirementDefinition or hastype SysML::RequirementUsage; 
        attribute :>> includeAbstractElements = true;
        // attribute :>> exposeFeaturesAndHeritage = true;
        attribute :>> maxRowHeight = 300;

        view ID :> columnViews {
            attribute :>> featureToRender = CT::declaredShortName;
            attribute :>> defaultValue = "id";
            attribute :>> columnWidth = 100;
        }
        view Name :> columnViews { attribute :>> featureToRender = CT::name; }
        view Doc :> columnViews { attribute :>> featureToRender = CT::documentation; }
        view Heritage :> columnViews { attribute :>> featureToRender = CT::heritage; }
        view Owner :> columnViews { attribute :>> featureToRender = CT::owner; }
        view Description :> columnViews {
            attribute :>> featureToRender = CT::attributeValue {
                attribute attributeName = "description";
            }
            attribute :>> defaultValue = "n/a";
            attribute :>> columnWidth = 304;
        }

        :>> TableViewDefinitions::TableView::columnOrder = (ID, Name, Doc, Owner, Heritage, Description);
    }
} // package RV_ViewsAndViewpoints
