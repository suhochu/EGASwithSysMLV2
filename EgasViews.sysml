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

    // ==========================================
    // 1. Viewpoint 정의 (관심사 및 목적 프레이밍)
    // ==========================================

    viewpoint def StakeholderPerspective {
        doc
        /* [이해관계자 뷰포인트]
         * 시스템의 핵심 이해관계자와 그들의 우선순위, 역할(카테고리)을 한눈에 파악하기 위한 목적을 가집니다.
         */
        frame concern torqueArbitrationConcern : TorqueArbitrationConcern;
        // frame RV_StakeHolderModel::FunctionalSafetyConcern;
    }

    viewpoint def RequirementTraceabilityPerspective {
        doc
        /* [요구사항 추적성 뷰포인트]
         * 이해관계자 요구사항(SHR)이 시스템의 유스케이스(UC)와 검증 케이스(Verification)에 
         * 어떻게 할당(Allocate/Satisfy)되고 검증(Verify)되는지 누락 없이 추적하기 위한 목적입니다.
         */
    }

    // ==========================================
    // 2. View 정의 (Syside 도구를 활용한 다이어그램/테이블 생성)
    // ==========================================

    // [View 1] 이해관계자 및 속성 테이블 뷰

    view egas_stakeholder_summary_table : TVD::TableView {
        doc
        /* EGAS 시스템의 이해관계자 목록과 중요도, 카테고리를 보여주는 테이블 */
        viewpoint stakeholderPerspective : StakeholderPerspective;
        satisfy stakeholderPerspective;

        // 대상 요소 지정: RV_StakeHolderModel 패키지 내부의 모든 요소
        expose RV_StakeHolderModel::*;
        filter @ SysML::ConcernDefinition;

        view Name :> columnViews { attribute :>> featureToRender = CT::name; }
        view ReqId :> columnViews { attribute :>> featureToRender = CT::reqId; }
        view Doc :> columnViews { attribute :>> featureToRender = CT::documentation; }
        view Heritage :> columnViews { attribute :>> featureToRender = CT::heritage; }
        view Owner :> columnViews { attribute :>> featureToRender = CT::owner; }
        view Rationale :> columnViews {
            attribute :>> featureToRender = CT::specificDocumentation {
                attribute documentationName = "rationale";
            }
        }
        view Priority :> columnViews {
            attribute :>> featureToRender = CT::attributeValue {
                attribute attributeName = "priority";
            }
        }

        // 테이블 설정
        // attribute :>> globalFilter = "Stakeholder"; // 이름에 Stakeholder가 포함되거나 관련 요소 필터링

        // // 첫 번째 열: 이해관계자 이름
        // view col_name :>> columnViews {
        //     attribute :>> featureToRender = CT::declaredName;
        //     attribute :>> columnWidth = 200;
        // }

        // // 두 번째 열: 우선순위 (priority 속성 값)
        // view col_priority :>> columnViews {
        //     // '=' 대신 ':'을 사용하여 CT::attributeValue로 타입을 명시적으로 좁힘
        //     attribute :>> featureToRender = CT::attributeValue {
        //         attributeName = "priority";
        //     }
        //     attribute :>> columnWidth = 150;
        //     attribute :>> defaultValue = "N/A";
        // }

        // // 세 번째 열: 역할 카테고리 (category 속성 값)
        // view col_category :>> columnViews {
        //     attribute :>> featureToRender = CT::attributeValue {
        //         attributeName = "category";
        //     }
        //     attribute :>> columnWidth = 200;
        // }

        attribute fileName = "egas_stakeholder_summary_table";
        :>> TableViewDefinitions::TableView::columnOrder = (
            Name, ReqId, Doc, Owner, Heritage, Rationale, Priority,
        );
    }

    // // [View 2] 요구사항 vs 유스케이스 만족(Satisfy) 매트릭스 뷰
    // view req_usecase_trace_matrix : MatrixView {
    //     doc
    //     /* 유스케이스(열)가 어떤 이해관계자 요구사항(행)을 만족(Satisfy)시키는지 확인하는 매트릭스 */
    //     viewpoint requirementTraceabilityPerspective : RequirementTraceabilityPerspective;
    //     satisfy requirementTraceabilityPerspective;

    //     // 행(Row): 이해관계자 요구사항 목록
    //     view :>> rowView {
    //         expose RV_StakeholderRequirementModel::*;
    //         attribute :>> representation = Rep::shortName; // 예: SHR-01 형태로 표시
    //     }

    //     // 열(Column): 유스케이스 목록
    //     view :>> columnView {
    //         expose RV_UseCases::**;
    //         attribute :>> representation = Rep::shortName; // 예: UC1 형태로 표시
    //         attribute :>> verticalColumnNames = true; // 열 제목을 세로로 배치하여 공간 절약
    //     }

    //     // 셀(Cell): 관계 표시 설정
    //     view :>> cellView {
    //         // 요구사항(Row) <- 유스케이스(Column) 방향의 Satisfy 관계. (SysML에서 UC satisfy Req 이므로)
    //         attribute :>> direction = Dir::col2row;
    //         attribute :>> showWeakTraceability = true;
    //     }
    // }

    // [View 3] 요구사항 vs 검증 케이스(Verify) 매트릭스 뷰
    // view req_validation_trace_matrix : MatrixView {
    //     doc
    //     /* 각 요구사항(행)이 어떤 검증 케이스(열)를 통해 검증(Verify)되는지 매핑하는 매트릭스 */
    //     viewpoint requirementTraceabilityPerspective : RequirementTraceabilityPerspective;
    //     satisfy requirementTraceabilityPerspective;

    //     // 행(Row): 이해관계자 요구사항
    //     view :>> rowView {
    //         expose RV_StakeholderRequirementModel::**;
    //         attribute :>> representation = Rep::shortName;
    //     }

    //     // 열(Column): 검증 케이스 (Test, Demo, Inspection 등)
    //     view :>> columnView {
    //         expose RV_StakeholderReqValidationModel::**;
    //         attribute :>> representation = Rep::name;
    //         attribute :>> verticalColumnNames = true;
    //     }

    //     // 셀(Cell): Verify 관계
    //     view :>> cellView {
    //         // 요구사항(Row) <- 검증케이스(Column)가 Verify 하는 방향이므로 col2row (↙)
    //         attribute :>> direction = Dir::col2row;
    //     }

    //     attribute fileName = "req_validation_trace_matrix";
    // }

    // [View 4] (참고) 기존에 작성하신 시스템 컨텍스트 블록 다이어그램 뷰 확장
    view egas_system_context : InterconnectionView {
        expose RV_ContextModel::EgasContext::*;
        filter not (@ NotShownInView);

        attribute fileName = "egas_system_context";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    view egas_system : GeneralView {
        expose RV_ContextModel::*;
        // filter not (@ NotShownInView);

        attribute fileName = "egas_system";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    view egas_system_main_action : ActionFlowView {
        expose RV_ContextModel::EgasSystem::EgasMainContinuousOperation::*;
        // filter not (@ NotShownInView);

        attribute fileName = "egas_system_main_action";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    view egas_system_state : StateTransitionView {
        expose RV_ContextModel::EgasSystem::egasBehavior::*::**;
        // filter not (@ NotShownInView);

        attribute fileName = "egas_system_state";
        attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }

    view egas_stakeholders_concern : GeneralView {
        doc
        /* EGAS 시스템의 이해관계자 목록과 중요도, 카테고리를 보여주는 테이블 */
        viewpoint stakeholderPerspective : StakeholderPerspective;
        satisfy stakeholderPerspective;

        // 대상 요소 지정: RV_StakeHolderModel 패키지 내부의 모든 요소
        expose RV_StakeHolderModel::*::**;
        filter @ SysML::ConcernDefinition;

        attribute fileName = "egas_stakeholders_concern";
        // attribute depth = 2;
        attribute fileType = "png";
        // render asTreeDiagram;
    }
} // package RV_ViewsAndViewpoints
