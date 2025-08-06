function main(vars, scr)
%function main(vars, scr)
%
% Project: CWT task, for fMRI
%
% Main experimental script. Waits for scanner trigger (5%) to start.
%
% Presents a cue, followed by a face, then queries whether the face was
% perceived as Happy or Angry, and Confidence. Face gender and affect are
% balanced accross probabilistic blocks.
%
% Happy and angry face morphs used are determined by the participants PMF,
% eg. morph at 30% & 70% happy response.
%
% Input:
%   vars        struct with key parameters (most are deifne in loadParams.m)
%   scr         struct with screen / display settings
%
%
% 16.06.2020        NN added useEyeLink flag to allow gaze recording
% 22.06.2020        NN adding cueing task, removed thresholding procedures
% 01.07.2020        NN updated to take cue & face stimulus on each trial
%                   from sequence set up by setupCueProbabilities          
%                   ### change to read in from saved file ###
%                   ### Add command line indication for which block we're
%                   in & a break around the middle (after a Pred block)###
%
% Niia Nikolova
% Last edit: 02/07/2020


% Load the parameters
loadParams;

% Results struct
DummyDouble = ones(vars.NTrialsTotal,1).*NaN;
DummyString = strings(vars.NTrialsTotal,1);
Results = struct('trialN',{DummyDouble},'EmoResp',{DummyDouble}, 'ConfResp', {DummyDouble},...
    'EmoRT',{DummyDouble}, 'ConfRT', {DummyDouble},'trialSuccess', {DummyDouble}, 'StimFile', {DummyString},...
    'MorphLevel', {DummyDouble}, 'Indiv', {DummyString}, 'SubID', {DummyDouble}, 'Cue', {DummyDouble}, 'CueProb',...
    {DummyDouble}, 'Triggers', {DummyDouble}, 'SOT_trial', {DummyDouble}, 'SOT_cue', {DummyDouble},...
    'SOT_ISI', {DummyDouble}, 'SOT_face', {DummyDouble}, 'SOT_EmoResp', {DummyDouble}, 'SOT_ConfResp', {DummyDouble},...
    'SOT_ITI', {DummyDouble}, 'TrialDuration', {DummyDouble});
% trialN 
% EmoResp 
% ConfResp
% EmoRT 
% ConfRT 
% trialSuccess 
% StimFile
% MorphLevel
% Indiv            M or F for PsiAdaptive
% subID
% Cue              1 or 2
% CueProb          Probability of this cue predicting Happy
% Triggers 
% SOT_trial 
% SOT_cue 
% SOT_ISI
% SOT_face
% SOT_EmoResp       #### Response screen onset OR Response time ??? #####
% SOT_ConfResp      #### Response screen onset OR Response time ??? #####
% SOT_ITI
% TrialDuration

% Diplay configuration
[scr] = displayConfig(scr);

% Keyboard & keys configuration
[keys] = keyConfig();

% Reseed the random-number generator
SetupRand;

% If this participant does not have a FAD threshold, and we want to abort
if vars.noThreshFlag    
    disp('Terminating CWT task.');
    vars.RunSuccessfull = 0;
    vars.Aborted = 1;
    experimentEnd(keys, Results, scr, vars);
    return
end

%% Prepare to start
AssertOpenGL;       % OpenGL? Else, abort

try
    %% Open screen window
    [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
    PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
    % Set text size, dependent on screen resolution
    if any(logical(scr.winRect(:)>3000))       % 4K resolution
        scr.TextSize = 65;
    else
        scr.TextSize = 28;
    end
    Screen('TextSize', scr.win, scr.TextSize);
    
    % Set priority for script execution to realtime priority:
    scr.priorityLevel = MaxPriority(scr.win);
    Priority(scr.priorityLevel);
    
    % Determine stim size in pixels
    scr.dist = scr.ViewDist;
    scr.width  = scr.MonitorWidth;
    scr.resolution = scr.winRect(3);                    % number of pixels of display in horizontal direction
    StimSizePix = angle2pix(scr, vars.StimSize);
    
    % Dummy calls to prevent delays
    vars.ValidTrial = zeros(1,2);
    vars.RunSuccessfull = 0;
    vars.Aborted = 0;
    vars.Error = 0;
    WaitSecs(0.1);
    GetSecs;
    vars.Resp = 888;
    vars.ConfResp = 888;
    vars.abortFlag = 0;
    WaitSecs(0.500);
    [~, ~, keys.KeyCode] = KbCheck;
    
    %% Initialise EyeLink
    if useEyeLink
        vars.EyeLink = 1;
        
        % check for eyelink data dir
        if ~exist('./data/eyelink', 'dir')
            mkdir('./data/eyelink')
        end
        
        [vars] = ELsetup(scr, vars);
    end
    
    tic
    
    %% Show task instructions
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, [vars.InstructionTask], 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    
    % Wait for trigger
    while keys.KeyCode(keys.Trigger) == 0
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
    end
    Results.SessionStartT = GetSecs;            % session start = trigger 1
    
    if useEyeLink
        Eyelink('message','STARTEXP');
    end
    
    %% Run through trials
    WaitSecs(0.500);            % pause before experiment start
    thisTrial = 1;              % trial counter
    happyCounter = 1;
    angryCounter = 1;
    endOfExpt = 0;
    
    while endOfExpt ~= 1       % General stop flag for the loop
        
        Results.SOT_trial(thisTrial) = GetSecs - Results.SessionStartT;
        if useEyeLink
            % EyeLink:  this trial
            startStimText = ['Trial ' num2str(thisTrial) ' start'];
            Eyelink('message', startStimText);
        end
        
        %% Present cue
        thisCue = vars.cueSequence(thisTrial);
        thisTrialCue = ['cue_', num2str(thisCue), '.png'];
        disp(['Trial # ', num2str(thisTrial), '. Cue: ', thisTrialCue]);
        
        % Read stim image for this trial into matrix 'imdata'
        CueFilePath = strcat(vars.StimFolder, thisTrialCue);
        ImDataOrig = imread(char(CueFilePath));
        ImData = imresize(ImDataOrig, [StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
        % <--- SHOULD SIZE BE DIFFERENT FOR CUE? ###
        
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        Screen('DrawTexture', scr.win, ImTex);
        [~, CueOn] = Screen('Flip', scr.win);

        Results.SOT_cue(thisTrial) = GetSecs - Results.SessionStartT;
        if useEyeLink
            % EyeLink:  cue on
            startStimText = ['Trial ' num2str(thisTrial) ' cue on'];
            Eyelink('message', startStimText);
        end
        
        % While loop to show stimulus until CueT seconds elapsed.
        while (GetSecs - CueOn) <= vars.CueT
            
            % KbCheck for Esc key
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
            
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end
        
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        if useEyeLink
            % EyeLink:  cue off
            startStimText = ['Trial ' num2str(thisTrial) ' cue off'];
            Eyelink('message', startStimText);
        end
        Screen('Close', ImTex);                      % Close the image texture
        
        %% ISI
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);     % <---- ### ADD A FIXATION CROSS? ###
        [~, StartITI] = Screen('Flip', scr.win);
        
        Results.SOT_ISI(thisTrial) = GetSecs - Results.SessionStartT;
        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' jitter start'];
            Eyelink('message', startStimText);
        end
        
        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ISI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        %% Present face stimulus
        switch vars.trialSequence(thisTrial)
            case 1                                              % Valid trial (Happy|cue_0)
                if thisCue      % cue_1
                    thisTrialStim = 0;      % 0 = angry face
                else            % cue_0
                    thisTrialStim = 1;      % 1 = happy face
                end
                
            case 2                                              % Invalid trial (Angry|cue_0)
                if thisCue      % cue_1
                    thisTrialStim = 1;      % 1 = happy face
                else            % cue_0
                    thisTrialStim = 0;      % 0 = angry face
                end
        end
        
        % #### CHANGE HERE AFTER F AND M ARE COLLAPSED ####
        if vars.faceSequence(thisTrial)     % 1 female
            thisFaceGender = 'F_';
        else                                % 0 male
            thisFaceGender = 'M_';
        end
        
        if thisTrialStim                    % Happy
            thisFaceAffect = vars.FaceMorphs(happyCounter, 2);
            happyCounter = happyCounter + 1;
        else                                % Angry
            thisFaceAffect = vars.FaceMorphs(angryCounter, 1);
            angryCounter = angryCounter + 1;
        end
        
        % Preassigned equal #s of M and F faces per block
        thisTrialFileName = [thisFaceGender, sprintf('%03d', thisFaceAffect), '.tif'];
        
        
        %         % #################################################################
        %         % #### TEMP - just one stimulus for development ####
        %         thisTrialStim = 130;            % double 0-200
        %         thisTrialFileName = ['F_', sprintf('%03d', thisTrialStim), '.tif'];
        %         % #################################################################
        
        disp(['Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
        % Read stim image for this trial into matrix 'imdata'
        StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
        ImDataOrig = imread(char(StimFilePath));
        StimFileName = thisTrialFileName;
        ImData = imresize(ImDataOrig, [StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
        
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        Screen('DrawTexture', scr.win, ImTex);
        [~, StimOn] = Screen('Flip', scr.win);
        
        Results.SOT_face(thisTrial) = GetSecs - Results.SessionStartT;
        if useEyeLink
            % EyeLink:  face on
            startStimText = ['Trial ' num2str(thisTrial) ' face stim on'];
            Eyelink('message', startStimText);
        end
        
        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT
            
            % KbCheck for Esc key
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
            
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end
        
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        if useEyeLink
            % EyeLink:  face off
            startStimText = ['Trial ' num2str(thisTrial) ' face stim off'];
            Eyelink('message', startStimText);
        end
        
        %% Show emotion prompt screen
        % Angry (L arrow) or Happy (R arrow)?
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
        
        [~, vars.StartRT] = Screen('Flip', scr.win);
        
        if useEyeLink
            % EyeLink:  face response
            startStimText = ['Trial ' num2str(thisTrial) ' face response screen on'];
            Eyelink('message', startStimText);
        end
        
        % Fetch the participant's response, via keyboard or mouse
        [vars] = getResponse(keys, scr, vars);
        
        Results.SOT_EmoResp(thisTrial) = vars.EndRT - Results.SessionStartT;
        
        if vars.abortFlag               % Esc was pressed
            Results.EmoResp(thisTrial) = 9;
            % Save, mark the run
            vars.RunSuccessfull = 0;
            vars.Aborted = 1;
            experimentEnd(keys, Results, scr, vars);
            return
        end
        
        % Time to stop? (max # trials reached)
        if (thisTrial == vars.NTrialsTotal)
            endOfExpt = 1;
        end
        
        % Compute response time
        RT = (vars.EndRT - vars.StartRT);
        
        % Write trial result to file
        Results.EmoResp(thisTrial) = vars.Resp;
        Results.EmoRT(thisTrial) = RT;
        
        
        %% Confidence rating
        if vars.ConfRating
            
            if useEyeLink
                % EyeLink:  conf rating
                startStimText = ['Trial ' num2str(thisTrial) ' confidence screen on'];
                Eyelink('message', startStimText);
            end
            
            % Fetch the participant's confidence rating
            [vars] = getConfidence(keys, scr, vars);
            Results.SOT_ConfResp(thisTrial) = vars.ConfRatingT - Results.SessionStartT;     % <-----  CHECK THAT THIS TIME IS CORRECT
            
            if vars.abortFlag       % Esc was pressed
                Results.ConfResp(thisTrial) = 9;
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
            
            % If this trial was successfull, move on...
            if(vars.ValidTrial(2)), WaitSecs(0.2); end
            
            % Write trial result to file
            Results.ConfResp(thisTrial) = vars.ConfResp;
            Results.ConfRT(thisTrial) = vars.ConfRatingT;
            
            % Was this a successfull trial? (both emotion and confidence rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial) == 2);
            
        else % no Confidence rating
            
            % Was this a successfull trial? (emotion rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial) == 1);
            
        end
        
        %% Update Results
        Results.trialN(thisTrial) = thisTrial;
        Results.StimFile(thisTrial) = StimFileName;
        Results.SubID(thisTrial) = vars.subNo;
        Results.Indiv(thisTrial) = StimFileName(1);
        Results.MorphLevel(thisTrial) = str2double(StimFileName(3:5));
        Results.Cue(thisTrial) = vars.cueSequence(thisTrial);
        
        %% ITI / prepare for next trial
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);       % <---- ### ADD A FIXATION CROSS? ###
        [~, StartITI] = Screen('Flip', scr.win);
        
        Results.SOT_ITI(thisTrial) = GetSecs - Results.SessionStartT;
        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' ITI start'];
            Eyelink('message', startStimText);
        end
        
        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ITI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        Results.TrialDuration(thisTrial) = GetSecs - Results.SOT_trial(thisTrial);
        
        
        % If the trial was missed, repeat it or go on...
        if vars.RepeatMissedTrials
            % if this was a valid trial, advance one. Else, repeat it.
            if vars.ValidTrial(1)            % face affect rating
                thisTrial = thisTrial + 1;
            else
                disp('Invalid response. Repeating trial.');
                % Repeat the trial...
            end
        else
            % Advance one trial (always in MR)
            thisTrial = thisTrial + 1;
        end
        
        
        % Reset Texture, ValidTrial, Resp
        vars.ValidTrial = zeros(1,2);
        vars.Resp = NaN;
        vars.ConfResp = NaN;
        Screen('Close', ImTex);
        
        if useEyeLink
            % EyeLink:  trial end
            startStimText = ['Trial ' num2str(thisTrial) ' end'];
            Eyelink('message', startStimText);
        end
        
        %% Should we have a break here?
        if thisTrial == vars.breaks(1)   % <---- vars.breaks has many elements FIX! ###
            % Gray screen - Take a short break
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            DrawFormattedText(scr.win, vars.InstructionPause, 'center', 'center', scr.TextColour);
            [~, breakStartsNow] = Screen('Flip', scr.win);
            
            % wait for vars.breakT seconds
            while (GetSecs - breakStartsNow) <= vars.breakT
                % Draw time remaining on the screen               
                breakRemaining = vars.breakT - (GetSecs - breakStartsNow);
                breakRemainingString = [num2str(round(breakRemaining)), ' seconds'];
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                DrawFormattedText(scr.win, vars.InstructionPause, 'center', 'center', scr.TextColour);
                DrawFormattedText(scr.win, breakRemainingString, 'center', ((scr.winRect(4)/2)+200), scr.TextColour);
                [~, ~] = Screen('Flip', scr.win);
                WaitSecs(1);  
                
            end
            
            % Get ready to continue...
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            DrawFormattedText(scr.win, ['The experiment will now continue, get ready.'], 'center', 'center', scr.TextColour);
            [~, ~] = Screen('Flip', scr.win);
            WaitSecs(3);
            
        end
        
    end%thisTrial
    
    vars.RunSuccessfull = 1;
    Results.SessionEndT = GetSecs - Results.SessionStartT;
    
    % Save, mark the run
    experimentEnd(keys, Results, scr, vars);
    
    toc
    
    %% EyeLink: experiment end
    if useEyeLink
        ELshutdown(vars)
    end
    
    % Cleanup at end of experiment - Close window, show mouse cursor, close
    % result file, switch back to priority 0
    sca;
    ShowCursor;
    fclose('all');
    Priority(0);
    
    
catch % Error. Clean up...
    
    % Save, mark the run
    
    vars.RunSuccessfull = 0;
    vars.Error = 1;
    experimentEnd(keys, Results, scr, vars);
    
end
