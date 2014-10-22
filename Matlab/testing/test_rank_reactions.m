
load('U87mCADREInputs');
load('HR1_CbModel');
load('confidenceScores');
changeCobraSolver('glpk');

%% Test parse_gprs

% Test with different GPR types
display('## Testing parse_gprs with test reactions...');

none = 1; % 
iso = 25; % (1591)
or = 54; % (221) or (222)
and = 805; % (23657) and (6520)
zero = 1092; % (7299)
both = 1139; % (1892) or (3030) and (3032)
complex = 1140; % (549) or (3030) and (3032) or (1892)
complex_zero = 3634; % (3906) and (2683) or (8704) or (8704)

gprTest = [none, iso, or, and, zero, both, complex, complex_zero];
gprTestRxns = model.rxns(gprTest);
testModel = extractSubNetwork(model, gprTestRxns);

try
    [GPRrxns, GPRmat] = parse_gprs(testModel);
    display(['PASS...', ...
        'Function parse_gprs ran without error']);
catch err
    display(['FAIL...', ...
        'Function parse_gprs was terminated with the error:']);
    display(['> ', err.message]);
end
display('---');

% Check outputs with pre-defined expected result
display('## Checking output of parse_gprs for test reactions...');
    
if exist('GPRmat', 'var')
    
    testGPRmat = {'1591', ''; ... % iso
        '221', ''; '222', ''; ... % or
        '23657', '6520'; ... % and
        '7299', ''; ... % zero
        '1892', ''; '3030', '3032'; ... % both
        '549', ''; '3030', '3032'; '1892', ''; ... % complex
        '3906', '2683'; '8704', ''; '8704', ''}; % complex zero

    if sum(any(~strcmp(GPRmat, testGPRmat))) == 0
        display(['PASS...', ...
            'Function parse_gprs returns the expected result']);
    else
        display(['FAIL...', ...
            'Function parse_gprs returns unexpected result']);
    end
else
    display(['FAIL...', ...
        'Function parse_gprs encountered error, cannot check output']);
end
display('---');

%% Test map_high_conf_to_rxns

% Test with results from parse_gprs and high-confidence core from U87
display('## Testing map_high_conf_to_rxns...');

if exist('GPRmat', 'var')
    try
        is_C_H = map_high_conf_to_rxns(model, GPRmat, GPRrxns, C_H_genes);
        display(['PASS...', ...
            'Function map_high_conf_to_rxns ran without error']);
    catch err
        display(['FAIL...', ...
            'Function map_high_conf_to_rxns was terminated with the error:']);
        display(['> ', err.message]);
    end
else
    display(['FAIL...', ...
        'GPRmat missing, cannot check map_high_conf_to_rxns']);
end
display('---');

% Check outputs for small GPRmat
display('## Checking output of map_high_conf_to_rxns...');

if exist('is_C_H', 'var')
    if sum(is_C_H) == 2
        display(['PASS...', ...
            'Function map_high_conf_to_rxns returns the expected result']);
    else
        display(['FAIL...', ...
            'Function map_high_conf_to_rxns returns unexpected result']);
    end
else
    display(['FAIL...', ...
        'No output to check from function map_high_conf_to_rxns']);
end
display('---');


%% Test map_gene_scores_to_rxns

% Test with results from parse_gprs and ubiquity scores from U87 data
display('## Testing map_gene_scores_to_rxns...');

% Modify U for two genes, just to make things more interesting
U(strmatch('3030', G, 'exact')) = 0.5;
U(strmatch('1892', G, 'exact')) = 0.7;

if exist('GPRmat', 'var')
    try
        U_GPR = map_gene_scores_to_rxns(model, G, U, GPRmat);
        display(['PASS...', ...
            'Function map_gene_scores_to_rxns ran without error']);
    catch err
        display(['FAIL...', ...
            'Function map_gene_scores_to_rxns was terminated with the error:']);
        display(['> ', err.message]);
    end
else
    display(['FAIL...', ...
        'GPRmat missing, cannot check map_gene_scores_to_rxns']);
end
display('---');

% Check outputs for small U_GPR
display('## Checking output of map_gene_scores_to_rxns...');

if exist('U_GPR', 'var')
    
    % Create a matrix for testing U_GPR and make some adjustments so that outputs
    % match up as expected
    U_GPR_tmp = U_GPR;
    U_GPR_tmp(isnan(U_GPR)) = 500;
    is_Z = U_GPR_tmp == -1e-6;
    U_GPR_tmp = round(U_GPR_tmp * 1e4) / 1e4;
    U_GPR_tmp(is_Z) = -1e-6;

    testU_GPR = [0.1848, NaN; ... % iso
        0.6445, NaN; 0.0284, NaN; ... % or
        0.7062, 1.0000; ... % and
        -1e-6, NaN; ... % zero
        0.7000, NaN; 0.5000, 1.0000; ... % both
        1.0000, NaN; 0.5000, 1.0000; 0.7000, NaN; ... % complex
        -1e-6, 1.0000; 1.0000, NaN; 1.0000, NaN]; % complex zero
    testU_GPR(isnan(testU_GPR)) = 500;

    if sum(sum(U_GPR_tmp ~= testU_GPR)) == 0
        display(['PASS...', ...
            'Function map_gene_scores_to_rxns returns the expected result']);
    else
        display(['FAIL...', ...
            'Function map_gene_scores_to_rxns returns unexpected result']);
    end
else
    display(['FAIL...', ...
        'No output to check from function map_gene_scores_to_rxns']);
end
display('---');


%% Test calc_expr_evidence

% Test with results from map_gene_scores_to_rxns, no high-confidence core
display('## Testing calc_expr_evidence with no high-confidence core...');

no_C_H = false(size(model.rxns));

if exist('U_GPR', 'var')
    try
        E_X = calc_expr_evidence(model, GPRrxns, U_GPR, no_C_H);
        display(['PASS...', ...
            'Function calc_expr_evidence ran without error']);
    catch err
        display(['FAIL...', ...
            'Function calc_expr_evidence was terminated with the error:']);
        display(['> ', err.message]);
    end
else
    display(['FAIL...', ...
        'GPRmat missing, cannot check calc_expr_evidence']);
end
display('---');

% Check outputs for small U_GPR
display('## Checking output of calc_expr_evidence, no high-confidence core...');

if exist('E_X', 'var')
    
    E_X_GPR = E_X(gprTest);
    is_Z = E_X_GPR == -1e-6;
    E_X_GPR = round(E_X_GPR * 1e4) / 1e4;
    E_X_GPR(is_Z) = -1e-6;

    testE_X = [0; ...
        0.1848; ...
        0.6445; ...
        0.7062; ...
        -1e-6; ...
        0.7000; ...
        1.0000; ...
        1.0000];
    
    if sum(sum(E_X_GPR ~= testE_X)) == 0
        display(['PASS...', ...
            'Function calc_expr_evidence returns the expected result']);
    else
        display(['FAIL...', ...
            'Function calc_expr_evidence returns unexpected result']);
    end
else
    display(['FAIL...', ...
        'No output to check from function calc_expr_evidence']);
end
display('---');

% Test with results from map_gene_scores_to_rxns with high-confidence core
display('## Testing calc_expr_evidence with high-confidence core...');

if exist('U_GPR', 'var')
    try
        E_X = calc_expr_evidence(model, GPRrxns, U_GPR, is_C_H);
        display(['PASS...', ...
            'Function calc_expr_evidence ran without error']);
    catch err
        display(['FAIL...', ...
            'Function calc_expr_evidence was terminated with the error:']);
        display(['> ', err.message]);
    end
else
    display(['FAIL...', ...
        'GPRmat missing, cannot check calc_expr_evidence']);
end
display('---');

% Check outputs for small U_GPR
display('## Checking output of calc_expr_evidence, high-confidence core...');

if exist('E_X', 'var')
    
    E_X_GPR = E_X(gprTest);
    is_Z = E_X_GPR == -1e-6;
    E_X_GPR = round(E_X_GPR * 1e4) / 1e4;
    E_X_GPR(is_Z) = -1e-6;

    testE_X = [0; ...
        0.1848; ...
        0.6445; ...
        0.7062; ...
        -1e-6; ...
        1.0000; ...
        1.0000; ...
        1.0000];
    
    if sum(sum(E_X_GPR ~= testE_X)) == 0
        display(['PASS...', ...
            'Function calc_expr_evidence returns the expected result']);
    else
        display(['FAIL...', ...
            'Function calc_expr_evidence returns unexpected result']);
    end
else
    display(['FAIL...', ...
        'No output to check from function calc_expr_evidence']);
end
display('---');


%% Test inactive reaction removal step

% Test with results from map_gene_scores_to_rxns with high-confidence core
display('## Testing inactive reaction removal step...');

if exist('U_GPR', 'var')
    try
        E_X = calc_expr_evidence(model, GPRrxns, U_GPR, is_C_H);
        display(['PASS...', ...
            'Function calc_expr_evidence ran without error']);
    catch err
        display(['FAIL...', ...
            'Function calc_expr_evidence was terminated with the error:']);
        display(['> ', err.message]);
    end
else
    display(['FAIL...', ...
        'GPRmat missing, cannot check calc_expr_evidence']);
end
display('---');

% Check outputs for small U_GPR
display('## Checking output of calc_expr_evidence, high-confidence core...');

if exist('E_X', 'var')
    
    E_X_GPR = E_X(gprTest);
    is_Z = E_X_GPR == -1e-6;
    E_X_GPR = round(E_X_GPR * 1e4) / 1e4;
    E_X_GPR(is_Z) = -1e-6;

    testE_X = [0; ...
        0.1848; ...
        0.6445; ...
        0.7062; ...
        -1e-6; ...
        1.0000; ...
        1.0000; ...
        1.0000];
    
    if sum(sum(E_X_GPR ~= testE_X)) == 0
        display(['PASS...', ...
            'Function calc_expr_evidence returns the expected result']);
    else
        display(['FAIL...', ...
            'Function calc_expr_evidence returns unexpected result']);
    end
else
    display(['FAIL...', ...
        'No output to check from function calc_expr_evidence']);
end
display('---');

