function CrossoverX

% CrossoverX
%
% Authors: David E. Fencsik
% $LastChangedDate$

experiment = 'Test01';
Version = '0.1';

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
expTrials = 4;
praTrials = 0;
setSizeList = [2 4 8];
taskflag = 7;

% define timings (sec)
durPreTrial  = 0.745;
durFixation  = 0.745;
durDisplay1  = 0.180;
durISI       = 0.995;
durDisplay2  = 2.000;
durFeedback  = 0.745;

% stimulus set-up
% Note: distance -> pixel sizes (17" monitor, 1024x768 resolution)
% 106 cm -> 60.14 pix/deg --- 105 cm -> 59.58 pix/deg
%  89 cm -> 50.50 pix/deg ---  88 cm -> 49.93 pix/deg
%  53 cm -> 30.07 pix/deg ---  52 cm -> 29.50 pix/deg
stimRadius = 256;
nStimMax = 12;
rectStim = [0 0 128 128];
rectDisplay = [0 0 500 500];
sizeStimX = RectWidth(rectStim);
sizeStimY = RectHeight(rectStim);

% response set-up
responseTA = 227;   % 'LeftGUI'  == left Apple-key
responseTP = 231;   % 'RightGUI' == right Apple-key
respUp3 = 228;     % RightControl
respUp2 = 230;     % RightAlt
respUp1 = 231;     % RightGUI
respDown1 = 227;   % LeftGUI
respDown2 = 226;   % LeftAlt
respDown3 = 224;   % LeftControl
respQuit = 41;     % ESCAPE
% responseTA = 4;  % 'a'  == "a" key
% responseTP = 52; % ''"' == quote key
allowedResponses = [responseTA responseTP];

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
   error(sprintf('%s can only be run in OSX versions of Psychtoolbox', mfilename));
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
   colBackground = colDarkGray;
   colFrame = colBackground;
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
   if prod(size(colBackground)) == 1
      colBackground = repmat(colBackground, 1, 3);
   end
   if taskflag == 7
      %%% 2 vs. 5

      % generate basic components
      col = reshape(colStim, 1, 1, 3);
      vbar = repmat(col, [20, 100, 1]);
      hbar = repmat(col, [40,  20, 1]);

      % generate 2
      mat = repmat(reshape(colBackground, 1, 1, 3), [100, 100, 1]);
      mat( 1:20 , :, :) = vbar;
      mat(41:60 , :, :) = vbar;
      mat(81:100, :, :) = vbar;
      mat( 1:40 , 81:100, :) = hbar;
      mat(61:100,  1:20 , :) = hbar;
      texTwo = Screen('MakeTexture', winMain, mat);
      
      % generate 5
      mat = repmat(reshape(colBackground, 1, 1, 3), [100, 100, 1]);
      mat( 1:20 , :, :) = vbar;
      mat(41:60 , :, :) = vbar;
      mat(81:100, :, :) = vbar;
      mat( 1:40 ,  1:20 , :) = hbar;
      mat(61:100, 81:100, :) = hbar;
      texFive = Screen('MakeTexture', winMain, mat);
   else
      error(sprintf('taskflag %d does not exist', taskflag));
   end

   nStimCells = 8;
   radiusStimCells = 256;
   stimCells = zeros(nStimCells, 4);
   for n = 1:nStimCells
      stimCells(n, :) = CenterRectOnPoint([0 0 100 100], ...
                                          centerX + radiusStimCells * sin((n - 1) * 2 * pi / nStimCells), ...
                                          centerY + radiusStimCells * cos((n - 1) * 2 * pi / nStimCells));
   end
   expansion = 100;
   rectDisplay = [min(stimCells(:, 1)) - expansion, min(stimCells(:, 2)) - expansion, ...
                  max(stimCells(:, 3)) + expansion, max(stimCells(:, 4)) + expansion];
   displayX = RectWidth(rectDisplay);
   displayY = RectHeight(rectDisplay);

   noise = 1.0;
   noiseStep1 = 0.001;
   noiseStep2 = 0.01;
   noiseStep3 = 0.1;

   matNoise = repmat(255, [displayY, displayX, 4]);
   matNoise(:, :, 1:3) = repmat(ceil(255 * rand(displayY, displayX)), [1, 1, 3]);
   %mat(226:275, 226:275, 4) = 0;
   matCenterX = displayX / 2;
   matCenterY = displayY / 2;
   
   matBounds = repmat(1, [size(matNoise, 1), size(matNoise, 2)]);
   for x = 1:size(matBounds, 2)
      for y = 1:size(matBounds, 1)
         if sqrt((x - matCenterX)^2 + (y - matCenterY)^2) > radiusStimCells + 80
            matBounds(y, x) = 0;
         end
      end
   end

   %texNoise = Screen('MakeTexture', winMain, mat);

   tloc = Randi(nStimCells);
   done = 0;
   while ~done
      matMask = repmat(255, size(matNoise, 1), size(matNoise, 2));
      matMask(rand(size(matMask)) > noise) = 0;
      matNoise(:, :, 4) = matMask .* matBounds;
      texNoise = Screen('MakeTexture', winMain, matNoise);

      Screen('FillRect', winMain, colBackground, rectDisplay);
      for n = 1:nStimCells
         Screen('DrawTexture', winMain, texFive, [], stimCells(n, :));
      end
      Screen('DrawTexture', winMain, texTwo, [], stimCells(tloc, :));
      % Screen('DrawTexture', winMain, texNoise, [], rectDisplay, [], [], noise);
      Screen('DrawTexture', winMain, texNoise, [], rectDisplay);
      CenterText(winMain, sprintf('%7.5f', noise), colForeground, displayX / 2, 0);
      Screen('Flip', winMain);
      
      while 1
         [keyDown, keyTime, keyCode] = KbCheck;
         if keyDown
            resp = find(keyCode);
            if resp == respQuit
               done = 1;
               break;
            elseif resp == respUp3
               noise = min(1, noise + noiseStep3);
               break;
            elseif resp == respUp2
               noise = min(1, noise + noiseStep2);
               break;
            elseif resp == respUp1
               noise = min(1, noise + noiseStep1);
               break;
            elseif resp == respDown1
               noise = max(0, noise - noiseStep1);
               break;
            elseif resp == respDown2
               noise = max(0, noise - noiseStep2);
               break;
            elseif resp == respDown3
               noise = max(0, noise - noiseStep3);
               break;
            end
         end
      end
      Screen('Close', texNoise);
%       while keyDown
%          [keyDown, keyTime, keyCode] = KbCheck;
%       end
   end
   
   ShowCursor;
   Screen('CloseAll');
   return;
               

   Screen('FillRect', winMain, colBackground);
   %    CenterText(winMain, 'Press any key to begin.', colForeground);
   %    Screen('DrawLine', winMain, colForeground, 0, 427, 1280, 427);
   Screen('Flip', winMain);
   %    KbWait;

   % balance independent variables
   ivs = {'setSize'           , setSizeList;
          'changeType'        , changeTypeList;
         };
   nVariables = size(ivs, 1);
   varLength = zeros(nVariables, 1);
   listLength = 1;
   for v = 1:nVariables
      varLength(v) = length(ivs{v, 2});
      listLength = listLength * varLength(v);
   end
   nRepetitions = ceil(expTrials / listLength);
   len1 = listLength;
   len2 = 1;
   [dummy, index] = sort(rand(listLength * nRepetitions, 1)); 
   for v = 1:nVariables
      len1 = len1 / varLength(v);
      eval([ivs{v, 1} ' = repmat(reshape(repmat(ivs{v, 2}, len1, len2), listLength, 1), nRepetitions, 1);']);
      eval([ivs{v, 1} ' = ' ivs{v, 1} '(index);']);
      len2 = len2 * varLength(v);
   end
   clear dummy len1 len2 index ivs varLength;

   if listLength * nRepetitions ~= expTrials
      warning('unbalanced design');
   end

   priorityLevel = MaxPriority(winMain, 'KbCheck', 'GetSecs');
   Priority(priorityLevel);
   % Priority(0);

   nTrials = expTrials + praTrials;
   for trial = 1:nTrials
      prepStartTime = GetSecs;
      trialtime = datestr(now);

      % pre-trial blank
      Screen('FillRect', winMain, colBackground);
      Screen('FrameRect', winMain, colFrame, rectDisplay);
      [t1, lastOnsetTime] = Screen('Flip', winMain);
      trialOnsetTime = lastOnsetTime;

      % determine trial index
      if trial <= praTrials
         prac = 1;
         trialIndex = Randi(expTrials);
      else
         prac = 0;
         trialIndex = trial - praTrials;
      end
      ss1 = setSize(trialIndex);
      ss2 = ss1;

      % shuffle colors and shapes for display 1
      if useColor
         colorIndex1 = repmat(useColor, [1, nColors]);
      else
         colorIndex1 = randperm(nColors);
      end
      if useShape
         shapeIndex1 = repmat(useShape, [1, nShapes]);
      else
         shapeIndex1 = randperm(nShapes);
      end

      % make changes for display 2
      if changeType(trialIndex) > 0 && changeType(trialIndex) <= length(changeTypeNames)
         changeTypeString = changeTypeNames{changeType(trialIndex)};
      else
         changeTypeString = 'unknown';
      end
      isDiff = 1;
      matchString = 'diff';
      maxSetSizeExceeded = 0; minSetSizeExceeded = 0;
      colorIndex2 = colorIndex1;
      shapeIndex2 = shapeIndex1;
      switch changeType(trialIndex)
       case ctSame
         isDiff = 0;
         matchString = 'same';
       case ctSubst1color
         if ss1 > nColors - 1, maxSetSizeExceeded = nColors - 1;
         elseif ss1 < 1, minSetSizeExceeded = 1;
         else
            colorIndex2(1) = colorIndex1(ss1 + 1);
         end
       case ctSubst2color
         if ss1 > nColors - 2, maxSetSizeExceeded = nColors - 2;
         elseif ss1 < 2, minSetSizeExceeded = 2;
         else
            colorIndex2(1) = colorIndex1(ss1 + 1);
            colorIndex2(2) = colorIndex1(ss1 + 2);
         end
       case ctSubst1shape
         if ss1 > nShapes - 1, maxSetSizeExceeded = nShapes - 1;
         elseif ss1 < 1, minSetSizeExceeded = 1;
         else
            shapeIndex2(1) = shapeIndex1(ss1 + 1);
         end
       case ctSubst2shape
         if ss1 > nShapes - 2, maxSetSizeExceeded = nShapes - 2;
         elseif ss1 < 2, minSetSizeExceeded = 2;
         else
            shapeIndex2(1) = shapeIndex1(ss1 + 1);
            shapeIndex2(2) = shapeIndex1(ss1 + 2);
         end
       case ctInter2color
         if ss1 > nColors, maxSetSizeExceeded = nColors;
         elseif ss1 < 2, minSetSizeExceeded = 2;
         else
            colorIndex2(1) = colorIndex1(2);
            colorIndex2(2) = colorIndex1(1);
         end
       case ctInter2shape
         if ss1 > nShapes, maxSetSizeExceeded = nShapes;
         elseif ss1 < 2, minSetSizeExceeded = 2;
         else
            shapeIndex2(1) = shapeIndex1(2);
            shapeIndex2(2) = shapeIndex1(1);
         end
       case ctAdd1
         if ss1 > min(nColors, nShapes) - 1, maxSetSizeExceeded = min(nColors, nShapes) - 1;
         else
            ss2 = ss1 + 1;
         end
       case ctAdd2
         if ss1 > min(nColors, nShapes) - 2, maxSetSizeExceeded = min(nColors, nShapes) - 2;
         else
            ss2 = ss1 + 2;
         end
       case ctRemove1
         if ss1 < 1, minSetSizeExceeded = 1;
         else
            ss2 = ss1 - 1;
         end
       case ctRemove2
         if ss1 < 2, minSetSizeExceeded = 2;
         else
            ss2 = ss1 - 2;
         end
       otherwise
         error(sprintf('change type %d (%s) not yet implemented', changeType(trialIndex), changeTypeString)); 
      end
      if maxSetSizeExceeded > 0
         error(sprintf('Set size must be no more than %d for %s trials', ...
                       maxSetSizeExceeded, changeTypeString));
      end
      if minSetSizeExceeded > 0
         error(sprintf('Set size must be at least %d for %s trials', ...
                       minSetSizeExceeded, changeTypeString));
      end

      % determine stimulus indexes
      stimIndex1 = (colorIndex1(1:ss1) - 1) .* nShapes + shapeIndex1(1:ss1);
      stimIndex2 = (colorIndex2(1:ss2) - 1) .* nShapes + shapeIndex2(1:ss2);

      % figure out object placement
      % rect = MakeGrid(rectDisplayCentered, 4, 4, rectStim, 1, 30, 30);
      rect = MakeRing(rectMain, rectStim, stimSpacing, stimRadius, 1, 1);

      prepDur = (GetSecs - prepStartTime) * 1000;

      % make sure no keys are pressed
      [keyDown, keyTime, keyCode] = KbCheck;
      while keyDown
         [keyDown, keyTime, keyCode] = KbCheck;
         WaitSecs(0.001); % free up CPU for other tasks
      end

      % prepare fixation
      t1 = GetSecs;
      Screen('FillRect', winMain, colBackground, rectDisplayCentered);
      Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
      Screen('FillOval', winMain, colFixation, rectFixation);
      Screen('DrawingFinished', winMain);
      fixationDrawDur = GetSecs - t1;
      [t1, lastOnsetTime] = Screen('Flip', winMain, lastOnsetTime + durPreTrial);
      Snd('Play', sndClick);
      fixationOnsetTime = lastOnsetTime;
      % fixationOnsetTime = GetSecs;

      % draw display 1
      t1 = GetSecs;
      Screen('FillRect', winMain, colBackground, rectDisplayCentered);
      Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
      for n = 1:ss1
         Screen('DrawTexture', winMain, texFive(stimIndex1(n)), rectStim, rect(n, :));
         WaitSecs(0.001); % free up CPU for other tasks
      end
      % CenterText(winMain, sprintf('%s%s', colorNames{colorIndex1(1)}, shapeNames{shapeIndex1(1)}), ...
      %            colForeground, 0, 120);
      Screen('DrawingFinished', winMain);
      display1DrawDur = GetSecs - t1;
      [t1, lastOnsetTime] = Screen('Flip', winMain, lastOnsetTime + durFixation);
      display1OnsetTime = lastOnsetTime;
      % display1OnsetTime = GetSecs;

      % ISI
      t1 = GetSecs;
      Screen('FillRect', winMain, colBackground, rectDisplayCentered);
      Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
      Screen('DrawingFinished', winMain);
      isiDrawDur = GetSecs - t1;
      [t1, lastOnsetTime] = Screen('Flip', winMain, lastOnsetTime + durDisplay1);
      isiOnsetTime = lastOnsetTime;
      % isiOnsetTime = GetSecs;

      % draw display 2
      Screen('FillRect', winMain, colBackground, rectDisplayCentered);
      Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
      for n = 1:ss2
         Screen('DrawTexture', winMain, texFive(stimIndex2(n)), rectStim, rect(n, :));
         WaitSecs(0.001); % free up CPU for other tasks
      end
      % CenterText(winMain, sprintf('%s%s', colorNames{colorIndex2(1)}, shapeNames{shapeIndex2(1)}), ...
      %            colForeground, 0, 120);
      Screen('DrawingFinished', winMain);
      display2DrawDur = GetSecs - t1;
      [t1, lastOnsetTime] = Screen('Flip', winMain, lastOnsetTime + durISI);
      display2OnsetTime = lastOnsetTime;
      % display2OnsetTime = GetSecs;

      % wait for response
      [keyDown, keyTime, keyCode] = KbCheck;
      while ~keyDown
         [keyDown, keyTime, keyCode] = KbCheck;
         WaitSecs(0.001); % free up CPU for other tasks
      end
      Screen('FillRect', winMain, colBackground, rectDisplayCentered);
      Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
      [t1, lastOnsetTime] = Screen('Flip', winMain);
      display2OffsetTime = lastOnsetTime;
      
      responseOnsetTime = keyTime;
      responseCode = find(keyCode);
      responseCode = responseCode(1);

      % process response
      rt = (responseOnsetTime - display2OnsetTime) * 1000;
      if responseCode == responseSame
         responseString = 'same';
         if isDiff
            acc = 0;
         else
            acc = 1;
         end
      elseif responseCode == responseDiff
         responseString = 'diff';
         if isDiff
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
      fixationDur = (display1OnsetTime - fixationOnsetTime) * 1000;
      display1Dur = (isiOnsetTime - display1OnsetTime) * 1000;
      isiDur = (display2OnsetTime - isiOnsetTime) * 1000;
      display2Dur = (display2OffsetTime - display2OnsetTime) * 1000;
      display1DrawDur = display1DrawDur * 1000;
      display2DrawDur = display2DrawDur * 1000;

      % output data
      dataFile = fopen(dataFileName, 'r');
      if dataFile == -1
         header = ['exp,code,version,sub,computer,blocktime,prac,trial,trialtime,' ...
                   'refreshdur,ss1,ss2,match,changetype,resp,acc,rt,' ...
                   'priority,prepdur,fixationdur,disp1dur,isidur,disp2dur,disp1drawdur,disp2drawdur'];
      else
         fclose(dataFile);
         header = [];
      end
      dataFile = fopen(dataFileName, 'a');
      if dataFile == -1
         error(sprintf('cannot open data file %s for writing', dataFileName));
      end
      if ~isempty(header)
         fprintf(dataFile, '%s\n', header);
      end
      %                  %exp     %sub     %prac    %refreshdur    %resp             %prepdur    %disp1dur         %disp1drawdur
      fprintf(dataFile, '%s,%s,%s,%s,%s,%f,%d,%d,%s,%0.3f,%d,%d,%s,%s,%s,%d,%0.1f,%0.0f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f,%0.3f\n', ...
              experiment, mfilename, Version, subject, computer, blocktime, prac, trial, trialtime, ...
              refreshDuration * 1000, ss1, ss2, matchString, changeTypeString, responseString, acc, rt, ...
              Priority, prepDur, fixationDur, display1Dur, isiDur, display2Dur, display1DrawDur, display2DrawDur);
      fclose(dataFile);

      % clear screen after feedback duration
      Screen('FillRect', winMain, colBackground, rectDisplayCentered);
      Screen('FrameRect', winMain, colFrame, rectDisplayCentered);
      Screen('Flip', winMain, lastOnsetTime + durFeedback + durExtraFeedback);

   end
   Priority(0);
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

if prod(size(randomize)) ~= 1
   randomize = 0;
end
if nargin < 6 || prod(size(xnoise)) ~= 1
   xnoise = 0;
end
if nargin < 7 || prod(size(ynoise)) ~= 1
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

if nargin < 3 || prod(size(randomize)) ~= 1
   randomize = 0;
end
if nargin < 4 || prod(size(equidistant)) ~= 1
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

if nargin < 2 || prod(size(string)) < 1
   error(sprintf('Usage: %s (win, string, [color], [xOffset], [yOffset])', mfilename));
end 
if nargin < 3 || isempty(color)
   color = BlackIndex(win);
end
if nargin < 4 || prod(size(xOffset)) ~= 1
   xOffset = 0;
end
if nargin < 5 || prod(size(yOffset)) ~= 1
   yOffset = 0;
end

[rect1, rect2] = Screen('TextBounds', win, string);
yOffset = yOffset - (rect1(RectTop) - rect2(RectTop)) / 2; % compensate for baseline
rect = OffsetRect(CenterRect(rect1, Screen('Rect', win)), xOffset, yOffset);
Screen('DrawText', win, string, rect(RectLeft), rect(RectTop), color);
