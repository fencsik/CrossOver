function SSE=maxruleSSE2(params,data)
%
% SSE = maxruleSSE2(params,data)
%
% Determines the sum of squared error for the maxrule model predictions
% compared to the data represented in SS, HR, and FA.
%
% params = 2 element vector [S C]
%         S = Sensitivity (d') at set size 1
%         C = Criterion
%
%   data = an Nx4 matrix of values for [K SS HR FA]
%         K = Capacity for max model
%        SS = Vector of set sizes tested
%        HR = Vector of hit rates for SS
%        FA = Vector of false alarm rates for SS
%
% Sample data: K SS HR   FA
%             [8 1 .855 .040;
%              8 2 .905 .170;
%              8 4 .785 .135;
%              8 8 .720 .085]
%

% Created by: Evan M. Palmer, 01/08/08
%             evan.palmer@wichita.edu

% New model to figure out the sensitivity and criterion that best matches a
% subject's performance, given a certain capacity (k) and set size (n).

% Not writing in any error checking for now.

S=params(1);
C=params(2);

K=data(1,1);
SS=data(:,2);
HR=data(:,3);
FA=data(:,4);



[model_HR,model_FA]=maxrule(S,C,SS,K);


HR_SSE=sum((HR-model_HR).^2);
FA_SSE=sum((FA-model_FA).^2);

SSE=HR_SSE+FA_SSE;


