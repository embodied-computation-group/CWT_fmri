function [noThreshFlag, thresh] = getParticipantThreshold(subIDstring)
%function [noThreshFlag, thresh] = getParticipantThreshold(subIDstring)
%
% Project: CWT task, for fMRI
%
% For a given subject ID, goes into FAD_PsiAdaptive data folder and gets
% the participants threshold estimate
%
%
% Niia Nikolova
% Last edit: 06/07/2020


% subIDstring = '005';
noThreshFlag = 0;
dataFolder = ['..', filesep, 'FAD_pilot2_PSI', filesep, 'data', filesep];       % ####on aux: FADtask_2_Psi_MR

if strcmp(subIDstring, '999')   % if we're testing, set a default thresh
    thresh = 100;
    
else
    % Find files in folder
    searchString = ['*',subIDstring, '*'];
    dataSpec = [dataFolder, searchString];
    files = dir(dataSpec);
    
    if length(files) > 1        % if there are more than one files, ask experimenter to pick which one
        disp('More than one file found for this participant. Please select a file to use. ');
        cd(dataFolder);
        loadFile = uigetfile('*.mat', 'Select a .mat file to load.');
        thisFilePath = [dataFolder, filesep, loadFile];
    elseif length(files) == 1
        thisFilePath = [dataFolder, filesep, files(1).name];
    else                        % if there are no data files for this participant, set default threhsold
        ListenChar(0);          % turn on keyboard
        useDefaultThresh = input('No FAD task threshold found! Use default threshold of 50%? (Enter 1 for YES or 0 for NO ) ');
        
        if useDefaultThresh     % set default
            thresh = 100;
            return;
        else
            disp('You chose not to use a default threshold value. Get the participant to do the FAD thresholding task!!!');
            thresh = 0;
            noThreshFlag = 1;
            ShowCursor;
            
            return;
        end
    end
    
    thisFileResults = load(thisFilePath, 'stair');        % load struct
    dataWeCareAbout = thisFileResults.stair;
    
    %% ################### UPDATE HERE WHEN WE'VE COLLAPSED ACCROSS MALE & FEMALE FACES #############
    threshA = dataWeCareAbout.F.PM.threshold(end);
    threshB = dataWeCareAbout.M.PM.threshold(end);
    % % Print thresh & slope estimates
    % disp(['Threshold estimate, staircase A (lo start): ', num2str(threshA)]);
    % disp(['Slope estimate, staircase A (lo start): ', num2str(10.^dataWeCareAbout.F.PM.slope(end))]);         % PM.slope is in log10 units of beta parameter
    % disp(['Threshold estimate, staircase B (hi start): ', num2str(threshB)]);
    % disp(['Slope estimate, staircase B (hi start): ', num2str(10.^dataWeCareAbout.M.PM.slope(end))]);
    
    thresh = mean([threshA, threshB]);
    
end

disp(['Using threshold of: ', num2str(thresh)]);
ListenChar(0);                      % turn on keyboard
end