function experimentEnd(keys, Results, scr, vars)
%function experimentEnd(keys, Results, scr, vars)

if vars.Aborted
    if isfield(scr, 'win')          % if a window is open, display a brief message
        % Abort screen
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, 'Experiment was aborted!', 'center', 'center', scr.TextColour);
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(0.5);
    end
    
    ListenChar(0);
    ShowCursor;
    sca;
    disp('Experiment aborted by user!');
    
    % Save, mark the run
    vars.DataFileName = ['Aborted_', vars.DataFileName];
    save(strcat(vars.OutputFolder, vars.DataFileName), 'Results', 'vars', 'scr', 'keys' );
    disp(['Run was aborted. Results were saved as: ', vars.DataFileName]);
    
    % and as .csv
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);

elseif vars.Error
    % Error
    vars.DataFileName = ['Error_',vars.DataFileName];
    save(strcat(vars.OutputFolder, vars.DataFileName), 'Results', 'vars', 'scr', 'keys' );
    % and as .csv
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);
    
    disp(['Run crashed. Results were saved as: ', vars.DataFileName]);
    disp(' ** Error!! ***')
    
    ListenChar(0);
    ShowCursor;
    sca; 
    
    % Output the error message that describes the error:
    psychrethrow(psychlasterror);
    
else % Successfull run
    % Show end screen and clean up
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, vars.InstructionEnd, 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(3);
    
    % Save the data
    save(strcat(vars.OutputFolder, vars.DataFileName), 'Results', 'vars', 'scr', 'keys' );
    disp(['Run complete. Results were saved as: ', vars.DataFileName]);
    
    % and as .csv
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);                                       %<----- PsiAdaptive: NOT SAVING .csv due to PF objects in Results struct#####
    
end

ListenChar(0);          % turn on keypresses -> command window
sca;
ShowCursor;
fclose('all');
Priority(0);