function CrossoverX

% CrossoverX
%
% Authors: David E. Fencsik
% $LastChangedDate$

experiment = 'Test01';
Version = '0.2';

%%% %%% Dialog box
%%% dlgParam = {'subject'           , 'Subject'                          , 'xxx';
%%%             'practiceBlock'     , 'Practice block? (1 = yes)'        , '0';
%%%             'praTrials'         , 'No. of practice trials'           , '8';
%%%             'expTrials'         , 'Exp trials per cell'              , '2';
%%%             };
%%% param = inputdlg(dlgParam(:, 2), [experiment ' Parameters'], 1, dlgParam(:, 3));
%%% if size(param) < 1
%%%    return
%%% end
%%% for a = 1:length(param)
%%%    p = param{a};
%%%    n = str2num(p);
%%%    if isempty(n)
%%%       str = 'p';
%%%    else
%%%       str = 'n';
%%%    end
%%%    eval([dlgParam{a, 1} ' = ' str ';']);
%%% end

% Set any remaining parameters
subject = 'def';
taskflag = 7;
expTrials = 4;
praTrials = 0;
targetList = 1; %[0 1];
setSizeList = [4 8];
noiseLevelList = [.5 .25 .75];
nStaircases = 0;
stairStepError = -0.10;
stairStepCorrect = 0.025;

% control how stimuli are presented and cued
noiseFlag     = 1; % 0 = none, 1 = % of noise pixels, 2 = transparency of noise texture
noiseCellFlag = 1; % 0 = whole display, 1 = per cell
pedestalFlag  = 1; % 0 = none, 1 = square, 2 = circle
precueFlag    = 0; % 0 = none, 1 = square, 2 = arc
allstimFlag   = 0; % 0 = only show S stim, 1 = always fill all cue locations
balanceFlag   = 0; % 0 = random stim locations, 1 = balanced L-R locations

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
% Note: distance -> pixel sizes (17" monitor, 1024x768 resolution)
% 106 cm -> 60.14 pix/deg --- 105 cm -> 59.58 pix/deg
%  89 cm -> 50.50 pix/deg ---  88 cm -> 49.93 pix/deg
%  53 cm -> 30.07 pix/deg ---  52 cm -> 29.50 pix/deg
stimRadius = 256;
nStimMax = 12;
rectStim = [0 0 100 100];
rectPedestal = [0 0 120 120];
rectDisplay = [0 0 500 500];
sizeStimX = RectWidth(rectStim);
sizeStimY = RectHeight(rectStim);

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
seed = sum(100*clock);
rand('state', seed);
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
   Screen('Preference', 'VisualDebugLevel', 3);
   screenNumber=max(Screen('Screens'));
   [winMain, rectMain] = Screen('OpenWindow', screenNumber, 0, [], 32, 2);
   [refreshDuration, dummy1, dummy2] = Screen('GetFlipInterval', winMain, 100);
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
   colForeground = colWhite;
   colBackground = colGray;
   colFrame = colBackground;
   colPedestal = colRed;
   colFixation = colForeground;
   colStim = [170 170 170];
   
   % other rects
   rectDisplayCentered = CenterRect(rectDisplay, rectMain);
   rectFixation = CenterRect([0 0 6 6], rectMain);

   % blank screen and issue wait notice
   Screen('FillRect', winMain, colBackground);
   CenterText(winMain, 'Please wait...', colForeground);
   Screen('Flip', winMain);

   % Generate stimuli
   if numel(colBackground) == 1
      colBackground = repmat(colBackground, 1, 3);
   end
   if taskflag == 1
      error('taskflag %d does not exist', taskflag);
   elseif taskflag == 2
      % orientation
      mat = repmat(255, [100, 100, 4]);
      mat(:, :, 1:3) = repmat(reshape(colBackground, 1, 1, 3), [100, 100, 1]);
      mat(:, 41:60, 1:3) = repmat(reshape(colStim, 1, 1, 3), [100, 20, 1]);
      mat(:, 41:50, 4) = repmat(0, [100, 20, 1]);

      stimTextureT = Screen('MakeTexture', winMain, mat);
      stimTextureD = stimTextureT;
      stimAngleT = 20;
      stimAngleD = 0;

      stimMode = mdDetect;
      responseString0 = 'absent';
      responseString1 = 'present';
   elseif taskflag == 7
      %%% 2 vs. 5

      % generate basic components
      col = reshape([colStim 255], 1, 1, 4);
      vbar = repmat(col, [20, 100, 1]);
      hbar = repmat(col, [40,  20, 1]);

      % generate 2
      mat = repmat(0, [100, 100, 4]);
      mat(:, :, 1:3) = repmat(reshape(colBackground, 1, 1, 3), [100, 100, 1]);
      mat( 1:20 , :, :) = vbar;
      mat(41:60 , :, :) = vbar;
      mat(81:100, :, :) = vbar;
      mat( 1:40 , 81:100, :) = hbar;
      mat(61:100,  1:20 , :) = hbar;
      stimTextureT = Screen('MakeTexture', winMain, mat);
      stimAngleT = 0;
      
      % generate 5
      mat = repmat(0, [100, 100, 4]);
      mat(:, :, 1:3) = repmat(reshape(colBackground, 1, 1, 3), [100, 100, 1]);
      mat( 1:20 , :, :) = vbar;
      mat(41:60 , :, :) = vbar;
      mat(81:100, :, :) = vbar;
      mat( 1:40 ,  1:20 , :) = hbar;
      mat(61:100, 81:100, :) = hbar;
      stimTextureD = Screen('MakeTexture', winMain, mat);
      stimAngleD = 0;

      stimMode = mdDetect;
      responseString0 = 'absent';
      responseString1 = 'present';
   else
      error('taskflag %d does not exist', taskflag);
   end

   % define stimulus presentation cells
   nStimCells = 8;
   radiusStimCells = 256;
   expansionFactor = 1.0;
   stimCells = zeros(nStimCells, 4);
   pedCells = stimCells;
   for n = 1:nStimCells
      stimCells(n, :) = CenterRectOnPoint(rectStim, ...
                                          centerX + round(radiusStimCells * sin((n - 1) * 2 * pi / nStimCells)), ...
                                          centerY + round(radiusStimCells * cos((n - 1) * 2 * pi / nStimCells)));
      pedCells(n, :) = CenterRectOnPoint(rectPedestal, ...
                                          centerX + round(radiusStimCells * sin((n - 1) * 2 * pi / nStimCells)), ...
                                          centerY + round(radiusStimCells * cos((n - 1) * 2 * pi / nStimCells)));
   end
   
   % compute square rect needed to contain all stimulus cells
   extraRadius = ceil( sqrt( (.5 * RectWidth(pedCells(1, :)))^2 + (.5 * RectHeight(pedCells(1, :)))^2 ) );
   stimAreaDiameter = ceil(2 * expansionFactor * (radiusStimCells + extraRadius));
   rectDisplay = CenterRect([0 0 stimAreaDiameter stimAreaDiameter], rectMain);

   % draw a sample of the display area
   Screen('FillRect', winMain, colBackground);
   Screen('FillOval', winMain, colFixation, CenterRect([0 0 10 10], rectMain));
   for n = 1:nStimCells
      Screen('FillRect', winMain, colForeground, stimCells(n, :));
      Screen('DrawText', winMain, int2str(n), stimCells(n, RectLeft) + 30, stimCells(n, RectBottom) - 50, colBackground);
   end
   Screen('FrameOval', winMain, colRed, rectDisplay);
   Screen('Flip', winMain);
   WaitSecs(.25);

   sx = RectWidth(rectDisplay);
   sy = RectHeight(rectDisplay);
   %matTransparency = repmat(255, 
   if noiseFlag == 1
      matNoise = repmat(colWhite*rand(sy, sx), [1, 1, 3]);
      matNoiseMask = repmat(1, [sy, sx]);
      radius = stimAreaDiameter / 2;
      for x = 1:sx
         for y = 1:sy
            if floor(sqrt( (x - sx / 2)^2 + (y - sy / 2)^2 )) > radius
               matNoiseMask(y, x) = 0;
            end
         end
      end
   else
      error('obscureflag = %d is not supported', obscureFlag);
   end

   % set-up pedestal drawings
   if pedestalFlag == 1
      drawPedestals = 1;
      pedestalCommand = 'FillRect';
   elseif pedestalFlag == 2
      drawPedestals = 1;
      pedestalCommand = 'FillOval';
   else
      drawPedestals = 0;
   end

   Screen('FillRect', winMain, colBackground);
   %    CenterText(winMain, 'Press any key to begin.', colForeground);
   %    Screen('DrawLine', winMain, colForeground, 0, 427, 1280, 427);
   Screen('Flip', winMain);
   %    KbWait;

   for subBlock = 1:2
      
      if subBlock == 1
         prac = 1;
         nTrials = praTrials;
      else
         prac = 0;
         nTrials = expTrials;
      end
      
      if nTrials <= 0, continue; end

      % balance independent variables
      NumberOfTrials = nTrials;
      if nStaircases < 1
         IVs = {'target'            , targetList;
                'setSize'           , setSizeList;
                'noiseLevel'        , noiseLevelList;
               };
      else
         IVs = {'target'            , targetList;
                'setSize'           , setSizeList;
               };
      end      
      nVariables = size(IVs, 1);
      varLength = zeros(nVariables, 1);
      listLength = 1;
      for v = 1:nVariables
         varLength(v) = length(IVs{v, 2});
         listLength = listLength * varLength(v);
      end
      nRepetitions = ceil(NumberOfTrials / listLength);
      len1 = listLength;
      len2 = 1;
      [dummy, index] = sort(rand(listLength * nRepetitions, 1)); 
      for v = 1:nVariables
         len1 = len1 / varLength(v);
         eval([IVs{v, 1} ' = repmat(reshape(repmat(IVs{v, 2}, len1, len2), listLength, 1), nRepetitions, 1);']);
         eval([IVs{v, 1} ' = ' IVs{v, 1} '(index);']);
         len2 = len2 * varLength(v);
      end
      if listLength * nRepetitions ~= NumberOfTrials
         warning('unbalanced design');
      end
      clear NumberOfTrials IVs nVariables varLength listLength nRepetitions v dummy len1 len2 index;

      % set priority level
      priorityLevel = MaxPriority(winMain, 'KbCheck', 'GetSecs');
      % Priority(priorityLevel);
      Priority(0);

      for trial = 1:nTrials
         prepStartTime = GetSecs;
         trialtime = datestr(now);

         ss = setSize(trial);
         noise = noiseLevel(trial);
         targ = target(trial);

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
         if stimMode == mdDetect
            if targ
               % select target stimuli
               index = Randi(length(stimTextureT));
               texture(1) = stimTextureT(index);
               angle(1) = stimAngleT(index);
               % define index for remaining stimuli
               index = Randi(length(stimTextureD), size(texture));
               texture(2:nStimCells) = stimTextureD(index(2:nStimCells));
               angle(2:nStimCells) = stimAngleD(index(2:nStimCells));
            else
               index = Randi(length(stimTextureD), size(texture));
               texture = stimTextureD(index);
               angle = stimAngleD(index);
            end
         else
            error('stim mode %d not supported', stimMode);
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
         if drawPedestals
            for n = 1:nStimCells
               Screen(pedestalCommand, winMain, colPedestal, stimCells(n, :));
            end
         end
         Screen('DrawingFinished', winMain);
         [t1, tLastOnset] = Screen('Flip', winMain);
         trialOnsetTime = tLastOnset;
         tNextOnset = tLastOnset + durPreTrial;

         % fixation
         t1 = GetSecs;
         Screen('FillRect', winMain, colBackground, rectDisplay);
         if drawPedestals
            for n = 1:nStimCells
               Screen(pedestalCommand, winMain, colPedestal, stimCells(n, :));
            end
         end
         Screen('FillOval', winMain, colFixation, rectFixation);
         Screen('DrawingFinished', winMain);
         fixationDrawDur = GetSecs - t1;
         [t1, tLastOnset] = Screen('Flip', winMain, tNextOnset);
         Snd('Play', sndClick);
         fixationOnsetTime = tLastOnset;
         tNextOnset = tLastOnset + durFixation;

         % draw pre-cues


         % draw display
         t1 = GetSecs;
         Screen('FillRect', winMain, colBackground, rectDisplay);
         if drawPedestals
            for n = 1:nStimCells
               Screen(pedestalCommand, winMain, colPedestal, stimCells(n, :));
            end
         end
         for n = 1:nStim
            Screen('DrawTexture', winMain, texture(n), [], stimloc(n, :), angle(n));
         end
         Screen('FillOval', winMain, colFixation, rectFixation);
         Screen('DrawingFinished', winMain);
         displayDrawDur = GetSecs - t1;
         [t1, tLastOnset] = Screen('Flip', winMain, tNextOnset);
         displayOnsetTime = tLastOnset;
         tNextOnset = tLastOnset + durStim;

         % ISI
         t1 = GetSecs;
         Screen('FillRect', winMain, colBackground, rectDisplay);
         if drawPedestals
            for n = 1:nStimCells
               Screen(pedestalCommand, winMain, colPedestal, stimCells(n, :));
            end
         end
         Screen('FillOval', winMain, colFixation, rectFixation);
         Screen('DrawingFinished', winMain);
         isiDrawDur = GetSecs - t1;
         [t1, tLastOnset] = Screen('Flip', winMain, tNextOnset);
         isiOnsetTime = tLastOnset;
         tNextOnset = tLastOnset + durISI;
         
         % mask

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
         rt = (responseOnsetTime - displayOnsetTime) * 1000;
         if numel(responseCode) > 1
            responseString = 'multi';
            acc = -1;
         elseif responseCode == response0
            responseString = responseString0;
            if targ
               acc = 0;
            else
               acc = 1;
            end
         elseif responseCode == response1
            responseString = responseString1;
            if targ
               acc = 1;
            else
               acc = 0;
            end
         else
            % non-response key pressed
            responseString = KbName(responseCode);
            acc = -1;
         end

         % prepare feedback
         if acc == 0
            feedback = sprintf('TRIAL %d - ERROR', trial);
            colFeedback = colRed;
         elseif acc == 1
            feedback = sprintf('TRIAL %d - CORRECT', trial);
            colFeedback = colGreen;
         else
            colFeedback = colRed;
            feedback = sprintf('YOU PRESSED A BAD KEY', trial);
         end
         
         % present feedback
         Screen('FillRect', winMain, colBackground, rectDisplayCentered);
         Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
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

         % compute durations and convert to milliseconds
         fixationDur = (displayOnsetTime - fixationOnsetTime) * 1000;
         displayDur = (isiOnsetTime - displayOnsetTime) * 1000;
         isiDur = 0; %(displayOnsetTime - isiOnsetTime) * 1000;

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
%%%                  Priority, prepDur, fixationDur, display1Dur, isiDur, display2Dur, display1DrawDur, display2DrawDur);
%%%          fclose(dataFile);

         % clear screen after feedback duration
         Screen('FillRect', winMain, colBackground, rectDisplayCentered);
         Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
         Screen('Flip', winMain, lastOnsetTime + durFeedback + durExtraFeedback);

      end % for trial = 1:nTrials
      Priority(0);
   end % for subBlock = 1:2

catch
   %this "catch" section executes in case of an error in the "try" section
   %above.  Importantly, it closes the onscreen window if its open.
   Priority(0);
   fprintf('error caught...\n\n');
   Screen('CloseAll');
   ShowCursor;
   rethrow(lasterror);
end %try..catch..

Screen('CloseAll');
ShowCursor;
Priority(0);



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
