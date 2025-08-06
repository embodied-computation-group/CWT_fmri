%% Define parameters
%
% Project: CWT task, for fMRI
%
% Sets key parameters, called by main.m
%
% Niia Nikolova
% Last edit: 01/07/2020


%% Key flags
vars.ConfRating = 1;                                         % Confidence rating? (1 yes, 0 no)        
vars.InputDevice = 2;                                        % Response method for conf rating. 1 - keyboard 2 - mouse
useEyeLink = 0;                                              % Use EyeLink to record gaze & pupil?    

% Get current timestamp & set filename
startTime = clock;      
saveTime = [num2str(startTime(4)), '-', num2str(startTime(5))];
vars.DataFileName = strcat(vars.DataFileName, '_', date, '_', saveTime); 

%% Procedure
vars.NTrialsTotal = 310;
vars.NCatchTrials = 10;

%% Cueing
% Set temporal evolution of cue probablilities using
% setupCueProbabilities.m   P(Happy|Cue_0)

% Fetch trialSequence & cueSequence from saved file         % <---- ### Add get saved sequence from file ####
[trialSequence, cueSequence, faceSequence, breaks] = setupCueProbabilities();
vars.trialSequence = trialSequence;
vars.cueSequence = cueSequence;             % cb. sequence of cues [0|1]
vars.faceSequence = faceSequence;           % cb. sequence of face genders [0|1]
vars.breaks = breaks;                       % break AFTER this trial


%% Stimuli
vars.PMFptsForStimuli = .05;                % Percent below and above FAD threshold to use as Happy and Angry stimuli
vars.gaussNoiseVariance = 5;                % Variance for noise we want to add to the H and A face stimuli
morphValsJump = 200 * vars.PMFptsForStimuli;

% Calculate morphs to use
[vars.noThreshFlag, thresh] = getParticipantThreshold(vars.subIDstring);            % get the participants threshold
faceMorphsVals = [thresh - morphValsJump, thresh + morphValsJump];
vars.FaceMorphsPcnt = faceMorphsVals ./ 2;                          
meanFaceMorphs = round(faceMorphsVals);                                            % 1x2 array of 0-200 values, [angry, happy]
% Add gaussian noise
A_wnoise = ones(vars.NTrialsTotal/2, 2) .* meanFaceMorphs;
A_wnoise = A_wnoise + sqrt(vars.gaussNoiseVariance*2)*randn(size(A_wnoise));        % Ntrials/2 x 2 array, [angry, happy]
vars.FaceMorphs = round(A_wnoise);

% Add 50/50 catch trials
catchTrialStim = '100';
vars.catchTrialArray = [ones(1,vars.NCatchTrials/2), zeros(1,vars.NCatchTrials/2)];
vars.catchTrialArray = mixArray(vars.catchTrialArray);  % shuffle F and M face catch trials

% Faces
vars.TaskPath = fullfile('.', 'code', 'task');          
vars.StimFolder = fullfile('.', 'stimuli', filesep);
vars.StimSize = 9;                                      % DVA    (old 7, changed 07/07)                                  
vars.StimsInDir = dir([vars.StimFolder, '*.tif']);      % list contents of 'stimuli' folder    

% Cues                                 
vars.CuesInDir = dir([vars.StimFolder, '*.png']);      % list contents in 'stimuli' folder    


%% Task timing
vars.fixedTiming        = 0;    % Flag to force fixed timing for affect response & conf rating. 1 fixed, 0 self-paced
vars.RepeatMissedTrials = 0;
vars.CueT               = .5;
vars.StimT              = .5;   % sec
vars.RespT              = 2;    % sec
vars.ConfT              = 3;    % sec
vars.ISI_min            = 2;    % long variable ISI, 2-3 or 2-4 sec
vars.ISI_max            = 3; 
vars.ISI                = randInRange(vars.ISI_min, vars.ISI_max, [vars.NTrialsTotal,1]);
vars.ITI_min            = 1;    % short variable ITI 
vars.ITI_max            = 2; 
vars.ITI                = randInRange(vars.ITI_min, vars.ITI_max, [vars.NTrialsTotal,1]);
vars.breakT             = 60;   % sec

% Instructions
switch vars.ConfRating
    
    case 1
        
        switch vars.InputDevice
            
            case 1 % Keyboard
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n Then, rate how confident you are in your choice using the number keys. \n \n Unsure (1), Sure (2), and Very sure (3). \n \n The scan will begin soon...';
                vars.InstructionConf = 'Rate your confidence \n \n Unsure (1)     Sure (2)     Very sure (3)';

            case 2 % Mouse
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left button                         HAPPY - Right button \n \n \n \n Then, rate how confident you are in your choice using the mouse. \n \n Unsure (0), Sure (50), and Very sure (100). \n \n The scan will begin soon...';
                vars.InstructionConf = 'Rate your confidence using the trackball. Left click to confirm.';
                vars.ConfEndPoins = {'0', '100'};
        end
    case 0
        switch vars.InputDevice
            
            case 1 % Keyboard
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n The scan will begin soon...';
            case 2 % Mouse
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left button                         HAPPY - Right button \n \n \n \n The scan will begin soon...';
        end
end
vars.InstructionQ = 'Angry (L)     or     Happy (R)';
vars.InstructionPause = 'Take a short break... \n \n The experiment will continue in ...';
vars.InstructionEnd = 'You have completed the session. Thank you!';





% ------------------------ TRY TO UPDATE STAIRCASE IN CWT OR REMOVE--------------------------------------
% %% MCS task: do some randomising of the stimulus order and, remove sequential duplicates
% switch vars.Procedure
%     
%     case 1 % 1 - Psi method adaptive   
%         
%         % Interleave M & F face staircases                  <--- change to High and Low start staircases (collapsed accross gender)                           
%         vars.stairSwitch = [zeros(stair.NumTrials, 1); ones(stair.NumTrials, 1)];
%         randomorder = randperm(length(vars.stairSwitch));
%         vars.stairSwitch = vars.stairSwitch(randomorder);
%         
%         
%     case 2 % 2 - N-down staircase
%         
%         % Interleave 4 staircases (F-low, F-high, M-low, M-high)
%         vars.stairSwitch = [zeros(vars.NumTrials, 1); ones(vars.NumTrials, 1); (ones(vars.NumTrials, 1)).*2 ;  (ones(vars.NumTrials, 1)).*3];
%         randomorder = randperm(length(vars.stairSwitch));
%         vars.stairSwitch = vars.stairSwitch(randomorder);
%         
%         
%     case 3 % 3 - Method of Constant Stimuli (used in Pilot 1)
%         
%         % Generate repeating list - string array with filenames & remove
%         % sequential duplicate stimuli
%         vars.StimList = strings(length(vars.StimsInDir),1);
%         for thisStim = 1:length(vars.StimsInDir)
%             vars.StimList(thisStim) = getfield(vars.StimsInDir(thisStim), 'name');
%         end
%         StimTrialList = repmat(vars.StimList,vars.NTrials,1);
%         
%         % Randomize order of stimuli & move sequential duplicates
%         ntrials = length(StimTrialList);
%         randomorder = randperm(length(StimTrialList));             % Shuffle 
%         vars.StimTrialList = StimTrialList(randomorder);
%         
%         for thisStim = 1:ntrials-1
%             nextStim = thisStim+1;
%             Stim_1 = vars.StimTrialList(thisStim);
%             Stim_2 = vars.StimTrialList(nextStim);
%             
%             % if two stim names are identical, move Stim_2 down and remove row
%             if strcmp(Stim_1,Stim_2)
%                 vars.StimTrialList = [vars.StimTrialList; Stim_2];
%                 vars.StimTrialList(nextStim)=[];
%             end
%             
%         end
% end
