#!/usr/bin/env python3

import re
import sys
from pathlib import Path

test_id_mappings = {
    'SeigManagerV1_4Real.t.sol': {
        'test_v3Parameters': 'SM030',
        'test_v3MigrationState': 'SM050',
        'test_slashingParameters': 'SM035',
        'test_setStakedSeigFactor_basic': 'SM030',
        'test_setStakedSeigFactor_exceedsRAY_reverts': 'SM035',
        'test_setMaxChallengers_basic': 'SM030',
        'test_setMaxFraudProofCost_basic': 'SM030',
        'test_setValidatorReward_basic': 'SM030',
        'test_setValidatorReward_zeroAddress_reverts': 'SM035',
        'test_setStakedSeigFactor_notOwner_reverts': 'SM035',
        'test_setMaxChallengers_notOwner_reverts': 'SM035',
        'test_setMaxFraudProofCost_notOwner_reverts': 'SM035',
        'test_deployedContractsConnected': None,
        'test_validatorRewardConnected': None,
    },
    'RAT.t.sol': {
        'test_getDynamicMinimumCollateral': 'RAT010',
        'test_getCoffWithRelaxedCheck_relaxedMode': 'RAT012',
        'test_getCoffWithRelaxedCheck_strictMode': 'RAT013',
        'test_getDynamicCoff_withFormula': 'RAT011',
        'test_getDynamicCoff_withAttentionCost': 'RAT014',
        'test_getMinimumCollateralWithRelaxedCheck_relaxedMode': 'RAT012',
        'test_getMinimumCollateralWithRelaxedCheck_strictMode': 'RAT013',
        'test_registerValidator_success': 'RAT001',
        'test_registerValidator_insufficientDeposit': 'RAT002',
        'test_registerValidator_alreadyRegistered': 'RAT003',
        'test_registerMultipleValidators': 'RAT006',
        'test_deactivateValidator': 'RAT004',
        'test_triggerAttentionTest': 'RAT020',
        'test_triggerAttentionTest_noValidators': 'RAT022',
        'test_submitEvidence': 'RAT030',
        'test_getAttentionTestStatus_evidencePeriod': 'RAT040',
        'test_getAttentionTestStatus_challengePeriod': 'RAT041',
        'test_getAttentionTestStatus_slashed': 'RAT042',
        'test_getAttentionTestStatus_restoredByEvidence': 'RAT043',
        'test_withdrawSlashingsToTreasury': 'RAT050',
        'test_probabilisticTrigger': 'RAT021',
        'test_resolveClaim_duringChallengePeriod': 'RAT033',
        'test_resolveClaim_afterChallengePeriod_fails': 'RAT034',
        'test_relaxedValidatorCheck_true_removesAtCoff': 'RAT025',
        'test_relaxedValidatorCheck_false_removesAtDmin': 'RAT025',
        'test_relaxedValidatorCheck_false_keepAboveDmin': 'RAT025',
        'test_triggerAttentionTest_zeroCollateral': 'RAT026',
        'test_triggerAttentionTest_partialBond': 'RAT024',
        'test_submitEvidence_reactivatesValidator': 'RAT035',
        'test_submitEvidence_noReactivation_insufficientCollateral': 'RAT036',
        'test_resolveClaim_reactivatesValidator': 'RAT035',
        'test_reactivation_strictMode_Dmin': 'RAT035',
        'test_RAT007_maxValidators_exceeded_reverts': None,
        'test_RAT007_maxValidators_zeroMeansUnlimited': None,
        'test_RAT007_maxValidators_reregisterAfterDeactivation': None,
        'test_RAT052_treasury_zeroAddress_reverts': None,
        'test_RAT052_treasury_setAndWithdraw': None,
        'test_EDGE010_duplicateTrigger_sameBatch_reverts': None,
        'test_EDGE010_differentBatch_allowed': None,
        'test_EDGE022_withdrawExceedsBalance_reverts': None,
        'test_EDGE022_fullDeduction_noUnderflow': None,
        'test_E2E014_multipleL2_sameValidator': None,
        'test_E2E014_slashingOneL2_noAffectOther': None,
    }
}

def add_test_id_to_function(function_name, test_id):
    if test_id is None or function_name.startswith('test_' + test_id):
        return function_name
    
    if function_name.startswith('testFuzz_'):
        return f"testFuzz_{test_id}_{function_name[9:]}"
    else:
        return f"test_{test_id}_{function_name[5:]}"

def process_file(file_path, mappings):
    if not file_path.exists():
        print(f"File not found: {file_path}")
        return
    
    content = file_path.read_text()
    
    for old_name, test_id in mappings.items():
        new_name = add_test_id_to_function(old_name, test_id)
        if new_name != old_name:
            pattern = r'\bfunction\s+' + re.escape(old_name) + r'\s*\('
            replacement = f'function {new_name}('
            content = re.sub(pattern, replacement, content)
            print(f"  {old_name} -> {new_name}")
    
    file_path.write_text(content)
    print(f"Updated: {file_path}")

def main():
    test_dir = Path(__file__).parent.parent / 'test' / 'v3'
    
    for filename, mappings in test_id_mappings.items():
        file_path = test_dir / filename
        print(f"\nProcessing {filename}...")
        process_file(file_path, mappings)

if __name__ == '__main__':
    main()
