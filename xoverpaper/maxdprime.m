function [dprime, criterion] = maxdprime (hr, fa, n, method)

% $LastChangedDate$

if nargin < 4
   method = 'palmer';
end
if nargin < 3
   error('at least three arguments are required');
end

if strcmp(method, 'palmer')
   c = Finv((1 - fa) .^ (1 / n));
   d = c - Finv((1 - hr) / (F(c) .^ (n - 1)));
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
