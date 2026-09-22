package ReqCommon {
    private import ScalarValues::*;

    doc
    /* [공통 어휘 패키지]
     * "01. Requirements Viewpoint"의 모든 패키지가 공유하는 열거형(Enum)과 형상관리용 메타데이터를 정의한다.
     * 개별 요구사항/이해관계자/유스케이스 파일에서 반복적으로 필요한 값 집합(우선순위, 치명도, 검증/유효성 상태 등)을
     * 이 파일 한 곳에서 정의하여 전체 모델의 일관성을 보장한다.
     */

    @MetaInformation {
        version = "v0.1";
    }

    // ==========================================
    // 0. 형상관리 메타데이터 (Configuration Management Metadata)
    // ==========================================

    metadata def MetaInformation {
        doc
        /* 모델 요소(패키지/요구사항/이해관계자/유스케이스 등)의 형상관리 버전을 기록하는 메타데이터.
         * 요소의 내용이 의미 있게 개정될 때마다 버전 문자열을 갱신한다 (예: "v0.1" -> "v0.2").
         * 사용법: 버전을 기록하려는 요소의 본문(body) 안에 `@MetaInformation { version = "v0.1"; }` 형태로 붙인다.
         */
        attribute version : String; // 형상관리 버전 문자열 (예: "v0.1")
        attribute updatedBy : ProjectMember [0..1]; // 최종 개정자 (최초 작성 시에는 생략 가능)
        attribute changeNote : String [0..1]; // 이번 개정에서 무엇이 왜 바뀌었는지 요약 (최초 작성 시에는 생략 가능)
        // attribute requirementKind : RequirementKind;
    }

    // ==========================================
    // 1. 프로젝트 관리 및 우선순위 관련 열거형
    // ==========================================

    enum def ProjectMember {
        doc
        /* 요구사항의 author/owner로 지정할 수 있는 프로젝트 참여자 목록 */
        suhoChu;
    }

    enum def PriorityLevel {
        doc
        /* 요구사항의 비즈니스적 가치/구현 시급성 우선순위 */
        enum High;
        enum Medium;
        enum Low;
    }

    enum def CriticalityLevel {
        doc
        /* 요구사항 미충족 시 시스템 안전/기능에 미치는 영향의 치명도 */
        enum Critical; // 시스템 마비 또는 심각한 안전 문제 발생
        enum Major; // 주요 기능 저하
        enum Minor; // 경미한 기능 저하 또는 우회 가능
        enum Negligible; // 영향 없음
    }

    // ==========================================
    // 2. 요구사항 품질/유효성 상태 관련 열거형
    // ==========================================

    enum def ReqVerificationStatus {
        doc
        /* 요구사항 "문장" 자체가 표준 구문/작성 규칙을 잘 따르는지에 대한 검증 상태 (Need/Requirement Verification) */
        enum Draft; // 초안 작성 중
        enum InReview; // 품질 검토 중
        enum Verified; // 작성 검증 완료 (합격)
        enum Rejected; // 검증 실패 (수정 필요)
    }

    enum def ReqValidationStatus {
        doc
        /* 요구사항이 이해관계자의 실제 니즈를 올바르게 대변하는지에 대한 유효성 확인 상태 (Need/Requirement Validation) */
        enum Draft; // 초안 상태
        enum InReview; // 이해관계자 리뷰 중
        enum Validated; // 유효성 확인 완료 (이해관계자 승인)
        enum Rejected; // 유효성 실패 (니즈 불일치)
    }

    enum def VVMethod {
        doc
        /* 요구사항의 검증/확인(V&V)에 사용할 수 있는 방법론 4종 */
        enum Test; // 시험: 물리적/소프트웨어적 작동 테스트
        enum Analysis; // 분석: 수학적 모델링, 시뮬레이션 등을 통한 검증
        enum Inspection; // 검사: 육안 검사, 코드 리뷰, 문서 검토
        enum Demonstration; // 실증/데모: 시연을 통한 기능 확인
        enum Audit; // 외부 기관의 프로세스 및 규제 준수 심사
    }

    // ==========================================
    // 3. 목표(Goal) 세분화 및 관계 관련 열거형/메타데이터
    // ==========================================

    enum def RefinementKind {
        doc
        /* 상위 목표가 하위 목표(들)로 세분화되는 방식 */
        enum AND; // 모든 하위 목표를 함께 충족해야 상위 목표가 충족됨
        enum OR; // 하위 목표 중 하나만 충족해도 상위 목표가 충족됨(대체 경로)
    }

    metadata def GoalRefinement {
        doc
        /* 상위 목표(concern/requirement) 본문에 붙여, 그 하위 목표들이 AND/OR 중 어떤 방식으로 세분화되었는지 기록하는 메타데이터. */
        attribute kind : RefinementKind; // 하위 목표들과의 세분화 방식(AND/OR)
        attribute rationale : String [0..1]; // 해당 세분화 방식을 선택한 이유
    }

    enum def ContributionPolarity {
        doc
        /* 한 목표의 달성이 다른 목표에 미치는 영향의 방향 */
        enum Positive; // 대상 목표 달성에 긍정적으로 기여함(Contribution, +)
        enum Negative; // 대상 목표 달성과 상충하여 갈등을 유발함(Conflict, -)
    }

    metadata def GoalRelationship {
        doc
        /* 목표(concern/requirement) 간의 기여(+)/갈등(-) 관계를 기록하는 메타데이터.
         * 영향을 주는 쪽(source) 목표의 본문에 `@GoalRelationship { relatedGoal = "대상 목표 이름"; polarity = ...; rationale = "..."; }` 형태로 붙인다.
         */
        attribute relatedGoal : String; // 관계를 맺는 대상 목표의 이름 (예: "PreciseControlConcern")
        attribute polarity : ContributionPolarity; // Positive(기여) 또는 Negative(갈등)
        attribute rationale : String; // 이 관계가 성립하는 근거
    }

    // ==========================================
    // 4. 인터페이스 정제를 위해 추가된 공통 열거형 정의
    // ==========================================

    enum def IgnitionStatusEnum {
        enum Off;
        enum On;
        enum Start;
    }

    enum def DashboardWarningStatusEnum {
        enum Normal; // 정상 (경고등 Off)
        enum Warning; // 일반 경고 (예: 성능 저하)
        enum Critical; // 치명적 경고 (예: 페일세이프 발동 즉시 점등)
    }

    enum def InterventionTypeEnum {
        enum Absolute; // 절대 토크 제한 (예: 무조건 50Nm 이하로 제한)
        enum Relative; // 상대 토크 저감 (예: 현재 토크에서 -30Nm 감산)
    }
} // package ReqCommon
