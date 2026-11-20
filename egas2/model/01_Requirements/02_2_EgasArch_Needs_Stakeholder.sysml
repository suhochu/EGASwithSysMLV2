package EgasArch_Needs_Stakeholder {
    enum def StakeholderPriorityKind {
        enum Critical;
        enum High;
        enum Medium;
        enum Low;
    }

    part def EgasStakeholder {
        attribute priority : StakeholderPriorityKind;
    }

    part def Driver :> EgasStakeholder {
        doc
        /* 운전자: 가속, 제동, 크루즈 컨트롤을 직접 조작한다. */
        :>> priority = StakeholderPriorityKind::Critical;
    }

    part def SafetyRegulator :> EgasStakeholder {
        doc
        /* 안전 규제 기관: 기능 안전 규격 준수와 결함 시 페일세이프 전환의 신뢰성을 본다. */
        :>> priority = StakeholderPriorityKind::Critical;
    }

    part def PlatformEngineer :> EgasStakeholder {
        doc
        /* 플랫폼 엔지니어·시스템 아키텍트: 다중 토크 요구를 중재하는 아키텍처를 책임진다. */
        :>> priority = StakeholderPriorityKind::High;
    }
} // package EgasArch_Needs_Stakeholder
