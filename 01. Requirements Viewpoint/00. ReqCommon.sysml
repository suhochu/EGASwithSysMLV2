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
 

    // enum def RequirementKind {
    //     doc
    //     /* 요구사항이 시스템 자체의 특성인지, 프로젝트 수행 및 비즈니스 성과인지 구분 */
    //     ProjectRelated; // 프로젝트 진행과 관련된 목표 (인증, 비용, 프로세스 등)
    //     SystemRelated; 
    //     FunctionalRequirement;
    //     PerformanceRequirement;
    //     QualityRequirement;
    //     DesignConstraint;
    //     // 시스템 자체와 관련된 기능적/비기능적 기술 목표
    // }

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
    }

    enum def ValidationMethod {
        doc
        /* 이해관계자의 니즈 충족 여부를 확인하는 운용 기반의 검증 방법 */
        enum UserAcceptanceTest; // 실 사용자 참여 인수 테스트 (실차 주행 등)
        enum OperationalDemonstration; // 운용 환경 시나리오 시연
        enum ExpertReview; // 도메인 전문가 및 규제 기관의 설계/문서 검토
    }
} // package ReqCommon
