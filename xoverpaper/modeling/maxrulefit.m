function [S,C,SSE]=maxrulefit(data, params, options)
%
% [S,C,SSE]=MAXRULEFIT(DATA,START_PARAMS,OPTIONS)
% Where S C that best fits the data for the specified max
% rule and SSE is the sum of squared error for the HR and FA generated for
% that rule, compared to the data.
%
% DATA = an Nx4 matrix of values for [K SS HR FA]
%         K = Capacity for max model
%        SS = Vector of set sizes tested
%        HR = Vector of hit rates for SS
%        FA = Vector of false alarm rates for SS
% START_PARAMS =  [S C] (not required)
%         S = Single Channel Sensitivity (d' @ set size 1)
%         C = Criterion
% OPTIONS = options for fminsearch routine (not required)
%
% MAXRULEFIT is an attempt to find the sensitivity and criterion for each
% set size that best matches the empirical data collected in the Crossover
% Experiment.
%
%
% Sample data: K SS HR   FA
%             [8 1 .855 .040;
%              8 2 .905 .170;
%              8 4 .785 .135;
%              8 8 .720 .085]
%

[n,m]=size(data);
if m ~= 4
   error('First argument must be an Nx4 vector.');
end
% if  n == 1        	                   %case of a row vector of data
% 	data = data';
% 	n = m;
% end
% if min(data)<=0                  	   % get rid of zeros and negative numbers
% 	warning('WARNING data include zero(s) and/or negative number(s)\n');
% 	nc=length(find(data<=0));
% 	fprintf('%d values out of %d are truncated\n', nc, n);
% 	data=data(find(data>0));
% end

if  (nargin > 1 && ~isempty(params))   % explicit starting parameter values set by user
	S_start=params(1);
	C_start=params(2);
else    
	S_start=norminv(data(1,3))-norminv(data(1,4));  % set defaut starting parameter values if not explicit
	C_start=S_start/2;                            % uses heuristic values. S = empirical d' @ ss=1
end

if  (nargin > 2 && ~isempty(options))  % explicit options values set by user and pass to fmins
	opts(1:3)=options(1:3);           % trace, termination and function tolerances
	opts(14)=options(4);              % maximum number of iterations
else
	opts=[0, 1.e-4,1.e-4];            % default values for trace, termination and function tolerances
    opts(1,4)=5000;                   % default max number of iterations (arbitrary number)
end

pinit = [S_start C_start];                % put initial parameter values in an array
   LB = [-10     -10];
   UB = [10       10];

[R,LogL,exitflag] = fminsearchbnd('maxruleSSE2',pinit,LB,UB,opts,data);

if nargout == 0
   % if no output arguments, then just print the results
   fprintf('S = \n'); S=R(1); disp(S);
   fprintf('C = \n'); C=R(2); disp(C);
   fprintf('SSE = \n'); SSE=maxruleSSE2(R,data); disp(SSE);
elseif nargout == 1
   S=R(1);
elseif nargout == 2
   S=R(1);
   C=R(2);
elseif nargout >=3
   S=R(1);
   C=R(2);
   SSE=maxruleSSE2(R,data);
end



