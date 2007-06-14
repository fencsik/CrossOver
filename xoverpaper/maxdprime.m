function [dprime, criterion] = maxdprime (hr, fa, n, method)

% maxdprime calculates d' and criterion for a search task assuming
% that response is based on the maximum of target and distractor
% signals
%
% [dprime, criterion] = maxdprime(HitRate, FalseAlarmRate, SetSize)
% computes d' and criterion based on the given hit rate, false alarm
% rate, and set size.  If output arguments are omitted, then d' and
% criterion will be printed on the command window.
%
% [dprime, criterion] = maxdprime(HitRate, FalseAlarmRate, SetSize, Method)
% allows for different computational methods to be used (Method is a
% case-insensitive string).  Currently, only the 'Palmer' method is
% implemented (based on Palmer, Ames, & Lindsey, 1993).

% Author: David Fencsik <fencsik@gmail.com>
% $LastChangedDate$

if nargin < 4
   method = 'palmer';
end
if nargin < 3
   error('at least three arguments are required');
end

if strcmpi(method, 'palmer')
   c = Finv((1 - fa) .^ (1 ./ n));
   d = c - Finv((1 - hr) ./ (F(c) .^ (n - 1)));
else
   error('requested method ''%s'' is not supported', num2str(method));
end

if nargout == 0
   fprintf('d'' = %0.3f\ncriterion = %0.3f\n\n', d, c);
elseif nargout == 1
   dprime = d;
elseif nargout >= 2
   dprime = d;
   criterion = c;
end


function p = F(x)
p = normcdf(x, 0, 1);


function x = Finv(p)
x = norminv(p, 0, 1);
