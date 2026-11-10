package EgasArch_Fwb_Function {
    private import ScalarValues::*;
    private import EgasArch_Common_Units::*;
    private import EgasArch_Common_Signals::*;
    private import EgasArch_Beh_Behavior::TorqueDemand;
    private import EgasArch_Fbb_Function::*;

    // UF-01 inner functions (GP-A).
    action def DerivePermissibleTorqueFunction {
        doc
        /* FN-01: derive the permissible torque from the driver pedal position. */
        in pedalPosition : AccelerationPedalPosition;
        out permissibleTorque : TorqueQuantity;
    }

    action def EstimateActualTorqueFunction {
        doc
        /* FN-02: estimate the actual engine torque from the engine sensor data. */
        in engineSensor : EngineSensorData;
        out actualTorque : TorqueQuantity;
    }

    action def CompareTorqueFunction {
        doc
        /* FN-03: compare the actual torque with the permissible torque and set the excess flag. */
        in permissibleTorque : TorqueQuantity;
        in actualTorque : TorqueQuantity;
        out excessFlag : TorqueExcessFlag;
    }

    // UF-02 inner functions (GP-A).
    action def ConfirmExcessPersistenceFunction {
        doc
        /* FN-04: confirm that the flagged excess persists. The confirmation time is tbd. */
        in excessFlag : TorqueExcessFlag;
        out confirmedExcess : Boolean;
    }

    action def IssueSafeStateRequestFunction {
        doc
        /* FN-05: turn a confirmed excess into the safe state request. */
        in confirmedExcess : Boolean;
        out safeStateRequest : SafeStateRequest;
    }

    // UF-03 inner functions (GP-A).
    action def ForceSafeStateDemandFunction {
        doc
        /* FN-06: replace the torque demand by the safe state demand on a safe state request. The safe state value is tbd. */
        in safeStateRequest : SafeStateRequest;
        in demand : TorqueDemand;
        out safeDemand : TorqueDemand;
    }

    action def RaiseDriverWarningFunction {
        doc
        /* FN-07: raise the driver warning on a safe state request. */
        in safeStateRequest : SafeStateRequest;
        out warning : DashboardWarning;
    }

    // UF-04 inner functions (GP-B).
    action def ComparePedalChannelsFunction {
        doc
        /* FN-08: compare the redundant pedal channels PVS1 and PVS2 for a deviation. The deviation limit is tbd. */
        in pedalPosition : AccelerationPedalPosition;
        out channelDeviated : Boolean;
    }

    action def ConfirmPedalFaultFunction {
        doc
        /* FN-09: confirm a pedal channel deviation as a pedal sensor fault. The confirmation time is tbd. */
        in channelDeviated : Boolean;
        out pedalFault : PedalFaultStatus;
    }

    // UF-05 inner functions (GP-B).
    action def EvaluateLimpHomeConditionFunction {
        doc
        /* FN-10: decide from the pedal fault and the mode channel whether the limp home limit applies. */
        in pedalFault : PedalFaultStatus;
        in modeChannel : ModeChannel;
        out limpHomeActive : Boolean;
    }

    action def LimitTorqueDemandFunction {
        doc
        /* FN-11: limit the torque demand while the limp home limit applies. The limit value is the pilotAssumed catalog entry limpHomeTorqueLimit. */
        in limpHomeActive : Boolean;
        in demand : TorqueDemand;
        out limitedDemand : TorqueDemand;
    }

    // UF-08 inner functions (GP-A).
    action def CheckQnaAnswerFunction {
        doc
        /* FN-12: send a question to the function controller and check its answer. The cycle and the question count are the EGAS catalog entries qnaCycleMax and qnaQuestionCountMin. */
        in qnaAnswer : QnaAnswer;
        out qnaQuestion : QnaQuestion;
        out answerWrong : Boolean;
    }

    action def RequestShutOffFunction {
        doc
        /* FN-13: request the shut off when the answer is wrong. The confirmation rule is tbd. */
        in answerWrong : Boolean;
        out shutOffRequest : ShutOffRequest;
    }

    // White boxes: each UF input and output is bound to exactly one FN port.
    action torqueComparisonWb : TorqueComparisonFunction {
        action derivePermissibleTorque : DerivePermissibleTorqueFunction;
        action estimateActualTorque : EstimateActualTorqueFunction;
        action compareTorque : CompareTorqueFunction;
        bind pedalPosition = derivePermissibleTorque.pedalPosition;
        bind engineSensor = estimateActualTorque.engineSensor;
        flow derivePermissibleTorque.permissibleTorque to compareTorque.permissibleTorque;
        flow estimateActualTorque.actualTorque to compareTorque.actualTorque;
        bind compareTorque.excessFlag = excessFlag;
    }

    action excessConfirmationWb : ExcessConfirmationFunction {
        action confirmExcessPersistence : ConfirmExcessPersistenceFunction;
        action issueSafeStateRequest : IssueSafeStateRequestFunction;
        bind excessFlag = confirmExcessPersistence.excessFlag;
        flow confirmExcessPersistence.confirmedExcess to issueSafeStateRequest.confirmedExcess;
        bind issueSafeStateRequest.safeStateRequest = safeStateRequest;
    }

    action safeStateEnforcementWb : SafeStateEnforcementFunction {
        action forceSafeStateDemand : ForceSafeStateDemandFunction;
        action raiseDriverWarning : RaiseDriverWarningFunction;
        bind safeStateRequest = forceSafeStateDemand.safeStateRequest;
        bind safeStateRequest = raiseDriverWarning.safeStateRequest;
        bind demand = forceSafeStateDemand.demand;
        bind forceSafeStateDemand.safeDemand = safeDemand;
        bind raiseDriverWarning.warning = warning;
    }

    action pedalSensorFaultDetectionWb : PedalSensorFaultDetectionFunction {
        action comparePedalChannels : ComparePedalChannelsFunction;
        action confirmPedalFault : ConfirmPedalFaultFunction;
        bind pedalPosition = comparePedalChannels.pedalPosition;
        flow comparePedalChannels.channelDeviated to confirmPedalFault.channelDeviated;
        bind confirmPedalFault.pedalFault = pedalFault;
    }

    action limpHomeTorqueLimitWb : LimpHomeTorqueLimitFunction {
        action evaluateLimpHomeCondition : EvaluateLimpHomeConditionFunction;
        action limitTorqueDemand : LimitTorqueDemandFunction;
        bind pedalFault = evaluateLimpHomeCondition.pedalFault;
        bind modeChannel = evaluateLimpHomeCondition.modeChannel;
        flow evaluateLimpHomeCondition.limpHomeActive to limitTorqueDemand.limpHomeActive;
        bind demand = limitTorqueDemand.demand;
        bind limitTorqueDemand.limitedDemand = limitedDemand;
    }

    action controllerMonitoringWb : ControllerMonitoringFunction {
        action checkQnaAnswer : CheckQnaAnswerFunction;
        action requestShutOff : RequestShutOffFunction;
        bind qnaAnswer = checkQnaAnswer.qnaAnswer;
        bind checkQnaAnswer.qnaQuestion = qnaQuestion;
        flow checkQnaAnswer.answerWrong to requestShutOff.answerWrong;
        bind requestShutOff.shutOffRequest = shutOffRequest;
    }

    dependency uf01Decomposition
        from
            torqueComparisonWb::derivePermissibleTorque,
            torqueComparisonWb::estimateActualTorque,
            torqueComparisonWb::compareTorque
        to egasUf::torqueComparison;
    dependency uf02Decomposition
        from
            excessConfirmationWb::confirmExcessPersistence,
            excessConfirmationWb::issueSafeStateRequest
        to egasUf::excessConfirmation;
    dependency uf03Decomposition
        from
            safeStateEnforcementWb::forceSafeStateDemand,
            safeStateEnforcementWb::raiseDriverWarning
        to egasUf::safeStateEnforcement;
    dependency uf04Decomposition
        from
            pedalSensorFaultDetectionWb::comparePedalChannels,
            pedalSensorFaultDetectionWb::confirmPedalFault
        to egasUf::pedalSensorFaultDetection;
    dependency uf05Decomposition
        from
            limpHomeTorqueLimitWb::evaluateLimpHomeCondition,
            limpHomeTorqueLimitWb::limitTorqueDemand
        to egasUf::limpHomeTorqueLimit;
    dependency uf08Decomposition
        from
            controllerMonitoringWb::checkQnaAnswer,
            controllerMonitoringWb::requestShutOff
        to egasUf::controllerMonitoring;
} // package EgasArch_Fwb_Function
