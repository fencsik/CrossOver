function Crossover

% Crossover
%
% Authors: David E. Fencsik

% 2010-06 revision to manipulate stim-sets within block
% Todo:
%  - Revise staircase code
%  - Output data
%  - Palmer-style setsize manipulation: show all stim with precue
%  - Fix pedestal/stim size (stim are currently too big)
%  - Cleanup keypress handling
%  - Test

    experiment = 'Test01';
    Version = '0.6';

    % get user input
    [subject, practiceBlock, praTrials, expTrials] = ...
        DialogBox(sprintf('%s Parameters', experiment), ...
                  'Subject:', 'xxx', 0, ...
                  'Practice block? (1 = yes)', '0', 1, ...
                  'No. of practice trials', '8', 1, ...
                  'Exp trials per cell', '2', 1);

    %% Set any remaining parameters
    subject = 'def';
    stimSetList = [2 7];
    expTrials = 2;
    praTrials = 0;
    targetList = 1; %[0 1];
    setSizeList = [4];
    noiseLevelList = [.5 .25 .75];

    % staircase parameters
    staircaseFlag = 0;
    nStaircaseTracks = 1;
    nReversals = 20;
    nReversalsDropped = 10;
    staircaseStart = 0.5;
    staircaseSteps = [-0.1, 0.025]; % Error, Correct
    staircaseRange = [0 1];

    % control how stimuli are presented and cued
    pedestalFlag    = 1; % 0 = no pedestals, 1 = pedestals
    pedestalShape   = 2; % 1 = square, 2 = circle
    precueFlag      = 0; % 0 = none, 1 = square, 2 = arc
    allstimFlag     = 0; % 0 = only show S stim, 1 = always fill all cue locations
    balanceFlag     = 0; % 0 = random stim locations, 1 = balanced L-R locations
    noiseType       = 1; % 0 = whole display, 1 = per cell, 2 = just stimuli
    maskFlag        = 0; % 0 = none, 1 = mask only stim, 2 = mask all cells, 3 = mask whole display

    % define timings (sec)
    durPreTrial   = 0.745;
    durFixation   = 0.745;
    durSSCues     = 0.080;
    durPostSSCues = 0.240;
    durStim       = 0.500;
    durISI        = 0.080;
    durFeedback   = 0.745;
    durPostTrial  = 0.745;

    % stimulus set-up
    % Note: distance -> pixel sizes (17 in. monitor, 1024x768 resolution)
    % 106 cm -> 60.14 pix/deg --- 105 cm -> 59.58 pix/deg
    %  89 cm -> 50.50 pix/deg ---  88 cm -> 49.93 pix/deg
    %  53 cm -> 30.07 pix/deg ---  52 cm -> 29.50 pix/deg
    nStimCells = 8;
    pedestalRadius = 256;
    pedestalSize = 128; % make sure pedestalSize - stimulusSize >= 0 and is even
    stimSize = 100;
    stimWidth = 20;

    % response set-up
    response0 = 227;   % 'LeftGUI'  == left Apple-key
    response1 = 231;   % 'RightGUI' == right Apple-key
    respUp3 = 228;     % RightControl
    respUp2 = 230;     % RightAlt
    respUp1 = 231;     % RightGUI
    respDown1 = 227;   % LeftGUI
    respDown2 = 226;   % LeftAlt
    respDown3 = 224;   % LeftControl
    respQuit = 41;     % ESCAPE
                       % response0 = 4;  % 'a'  == "a" key
                       % response1 = 52; % ''"' == quote key
    allowedResponses = [response0 response1];

    % stimulus presentation modes
    mdDetect = 1; % target present on half of trials, remaining stim are distractors
    mdIdentify = 2; % two target classes, one present on every trial, remaining are distractors

    % misc set-up
    rand('twister', 100 * sum(clock));
    dataFileName = sprintf('%sData-%s.txt', experiment, subject);
    [status, result] = system('echo $HOSTNAME');
    if status == 0
        computer = strtok(result, '.');
        computer = computer(isletter(computer)); % remove any spaces or newlines
    else
        computer = 'unknown';
    end
    blocktime = now;
    sndBeep = MakeBeep(880, .1);
    sndClick = MakeBeep(1000, .01);

    % system tests
    if exist('IsOSX') ~= 2 || ~IsOSX
        error('%s can only be run in OSX versions of Psychtoolbox', mfilename);
    end
    AssertOpenGL;

    try
        % Open main window, double-buffered fullscreen window
        Screen('Preference', 'SkipSyncTests', 0);
        Screen('Preference', 'VisualDebugLevel', 4);
        screenNumber=max(Screen('Screens'));
        [winMain, rectMain] = Screen('OpenWindow', screenNumber, 0, [], 32, 2);
        refreshDuration = Screen('GetFlipInterval', winMain);
        Screen(winMain, 'BlendFunction', GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        [centerX, centerY] = RectCenter(rectMain);

        HideCursor;
        Snd('Play', sndBeep);

        % Some window set-up
        Screen('TextFont', winMain, 'Monaco');
        Screen('TextSize', winMain, 18);
        Screen('TextStyle', winMain, 1); % 0=normal, 1=bold, 2=italic, 4=underlined, 8=outline

        % Define colors
        colWhite = WhiteIndex(winMain);
        colBlack = BlackIndex(winMain);
        colGray = GrayIndex(winMain);
        colLightGray = round( (colWhite + colGray) / 2 ) + 1;
        colDarkGray = round( (colBlack + colGray) / 2 );
        colRed = [255 0 0];
        colBlue = [0 0 255];
        colGreen = [0 150 0];
        colYellow = [255 255 0];
        colForeground = colBlack;
        colBackground = colLightGray;
        colFrame = colBackground;
        colPedestal = colGray;
        colFixation = colRed;
        colStim = [170 170 170];

        % other rects
        rectFixation = CenterRect([0 0 6 6], rectMain);

        % blank screen and issue wait notice
        Screen('FillRect', winMain, colBackground);
        CenterText(winMain, 'Please wait...', colForeground);
        Screen('Flip', winMain);

        % Generate stimuli
        bg = colBackground;
        if numel(bg) == 1
            bg = repmat(bg, 1, 3);
        end
        edgeOffset = round((pedestalSize - stimSize) / 2); % distance from edge of pedestal to edge of stimulus
        middle = ceil(pedestalSize / 2); % middle of the pedestal
        stimRadius = stimWidth / 2; % distance from stimulus edge to its middle
        nStimSets = numel(stimSetList);
        stim = struct('texT', cell(1, nStimSets), ...
                      'texD', cell(1, nStimSets), ...
                      'angleT', cell(1, nStimSets), ...
                      'angleD', cell(1, nStimSets), ...
                      'mode', cell(1, nStimSets), ...
                      'resp', cell(1, nStimSets));
        for i = 1:nStimSets
            switch stimSetList(i)
              case 2
                % orientation
                mat = repmat(0, [pedestalSize, pedestalSize, 4]);
                mat(edgeOffset+1:pedestalSize-edgeOffset, ...
                    middle-stimRadius+1:middle+stimRadius, :) = ...
                    repmat(reshape([colStim 255], 1, 1, 4), ...
                           [stimSize, stimWidth, 1]);
                stim(i).texT = Screen('MakeTexture', winMain, mat);
                stim(i).texD = stim(i).texT;
                stim(i).angleT = 20;
                stim(i).angleD = 0;
                stim(i).mode = mdDetect;
                stim(i).response = {'absent', 'present'};
                clear mat;
              case 7
                %%% 2 vs. 5
                % generate basic components
                col = reshape([colStim 255], 1, 1, 4);
                hbar = repmat(col, [stimWidth, stimSize, 1]);
                vbar = repmat(col, [middle - edgeOffset,  stimWidth, 1]);
                % generate common horizontal lines
                mat = repmat(0, [pedestalSize, pedestalSize, 4]);
                mat(edgeOffset+1:edgeOffset+stimWidth, ...
                    edgeOffset+1:pedestalSize-edgeOffset, :) = hbar;
                mat(middle-stimRadius+1:middle+stimRadius, ...
                    edgeOffset+1:pedestalSize-edgeOffset, :) = hbar;
                mat(pedestalSize-edgeOffset-stimWidth+1:...
                    pedestalSize-edgeOffset, ...
                    edgeOffset+1:pedestalSize-edgeOffset, :) = hbar;
                % generate 2
                mat2 = mat;
                mat2(edgeOffset+1:middle, ...
                     pedestalSize-edgeOffset-stimWidth+1:...
                     pedestalSize-edgeOffset, :) = vbar;
                mat2(middle+1:pedestalSize-edgeOffset, ...
                     edgeOffset+1:edgeOffset+stimWidth, :) = vbar;
                stim(i).texT = Screen('MakeTexture', winMain, mat2);
                stim(i).angleT = 0;
                % generate 5
                mat5 = mat;
                mat5(edgeOffset+1:middle, ...
                     edgeOffset+1:edgeOffset+stimWidth, :) = vbar;
                mat5(middle+1:pedestalSize-edgeOffset, ...
                     pedestalSize-edgeOffset-stimWidth+1:...
                     pedestalSize-edgeOffset, :) = vbar;
                stim(i).texD = Screen('MakeTexture', winMain, mat5);
                stim(i).angleD = 0;
                % miscellaneous
                stim(i).mode = mdDetect;
                stim(i).response = {'absent', 'present'};
                clear mat mat2 mat5;
              otherwise
                error('stimulus set %d does not exist', stimSetList(i));
            end
        end

        % define stimulus presentation cells
        expansionFactor = 1.0;
        rectPedestal = [0 0 pedestalSize pedestalSize];
        stimCells = zeros(nStimCells, 4);
        for n = 1:nStimCells
            stimCells(n, :) = CenterRectOnPoint(rectPedestal, ...
                                                centerX + round(pedestalRadius * sin((n - 1) * 2 * pi / nStimCells)), ...
                                                centerY + round(pedestalRadius * cos((n - 1) * 2 * pi / nStimCells)));
        end

        % compute square rect needed to contain all stimulus cells
        extraRadius = ceil( sqrt( (.5 * RectWidth(stimCells(1, :)))^2 + (.5 * RectHeight(stimCells(1, :)))^2 ) );
        stimAreaDiameter = ceil(2 * expansionFactor * (pedestalRadius + extraRadius));
        rectDisplay = CenterRect([0 0 stimAreaDiameter stimAreaDiameter], rectMain);

        % draw a sample of the display area
        Screen('FillRect', winMain, colBackground);
        Screen('FillOval', winMain, colFixation, rectFixation);
        for n = 1:nStimCells
            Screen('FillRect', winMain, colForeground, stimCells(n, :));
            Screen('DrawText', winMain, sprintf('%d', n), stimCells(n, RectLeft) + 30, stimCells(n, RectBottom) - 50, colBackground);
        end
        Screen('FrameOval', winMain, colRed, rectDisplay);
        Screen('Flip', winMain);
        WaitSecs(.25);

        % draw a sample of task stimuli
        Screen('FillRect', winMain, colBackground);
        Screen('FillOval', winMain, colFixation, rectFixation);
        for n = 1:nStimCells
            i = Randi(nStimSets);
            if (Randi(2) == 1)
                j = Randi(numel(stim(i).texT));
                tex = stim(i).texT(j);
                angle = stim(i).angleT(j);
            else
                j = Randi(numel(stim(i).texD));
                tex = stim(i).texD(j);
                angle = stim(i).angleD(j);
            end
            Screen('FillRect', winMain, colForeground, stimCells(n, :));
            Screen('DrawTexture', winMain, tex, [], stimCells(n, :), angle);
        end
        Screen('FrameOval', winMain, colRed, rectDisplay);
        Screen('Flip', winMain);
        WaitSecs(.25);

        % define matrices for alpha channel of noise fields, to restrict their shape
        if noiseType == 1 || noiseType == 2
            % each cell gets its own noise field
            matNoiseTransparency = repmat(255, [pedestalSize, pedestalSize]);
            if pedestalShape == 2
                radius = pedestalSize / 2;
                for x = 1:pedestalSize
                    for y = 1:pedestalSize
                        if floor(sqrt( (x - pedestalSize / 2)^2 + (y - pedestalSize / 2)^2 )) > radius
                            matNoiseTransparency(y, x) = 0;
                        end
                    end
                end
            end
        elseif noiseType == 0
            % one noise field for the whole display
            matNoiseTransparency = repmat(255, [stimAreaDiameter, stimAreaDiameter]);
            if pedestalShape == 2
                radius = stimAreaDiameter / 2;
                for x = 1:stimAreaDiameter
                    for y = 1:stimAreaDiameter
                        if floor(sqrt( (x - stimAreaDiameter / 2)^2 + (y - stimAreaDiameter / 2)^2 )) > radius
                            matNoiseTransparency(y, x) = 0;
                        end
                    end
                end
            end
        else
            error('noise type %d not supported', noiseType);
        end

        % generate mask textures
        nMaskTextures = nStimCells * 2;
        nLines = 100;
        texMasks = zeros(nMaskTextures, 1);
        for n = 1:nMaskTextures
            texMasks(n) = Screen('OpenOffscreenWindow', winMain, [], ...
                                 [0 0 pedestalSize pedestalSize]);
            Screen('BlendFunction', texMasks(n), ...
                   GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen('FillRect', texMasks(n), colBackground);
            Screen('DrawLines', texMasks(n), ...
                   Randi(pedestalSize + 1, [2, nLines * 2]) - 1, ...
                   Randi(10, [1, nLines]), ...
                   reshape(repmat(Randi(256, [3, nLines]) - 1, [2, 1]), ...
                           [3, nLines * 2]), ...
                   [], 1);
        end

        % set-up pedestal drawings
        if pedestalShape == 1
            pedestalCommand = 'FillRect';
        elseif pedestalShape == 2
            pedestalCommand = 'FillOval';
        else
            error('pedestal shape of %d is not supported', pedestalShape);
        end

        Screen('FillRect', winMain, colBackground);
        for n = 1:nStimCells
            Screen('DrawTexture', winMain, texMasks(n), [], stimCells(n, :));
        end
        Screen('FillOval', winMain, colFixation, rectFixation);
        Screen('Flip', winMain);
        WaitSecs(.25);

        Screen('FillRect', winMain, colBackground);
        %    CenterText(winMain, 'Press any key to begin.', colForeground);
        %    Screen('DrawLine', winMain, colForeground, 0, 427, 1280, 427);
        Screen('Flip', winMain);
        %    KbWait;

        blockPhaseStrings = {'practice', 'staircase', 'fixed'};
        blockPhases = 1:3;
        for phase = blockPhases
            if (phase == 1 && praTrials > 0)
                phaseName = 'practice';
                nTrials = praTrials;
                doStaircase = 0;
            elseif (phase == 2 && staircaseFlag)
                %% Optional staircasing trials
                phaseName = 'staircase';
                doStaircase = 1;
                nTrials = 10 * numel(targetList) * ...
                          numel(setSizeList) * numel(stimSetList);
                %% initialize staircase
                staircase = zeros(nStimSets, 1);
                staircaseIsDone = zeros(nStimSets, 1);
                for i = 1:nStimSets
                    staircase(i) = ...
                        Staircaser('Create', 1, nReversals, ...
                                   staircaseStart, staircaseSteps, ...
                                   nReversalsDropped, ...
                                   nStaircaseTracks, staircaseRange);
                end
                staircaseTrialCounter = nTrials;
            elseif (phase == 3 && expTrials > 0)
                %% Experimental trials, with noise level determined by
                %% staircase phase or by fixed values
                phaseName = 'fixed';
                nTrials = expTrials;
                doStaircase = 0;
            else
                % none of the phases are applicable
                continue;
            end

            % balance independent variables
            if ~doStaircase
                [target, setSize, noiseLevel, stimSet] = ...
                    BalanceFactors2(nTrials, 1, targetList, ...
                                    setSizeList, noiseLevelList, ...
                                    1:numel(stimSetList));
            end

            % set priority level
            priorityLevel = MaxPriority(winMain, 'KbCheck', 'GetSecs');
            % Priority(priorityLevel);
            Priority(0);

            trial = 0;
            blockDone = 0;
            while (~blockDone)
                prepStartTime = GetSecs;
                trial = trial + 1;
                trialtime = datestr(now, 'yyyymmdd.HHMMSS');

                if (doStaircase)
                    staircaseTrialCounter = staircaseTrialCounter + 1;
                    if (staircaseTrialCounter > nTrials)
                        [target, setSize, stimSet] = ...
                            BalanceFactors2(nTrials, 1, ...
                                            targetList, setSizeList, ...
                                            1:numel(stimSetList));
                        staircaseTrialCounter = 1;
                    end
                    ss = setSize(staircaseTrialCounter);
                    targ = target(staircaseTrialCounter);
                    stimIndex = stimSet(staircaseTrialCounter);
                    [success, noise, trackLabel] = ...
                        Staircaser('StartTrial', staircase(stimIndex));
                    if (~success)
                        error('Staircaser StartTrial failed on trial %d', ...
                              trial);
                    end
                else
                    ss = setSize(trial);
                    targ = target(trial);
                    stimIndex = stimSet(trial);
                    noise = noiseLevel(trial);
                    trackLabel = 0;
                end

                %% Setup display layout
                if balanceFlag == 0
                    stimloc = stimCells(randperm(nStimCells), :);
                else
                    error('balanceFlag values of %d are not supported', balanceFlag);
                end
                cueloc = stimloc(1:ss);

                if allstimFlag == 0;
                    nStim = ss;
                else
                    nStim = nStimCells;
                end

                texture = zeros(nStimCells, 1);
                angle = zeros(nStimCells, 1);
                if stim(stimIndex).mode == mdDetect
                    if targ
                        % select target stimuli
                        index = Randi(length(stim(stimIndex).texT));
                        texture(1) = stim(stimIndex).texT(index);
                        angle(1) = stim(stimIndex).angleT(index);
                        % define index for remaining stimuli
                        index = Randi(length(stim(stimIndex).texD), ...
                                      [numel(texture) - 1, 1]);
                        texture(2:nStimCells) = ...
                            stim(stimIndex).texD(index);
                        angle(2:nStimCells) = ...
                            stim(stimIndex).angleD(index);
                    else
                        index = Randi(length(stim(stimIndex).texD), ...
                                      size(texture));
                        texture = stim(stimIndex).texD(index);
                        angle = stim(stimIndex).angleD(index);
                    end
                else
                    error('stim mode %d not supported', stimMode);
                end

                % generate noise fields
                if noiseType == 0
                    % whole display
                    matNoise = repmat(Randi(256, [stimAreaDiameter, stimAreaDiameter]) - 1, [1, 1, 4]);
                    matNoise(:, :, 4) = matNoiseTransparency;
                    texNoise = Screen('MakeTexture', winMain, matNoise);
                else
                    % one per stim cell
                    if noiseType == 1
                        n = nStimCells;
                    else
                        n = ss;
                    end
                    matNoise = repmat(matNoiseTransparency, [1, 1, 4]);
                    texNoise = zeros(n, 1);
                    for i = 1:n
                        matNoise(:, :, 1:3) = repmat(Randi(256, [pedestalSize, pedestalSize]) - 1, [1, 1, 3]);
                        texNoise(i) = Screen('MakeTexture', winMain, matNoise);
                    end
                end

                % generate indexes for mask textures
                if any(maskFlag == [1 2])
                    maskIndex = randperm(nMaskTextures);
                end

                prepDur = (GetSecs - prepStartTime) * 1000;

                % make sure no keys are pressed
                [keyDown, keyTime, keyCode] = KbCheck;
                while keyDown
                    [keyDown, keyTime, keyCode] = KbCheck;
                    WaitSecs(0.001); % free up CPU for other tasks
                end

                % pretrial blank
                Screen('FillRect', winMain, colBackground);
                if pedestalFlag
                    for n = 1:nStimCells
                        Screen(pedestalCommand, winMain, colPedestal, stimCells(n, :));
                    end
                end
                Screen('DrawingFinished', winMain);
                [t1, tLastOnset] = Screen('Flip', winMain);
                tOnsetTrial = tLastOnset;
                tNextOnset = tLastOnset + durPreTrial;

                % fixation
                t1 = GetSecs;
                Screen('FillRect', winMain, colBackground, rectDisplay);
                if pedestalFlag
                    for n = 1:nStimCells
                        Screen(pedestalCommand, winMain, colPedestal, stimCells(n, :));
                    end
                end
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                durDrawFixation = GetSecs - t1;
                [t1, tLastOnset] = Screen('Flip', winMain, tNextOnset);
                Snd('Play', sndClick);
                tOnsetFixation = tLastOnset;
                tNextOnset = tLastOnset + durFixation;

                % draw pre-cues


                % draw display
                t1 = GetSecs;
                Screen('FillRect', winMain, colBackground, rectDisplay);
                if pedestalFlag
                    for n = 1:nStimCells
                        Screen(pedestalCommand, winMain, colPedestal, stimCells(n, :));
                    end
                end
                for n = 1:nStim
                    Screen('DrawTexture', winMain, texture(n), [], stimloc(n, :), angle(n));
                end
                if noiseType == 0
                    Screen('DrawTexture', winMain, texNoise, [], rectDisplay, [], [], noise);
                elseif any(noiseType == [1 2])
                    n = nStim;
                    if noiseType == 1, n = nStimCells; end
                    for i = 1:n
                        Screen('DrawTexture', winMain, texNoise(i), [], stimloc(i, :), [], [], noise);
                    end
                end
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                displayDrawDur = GetSecs - t1;
                [t1, tLastOnset] = Screen('Flip', winMain, tNextOnset);
                tOnsetDisplay = tLastOnset;
                tNextOnset = tLastOnset + durStim;

                % ISI
                t1 = GetSecs;
                Screen('FillRect', winMain, colBackground, rectDisplay);
                if pedestalFlag
                    for i = 1:nStimCells
                        Screen(pedestalCommand, winMain, colPedestal, stimCells(i, :));
                    end
                end
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                isiDrawDur = GetSecs - t1;
                [t1, tLastOnset] = Screen('Flip', winMain, tNextOnset);
                isiOnsetTime = tLastOnset;
                tNextOnset = tLastOnset + durISI;

                % mask
                t1 = GetSecs;
                Screen('FillRect', winMain, colBackground, rectDisplay);
                if pedestalFlag && maskFlag ~= 2 && nStim ~= nStimCells
                    for i = 1:nStimCells
                        Screen(pedestalCommand, winMain, colPedestal, stimCells(i, :));
                    end
                end
                if any(maskFlag == [1 2])
                    n = nStim;
                    if maskFlag == 2, n = nStimCells; end
                    for i = 1:n
                        Screen('DrawTexture', winMain, texMasks(maskIndex(i)), [], stimloc(i, :));
                    end
                end
                Screen('FillOval', winMain, colFixation, rectFixation);
                Screen('DrawingFinished', winMain);
                maskDrawDur = GetSecs - t1;
                [t1, tLastOnset] = Screen('Flip', winMain, tNextOnset);
                maskOnsetTime = tLastOnset;

                % collect response
                while 1
                    [keyDown, keyTime, keyCode] = KbCheck;
                    if keyDown && any(keyCode(allowedResponses))
                        break;
                    end
                    WaitSecs(0.001); % free up CPU for other tasks
                end
                Screen('FillRect', winMain, colBackground, rectDisplay);
                [t1, lastOnsetTime] = Screen('Flip', winMain);
                maskOffsetTime = lastOnsetTime;

                responseOnsetTime = keyTime;
                responseCode = find(keyCode);

                % process response
                rt = (responseOnsetTime - tOnsetDisplay) * 1000;
                if isempty(responseCode)
                    responseString = 'none';
                    acc = -1;
                elseif numel(responseCode) > 1
                    responseString = 'multi';
                    acc = -2;
                elseif responseCode == response0
                    responseString = stim(stimIndex).response{1};
                    if targ
                        acc = 0;
                    else
                        acc = 1;
                    end
                elseif responseCode == response1
                    responseString = stim(stimIndex).response{2};
                    if targ
                        acc = 1;
                    else
                        acc = 0;
                    end
                else
                    % non-response key pressed
                    responseString = sprintf('%d', responseCode);
                    acc = -3;
                end

                % prepare feedback
                switch acc
                  case 0
                    feedback = sprintf('TRIAL %d - ERROR', trial);
                    colFeedback = colRed;
                  case 1
                    feedback = sprintf('TRIAL %d - CORRECT', trial);
                    colFeedback = colGreen;
                  case -1
                    feedback = 'NO RESPONSE';
                    colFeedback = colRed;
                  case -2
                    feedback = 'MULTIPLE KEYS PRESSED';
                    colFeedback = colRed;
                  case -3
                    feedback = 'NON-RESPONSE KEY PRESSED';
                    colFeedback = colRed;
                end

                % present feedback
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen('FrameRect', winMain, colFrame, rectDisplay);
                CenterText(winMain, feedback, colFeedback, 0, -50);
                [t1, lastOnsetTime] = Screen('Flip', winMain);
                feedbackOnsetTime = lastOnsetTime;

                durExtraFeedback = 0;
                if acc == -1
                    durExtraFeedback = 0.300;
                    Snd('Play', sndBeep);
                    Snd('Play', sndBeep);
                    Snd('Play', sndBeep);
                end

                % update staircase
                reversal = 0;
                if doStaircase
                    if any(acc == [0 1])
                        r = acc + 1;
                    else
                        r = 0;
                    end
                    [success, done, reversal] = ...
                        Staircaser('EndTrial', staircase(stimIndex), r);
                    if (~success)
                        error('Staircaser EndTrial failed on trial %d', ...
                              trial);
                    elseif (done)
                        staircaseIsDone(stimIndex) = 1;
                    end
                end

                %%%          % output data
                %%%          dataFile = fopen(dataFileName, 'r');
                %%%          if dataFile == -1
                %%%             header = ['exp,code,version,sub,computer,blocktime,prac,trial,trialtime,' ...
                %%%                       'refreshdur,ss1,ss2,match,changetype,resp,acc,rt,' ...
                %%%                       'priority,prepdur,fixationdur,disp1dur,isidur,disp2dur,disp1drawdur,disp2drawdur'];
                %%%          else
                %%%             fclose(dataFile);
                %%%             header = [];
                %%%          end
                %%%          dataFile = fopen(dataFileName, 'a');
                %%%          if dataFile == -1
                %%%             error('cannot open data file %s for writing', dataFileName);
                %%%          end
                %%%          if ~isempty(header)
                %%%             fprintf(dataFile, '%s\n', header);
                %%%          end
                %%%          %                  %exp     %sub     %prac    %refreshdur    %resp             %prepdur    %disp1dur         %disp1drawdur
                %%%          fprintf(dataFile, '%s,%s,%s,%s,%s,%f,%d,%d,%s,%0.3f,%d,%d,%s,%s,%s,%d,%0.1f,%0.0f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f\n', ...
                %%%                  experiment, mfilename, Version, subject, computer, blocktime, prac, trial, trialtime, ...
                %%%                  refreshDuration * 1000, ss1, ss2, matchString, changeTypeString, responseString, acc, rt, ...
                %%%                  Priority, prepDur, durFixation, durDisplay, durISI, durDrawDisplay);
                %%%          fclose(dataFile);

                % clear screen after feedback duration
                Screen('FillRect', winMain, colBackground, rectDisplay);
                Screen('FrameRect', winMain, colFrame, rectDisplay);
                Screen('Flip', winMain, lastOnsetTime + durFeedback + durExtraFeedback);

                % Check whether block is done
                if (any(phase == [1 3]) && trial >= nTrials)
                    blockDone = 1;
                elseif (phase == 2 && doStaircase && all(staircaseIsDone))
                    blockDone = 1;
                end

            end % trial loop
            Priority(0);
        end % block loop

    catch
        %this "catch" section executes in case of an error in the "try" section
        %above.  Importantly, it closes the onscreen window if its open.
        ple();
    end %try..catch..

    Priority(0);
    ShowCursor;
    fclose('all');
    Screen('CloseAll');
    clear all global

function [pos, index] = MakeGrid (rect, rows, cols, stimrect, randomize, xnoise, ynoise)

% MakeGrid generates a grid of equally-spaced rects within a
% rectangle.  Each row of the returned matrix specifies one rect.
%
% MAKEGRID (RECT, ROWS, COLS, STIMRECT, RANDOMIZES, XNOISE, YNOISE)
% arranges rects of size STIMRECT within RECT in an equally spaced
% ROWS X COLS grid.  Non-zero values of RANDOMIZE lead to
% randomization of the order of the rects; otherwise, the rects are
% arranged in order from left-to-right, then top-to-bottom.  Optional
% arguments XNOISE and YNOISE specify the range of uniformly
% distributed horizontal and vertical noise, respectively, added to
% the centers of the rects (e.g., a value of 10 will lead add noise in
% the range of [-5, 4]).
%
% Author: David E. Fencsik (fencsik@gmail.com)
% $LastChangedDate$

    if numel(randomize) ~= 1
        randomize = 0;
    end
    if nargin < 6 || numel(xnoise) ~= 1
        xnoise = 0;
    end
    if nargin < 7 || numel(ynoise) ~= 1
        ynoise = 0;
    end

    n = cols * rows;

    bigW = rect(3) - rect(1);
    bigH = rect(4) - rect(2);
    smallW = stimrect(3) - stimrect(1);
    smallH = stimrect(4) - stimrect(2);

    intBorderX = floor((bigW - cols * smallW) / (cols + 1));
    extBorderX = ceil((bigW - cols * smallW - intBorderX * (cols - 1)) / 2);
    intBorderY = floor((bigH - rows * smallH) / (rows + 1));
    extBorderY = ceil((bigH - rows * smallH - intBorderY * (rows - 1)) / 2);

    xOffset = rect(RectLeft);
    yOffset = rect(RectTop);

    pos = zeros(n, 4);

    for r = 1:rows
        for c = 1:cols
            pos(cols * (r - 1) + c, :) = ...
                [extBorderX + (smallW + intBorderX) * (c - 1), ...
                 extBorderY + (smallH + intBorderY) * (r - 1), ...
                 extBorderX + (smallW + intBorderX) * (c - 1) + smallW, ...
                 extBorderY + (smallH + intBorderY) * (r - 1) + smallH];
        end
    end

    if xnoise > 0
        pos(:, [1 3]) = pos(:, [1 3]) + repmat(Randi(xnoise, [n, 1]) - ceil(xnoise / 2) - 1, [1, 2]);
    end
    if ynoise > 0
        pos(:, [2 4]) = pos(:, [2 4]) + repmat(Randi(ynoise, [n, 1]) - ceil(ynoise / 2) - 1, [1, 2]);
    end

    pos = pos + repmat([xOffset yOffset xOffset yOffset], size(pos, 1), 1);

    if randomize
        [tmp, index] = sort(rand(n, 1));
        pos = pos(index, :);
    else
        index = 1:n;
    end


function [pos, index] = MakeRing (rect, stimrect, num, radius, randomize, equidistant)

% MakeRing (RECT, STIMRECT, NUM, RADIUS, RANDOMIZE, EQUIDISTANT)
%
% Generates stimulus positions in a circle around the center of a
% supplied display rect.
%
% Generates NUM positions, each with a rect the size of STIMRECT
% located RADIUS pixels from the center of RECT.  If RANDOMIZE is 1,
% then the order of the positions is randomized (default 0).  If
% EQUIDISTANT is greater than N, then the stimulus positions have
% angular displacements as if there were EQUIDISTANT stimuli equally
% spaced around the circle; otherwise, all N stimuli are equally
% spaced.

    if nargin < 3 || numel(randomize) ~= 1
        randomize = 0;
    end
    if nargin < 4 || numel(equidistant) ~= 1
        equidistant = 0;
    end

    [centerX, centerY] = RectCenter(rect);

    if equidistant > num
        delta = 2 * pi / equidistant;
    else
        delta = 2 * pi / num;
    end

    start = rand * 2 * pi;

    pos = zeros(num, 4);

    for n = 1:num
        theta = start + delta * (n - 1);
        x = radius * sin(theta);
        y = radius * cos(theta);
        pos(n, :) = CenterRectOnPoint(stimrect, centerX + x, centerY - y);
    end

    if randomize
        [tmp, index] = sort(rand(num, 1));
        pos = pos(index, :);
    else
        index = 1:n;
    end



function CenterText (win, string, color, xOffset, yOffset)

    if nargin < 2 || numel(string) < 1
        error('Usage: %s (win, string, [color], [xOffset], [yOffset])', mfilename);
    end
    if nargin < 3 || isempty(color)
        color = BlackIndex(win);
    end
    if nargin < 4 || numel(xOffset) ~= 1
        xOffset = 0;
    end
    if nargin < 5 || numel(yOffset) ~= 1
        yOffset = 0;
    end

    [rect1, rect2] = Screen('TextBounds', win, string);
    yOffset = yOffset - (rect1(RectTop) - rect2(RectTop)) / 2; % compensate for baseline
    rect = OffsetRect(CenterRect(rect1, Screen('Rect', win)), xOffset, yOffset);
    Screen('DrawText', win, string, rect(RectLeft), rect(RectTop), color);


function varargout = DialogBox (title, varargin)
    n = (nargin - 1);
    if nargout ~= n / 3
        error('input and output arguments must match');
    end
    prompt = varargin(1:3:n);
    defaults = varargin(2:3:n);
    toNum = varargin(3:3:n);
    param = inputdlg(prompt, title, 1, defaults);
    if isempty(param)
        error('Dialog box cancelled');
    end
    varargout = cell(1, nargout);
    for i = 1:length(param)
        p = param{i};
        if toNum{i}
            n = [];
            if ~exist(p)
                n = str2num(p);
                if ~isempty(n)
                    varargout{i} = n;
                end
            end
            if isempty(n)
                error(['parameter ''%s'' value ''%s'' could not be ', ...
                       'converted to numeric as requested'], prompt{i}, p);
            end
        else
            varargout{i} = p;
        end
    end
