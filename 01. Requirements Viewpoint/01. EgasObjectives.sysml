package SystemObjectives {
    doc
    /* [목표(Goal) 뷰포인트]
     * EGAS 프로젝트가 존재하는 근본적인 이유를 정의한다: 어떤 문제(Problem Statement)를 풀기 위해
     * 어떤 시스템 아이디어(System Idea)를 제안하는지를 최상위 요구사항 계층으로 표현한다.
     * 이 패키지의 요구사항들은 이후 03/04번 파일의 이해관계자 우려사항(Concern) 및 이해관계자
     * 요구사항(Stakeholder Requirement)이 `:>` 특화(specialization)를 통해 근거로 삼는 최상위 앵커 역할을 한다.
     */
    private import ModelingMetadata::*;
    private import EgasBaseArchitecture::EgasSystem;
    private import EgasSystemStakeHolders::*;
    private import ReqCommon::*;

    @ElementVersion {
        version = "v0.1";
    }

    requirement def Objective {
        doc
        /* 프로젝트의 근본적인 문제 정의(Problem Statement), 시스템 아이디어(System Idea), 
         * 그리고 비즈니스 목표를 모델링하는 최상위 요구사항 타입
         */
    }

    // ==========================================
    // 1. Problem Statement (문제 정의)
    // ==========================================
    requirement def <'OBJ-PBLM'> egasProblemStatement :> Objective {
        doc
        /* [Problem Statement]
         * 현대의 자동차는 운전자, 크루즈 컨트롤, 차체 자세 제어(ESP), 변속기 제어(TCU) 등 다양한 소스에서 동시다발적이고 상충되는 토크 요구가 발생한다.
         * 비정상적인 가속이나 센서 고장 등은 치명적인 사고로 직결되는 페인 포인트를 가진다.
         * 시스템은 다수의 복합적인 토크 요구를 안전하게 중재하고, 기계적 결함이나 가속/제동 동시 조작 상황에서도 차량의 추진력을 완벽하게 통제할 수 있는 고신뢰성 중앙 엔진 제어를 보장해야 한다.
         */
        @ElementVersion {
            version = "v0.1";
        }
    }

    // ==========================================
    // 2. System Idea / Elevator Pitch (시스템 아이디어)
    // ==========================================
    requirement def <'OBJ-IDEA'> egasSystemIdea :> 'OBJ-PBLM' {
        doc
        /* [System Idea]
         * EGAS(Electronic Throttle Control) 시스템은 차량 내 모든 토크 요구를 중앙집중식으로 수집하고 안전 최우선 원칙(예: Brake Override)에 따라 중재하는 지능형 엔진 제어 시스템이다.
         * 이중화된 센서 모니터링과 정밀한 공기, 연료, 점화 제어를 동기화하여 운전자의 의도를 정확하게 구현함과 동시에 극한의 주행 상황에서도 차량의 안정성을 보장해야 한다.
         */
        @ElementVersion {
            version = "v0.1";
        }
    }
} // package SystemObjectives
