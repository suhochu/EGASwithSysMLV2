package FE_SystemBehaviorModel {
    private import FE_BehaviorModel::*;

    // ==========================================
    // FE 통합 시스템 동작 모델 (FE System Behavioral Model)
    // ==========================================
    state rvEgasState : RV_BehavioralModel::EgasBehavior;
    state FeEgasBehavior :> rvEgasState {
        state redefines drivingControlRegion : FE_BehaviorModel::DrivingTorqueBehavior;
        state
            redefines emergencyInterventionRegion : FE_BehaviorModel::EmergencyInterventionBehavior;
        state
            redefines safetyMonitoringRegion
            : FE_BehaviorModel::DiagnosticsAndMaintenanceSupportBehavior;
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.calibrationHandling
            : FE_BehaviorModel::CalibrationSupportBehavior;
        state
            redefines
                monitoringAndServiceRegion.monitoringActive.diagnosticsHandling
            : FE_BehaviorModel::DiagnosticsAndMaintenanceSupportBehavior;
    }
} // package FE_SystemBehaviorModel
