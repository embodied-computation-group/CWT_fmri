function [trialSequence, cueSequence, faceSequence, breaks] = setupCueProbabilities()
%[trialSequence, cueSequence, faceSequence, breaks] = function setupCueProbabilities()
%
% Project: CWT task, for fMRI.
% Sets up a squenece of blocks of cue probabilities given some parameters. NB that each block type must be presented an equal number of times
%
% Input:  none
%
% Output:
%   trialSequence [1, 2]     valid (Happy|cue_0) or invalid (Angry|cue_0) trial
%   cueSequence   [0, 1]     cue to be presented
%   faceSequence  [0, 1]     gender of face to be presented
%   breaks                   array or trial #s after which to pause the
%                            experiment
%
% Niia Nikolova
% Last edit: 09/07/2020             Shortened duration (now 210 trials)


% Set cue probablilities. vars.cueProbablitly = P(Happy|cue_0)
trialDuration       = [8, 10];                      % in sec (min 8, max 10)
probabilitiesHappy  = [0.25, 0.75];
NProbLevels         = length(probabilitiesHappy);   % + 0.5 for Non-predicitve blocks
NBlocks_long        = 2;
NBlocks_short       = 4;                            %6;
NBlocks             = NBlocks_long + NBlocks_short;
NBlocks_total       = NBlocks + (NBlocks-1);    % predicitve and unpredictive blocks
NGroups             = 2;                        % each group consists of 2x each of 2 prob levels
NTrialsTotal        = 210;%310;

cueBlockLength_shortP   = 20;% short predictive block, +/-jitter    || 24, total for 6* short blocks = 144
cueBlockLength_longP    = 40;% long predictive block, +/-jitter     || 48, total for 2* long blocks  = 96
cueBlockLength_U        = 10;% unpredictive block, +/-jitter        || 10, total for 5* U blocks     = 50
jitter                  = 4; %3

NBreaks                 = 1; % Number of breaks for the participant
breakAfterXTrials       = NTrialsTotal/(NBreaks+1);
breaks                  = [];

isThisBlockPredictive   = repmat([1, 0], 1, ((NBlocks_total-1)/2)+1);
blockLengths            = [];                       % master block length array for this sequence
trialSequence           = [];
effectiveBlockProbabilities = [];
desiredBlockProbabilities   = [];

cueSequence     = [];
faceSequence    = [];

%% Create arrays for P and U block lengths
blockLengthArray_longP = round(jitter_values(cueBlockLength_longP, jitter, jitter, NBlocks_long));
blockLengthArray_shortP = round(jitter_values(cueBlockLength_shortP, jitter, jitter, NBlocks_short));
blockLengthArray_U = round(jitter_values(cueBlockLength_U, jitter, jitter, (NBlocks-1)));

% check if we get the # of trials we expect, print expected duration
NTrialsCheck = sum(blockLengthArray_longP) + sum(blockLengthArray_shortP) + sum(blockLengthArray_U);
if NTrialsCheck ~= NTrialsTotal
    disp('Unexpected # of trials.'); end
expectedDurationMin = NTrialsCheck * trialDuration(1) / 60;
expectedDurationMax = NTrialsCheck * trialDuration(2) / 60;
disp(['Expected run duration at ', num2str(trialDuration(1)), 's/trial: ', num2str(expectedDurationMin), ' min.']);
disp(['Expected run duration at ', num2str(trialDuration(2)), 's/trial: ', num2str(expectedDurationMax), ' min.']);

%% Create array of Cue-Outcome probabilities per *predictive* block
% 1 long/highP, 2 long/lowP, 3 short/highP, 4 short/lowP   [P(Happy|cue_0)]
probabilitiesArray = [ones(1,NBlocks_long/2), 2*ones(1,NBlocks_long/2), 3*ones(1, NBlocks_short/2), 4*ones(1, NBlocks_short/2)];
probabilitiesArray = mixArray(probabilitiesArray);

% If we want to remove sequential duplicate blocks
for doThis = 1:2                        % Loop through twice
    for thisBlock = 1:NBlocks-1
        nextBlock = thisBlock + 1;
        Stim_1 = probabilitiesArray(thisBlock);
        Stim_2 = probabilitiesArray(nextBlock);
        
        % if two blocks are identical, move Stim_2 down and remove row
        if eq(Stim_1,Stim_2)
            if thisBlock == NBlocks-1   % If the last two block are the same, move the last one to 1st position
                probabilitiesArray = [Stim_2, probabilitiesArray];
                probabilitiesArray(nextBlock)=[];
            else                        % Otherwise move the duplicate block to the end
                probabilitiesArray = [probabilitiesArray, Stim_2];
                probabilitiesArray(nextBlock)=[];
            end
        end
    end
end

%% Create trials for each block
% create Block lengths array based on pobabilitiesArray
count_longB = 1;
count_shortB = 1;
count_unpredB = 1;
count_predLoop = 1;

for thisBlock = 1:NBlocks_total   
    
    if isThisBlockPredictive(thisBlock)
        
        switch probabilitiesArray(count_predLoop)
            case 1  % long, highP
                NTrialsInThisBlock = blockLengthArray_longP(count_longB);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(2);
                count_longB = count_longB + 1;
            case 2  % long, lowP
                NTrialsInThisBlock = blockLengthArray_longP(count_longB);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(1);
                count_longB = count_longB + 1;
            case 3  % short, highP
                NTrialsInThisBlock = blockLengthArray_shortP(count_shortB);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(2);
                count_shortB = count_shortB + 1;
            case 4  % short, lowP
                NTrialsInThisBlock = blockLengthArray_shortP(count_shortB);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(1);
                count_shortB = count_shortB + 1;
        end
        count_predLoop = count_predLoop + 1;
        
    else        % short, unpredictive
        NTrialsInThisBlock = blockLengthArray_U(count_unpredB);
        blockLengths = [blockLengths, NTrialsInThisBlock];
        pHappy = 0.5;
        count_unpredB = count_unpredB + 1;
    end
    
    % Generate the trials for this block & shuffle them
    % trialvector   [1]=valid trial (Happy|cue_0)        [2]=invalid trial (Angry|cue_0)
    [trialvector, real_probability] = create_trials(pHappy, blockLengths(thisBlock));
    trialvector = mixArray(trialvector);

    % Generate cues for this block & shuffle
    [cueVectorThisBlock, ~] = create_trials(0.5, NTrialsInThisBlock); 
    cueVectorThisBlock = mixArray(cueVectorThisBlock);                           
    cueVectorThisBlock(cueVectorThisBlock==2) = 0;      % change to [0 | 1]   
    
    % Generate face genders for this block & shuffle
    [faceVectorThisBlock, ~] = create_trials(0.5, NTrialsInThisBlock); 
    faceVectorThisBlock = mixArray(faceVectorThisBlock);                           
    faceVectorThisBlock(faceVectorThisBlock==2) = 0;    % change to [0 | 1]  
    
    % Add this block to the large sequence of trials for a while run
    trialSequence = [trialSequence, trialvector];
    effectiveBlockProbabilities = [effectiveBlockProbabilities, real_probability];
    desiredBlockProbabilities = [desiredBlockProbabilities, pHappy];
    cueSequence = [cueSequence, cueVectorThisBlock];
    faceSequence = [faceSequence, faceVectorThisBlock];
    
end

disp(['Number of trials in sequence: ', num2str(length(trialSequence))]);
disp(['Block lengths (nTrials): ', num2str(blockLengths)]);
disp(['Desired block probabilities: ', num2str(desiredBlockProbabilities)]);
disp(['Effective block probabilities: ', num2str(effectiveBlockProbabilities)]);

% Find & mark halfway point to place a break there              
for thisBlock = 1:NBlocks_total 
    trialsSoFar = sum(blockLengths(1:thisBlock));
    
    if mod(trialsSoFar, breakAfterXTrials) && (trialsSoFar ~= (length(trialSequence)))
        % Insert break after this block
        breaks = [breaks, trialsSoFar];
    end
end


%% Draw a little plot of the blocks in this sequence?


end