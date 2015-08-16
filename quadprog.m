## Copyright (C) 2015 Asma Afzal
## Copyright (C) 2013-2015 Julien Bect
## Copyright (C) 2000-2015 Gabriele Pannocchia
##
## Octave is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} quadprog (@var{H}, @var{f})
## @deftypefnx {Function File} {} quadprog (@var{H}, @var{f}, @var{A}, @var{b})
## @deftypefnx {Function File} {} quadprog (@var{H}, @var{f}, @var{A}, @var{b}, @var{Aeq}, @var{beq})
## @deftypefnx {Function File} {} quadprog (@var{H}, @var{f}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub})
## @deftypefnx {Function File} {} quadprog (@var{H}, @var{f}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub}, @var{x0})
## @deftypefnx {Function File} {} quadprog (@var{H}, @var{f}, @var{A}, @var{b}, @var{Aeq}, @var{beq}, @var{lb}, @var{ub}, @var{x0}, @var{options})
## @deftypefnx {Function File} {[@var{x}, @var{fval}, @var{exitflag}, @var{output}, @var{lambda}] =} quadprog (@dots{})
## Solve the quadratic program
## @example
## @group
## min 0.5 x'*H*x + x'*f
##  x
## @end group
## @end example
## subject to
## @example
## @group
## @var{A}*@var{x} <= @var{b},
## @var{Aeq}*@var{x} = @var{beq},
## @var{lb} <= @var{x} <= @var{ub}.
## @end group
## @end example
##
## The initial guess @var{x0} and the constraint arguments (@var{A} and
## @var{b}, @var{Aeq} and @var{beq}, @var{lb} and @var{ub}) can be set to
## the empty matrix (@code{[]}) if not given.  If the initial guess
## @var{x0} is feasible the algorithm is faster.
##
## @var{options} can be set with @code{optimset}, currently the only
## option is @code{MaxIter}, the maximum number of iterations (default:
## 200).
##
## Returned values:
##
## @table @var
## @item x
## Position of minimum.
##
## @item fval
## Value at the minimum.
##
## @item exitflag
## Status of solution:
##
## @table @code
## @item 0
## Maximum number of iterations reached.
##
## @item -2
## The problem is infeasible.
##
## @item -3
## The problem is not convex and unbounded
##
## @item 1
## Global solution found.
##
## @item 4
## Local solution found.
## @end table
##
## @item output
## Structure with additional information, currently the only field is
## @code{iterations}, the number of used iterations.
##
## @item lambda
## Structure containing Lagrange multipliers corresponding to the
## constraints.
##
## @end table
##
## This function calls Octave's @code{__qp__} back-end algorithm internally.
## @end deftypefn

## PKG_ADD: __all_opts__ ("quadprog");

 function varargout = quadprog (H, f, varargin)

  if (nargin == 1 && ischar (H) && strcmp (H, "defaults"))
    varargout{1} = optimset ("MaxIter", 200);
    return;
  endif

  nargs = nargin;
  n_out = nargout ();
  varargout = cell (1, n_out);

  if (nargs < 2 || nargs == 3 || nargs == 5 || nargs == 7 || nargs > 10)
    print_usage();
  endif

  ## Checking the quadratic penalty
  if (! issquare (H))
    error ("Quadratic penalty matrix not square");
  elseif (! ishermitian (H))
    ## warning ("qp: quadratic penalty matrix not hermitian");
    H = (H + H')/2;
  endif
  n = rows (H);

  ## Linear penalty.
  if (isempty (f))
    f = zeros (n, 1);
  elseif (numel (f) != n)
    error ("The linear term has incorrect length");
  endif

  if (nargs > 2)
    A_in = varargin{1};
    b_in = varargin{2};
  else
    A_in = [];
    b_in = [];
  endif

  if (nargs > 4)
    Aeq = varargin{3};
    beq= varargin{4};
  else
    Aeq = [];
    beq = [];
  endif

  if (nargs > 6)
    lb = varargin{5};
    ub = varargin{6};
  else
    lb = [];
    ub = [];
  endif

  if (nargs >= 9)
    x0 = varargin{7};
  else
    x0 = [];
  endif

  options = struct ();

  if (nargs == 10)
    if (isstruct (varargin{8}))
      options = varargin{8};
    endif
  endif

  maxit = optimget (options, "MaxIter", 200);

  ## Checking the initial guess (if empty it is resized to the
  ## right dimension and filled with 0)
  if (isempty (x0))
    x0 = zeros (n, 1);
  elseif (numel (x0) != n)
    error ("The initial guess has incorrect length");
  endif

  lambda = struct ("lower", [], "upper", [], "eqlin", [], "ineqlin", []);

  ## Inequality constraint matrices
  A = zeros (0, n);
  b = zeros (0, 1);
  if (! isempty (A_in) && ! isempty (b_in))
    [dimA_in, n1] = size (A_in);
    if (n1 != n)
      error ("Inequality constraint matrix has incorrect column dimension");
    endif
    if (numel (b_in) != dimA_in)
      error ("Inequality constraint matrix and upper bound vector inconsistent");
    endif
    A = [A; -A_in];
    b = [b; -b_in];
    idx_ineq = isinf (b_in) & b_in < 0;
    lambda.ineqlin = zeros (n, 0);
    ## Discard inequality constraints that have -Inf bounds since those
    ## will never be active but keep the index for ordering of lambda.
    b(idx_ineq) = [];
    A(idx_ineq,:) = [];
  elseif (isempty (A_in) && ! isempty (b_in) || ! isempty (A_in) && isempty (b_in))
    error("The number of rows in A must be the same as the length of b")
  endif
  ## Equality constraint matrices
  if (isempty (Aeq) || isempty (beq))
    Aeq = zeros (0, n);
    beq= zeros (0, 1);
    n_eq = 0;
  else
    [n_eq, n1] = size (Aeq);
    if (n1 != n)
      error ("Equality constraint matrix has incorrect column dimension");
    endif
    if (numel (beq) != n_eq)
      error ("Equality constraint matrix and vector have inconsistent dimension");
    endif
    lambda.eqlin = zeros (n, 0);
  endif

  ## Bound constraints
  n_in = 0;
  if (nargs > 5)
    if (! isempty (lb))
      if (numel (lb) != n)
        error ("Lower bound has incorrect length");
      elseif (isempty (ub))
        A = [A; eye(n)];
        b = [b; lb];
      endif
      idx_lb = isinf (lb) & lb < 0;
      lambda.lower = zeros (0, n);
    endif

   if (! isempty (ub))
      if (numel (ub) != n)
        error ("Upper bound has incorrect length");
      elseif (isempty (lb))
        A = [A; -eye(n)];
        b = [b; -ub];
      endif
      idx_ub = isinf (ub) & ub < 0;
      lambda.upper = zeros (0, n);
   endif
   count_not_ineq = 0;
   idx_bounds_ineq = true(n,1);
   if (! isempty (lb) && ! isempty (ub))
      rtol = sqrt (eps);
      A_lb =[];
      for i = 1:n;
        if (abs (lb (i) - ub(i)) < rtol*(1 + max (abs (lb(i) + ub(i)))))
          ## These are actually an equality constraint
          idx_bounds_ineq (i) = false;
          tmprow = zeros (1,n);
          tmprow(i) = 1;
          Aeq = [Aeq; tmprow];
          beq = [beq; 0.5*(lb(i) + ub(i))];
          n_eq = n_eq + 1;
        else
          tmprow = zeros (1,n);
          tmprow(i) = 1;
          A_lb = [A_lb; tmprow];
        endif
      endfor
      count_not_ineq = sum (! idx_bounds_ineq);
      lb = lb(idx_bounds_ineq); ub = ub(idx_bounds_ineq);
      A = [A; A_lb; -A_lb];
      b = [b; lb; -ub];
    endif
  endif

  ## Now we should have the following QP:
  ##
  ##   min_x  0.5*x'*H*x + x'*q
  ##   s.t.   Aeq*x = beq
  ##          A*x >= b

  n_in = numel (b);

  ## Check if the initial guess is feasible.
  if (isa (x0, "single") || isa (H, "single") || isa (f, "single")
      || isa (Aeq, "single") || isa (beq, "single"))
    rtol = sqrt (eps ("single"));
  else
    rtol = sqrt (eps);
  endif

  eq_infeasible = (n_eq > 0 && norm (Aeq * x0 - beq) > rtol * (1 + abs (beq)));
  in_infeasible = (n_in > 0 && any (A * x0 - b < -rtol * (1 + abs (b))));

  exitflag = 0;

  if (eq_infeasible || in_infeasible)
      ## The initial guess is not feasible.
      ## First define xbar that is feasible with respect to the equality
      ## constraints.
      if (eq_infeasible)
        if (rank (Aeq) < n_eq)
          error ("Equality constraint matrix must be full row rank");
        endif
        xbar = pinv (Aeq) * beq;
      else
        xbar = x0;
      endif

    ## Check if xbar is feasible with respect to the inequality
    ## constraints also.
    if (n_in > 0)
      res = A * xbar - b;
      if (any (res < -rtol * (1 + abs (b))))
        ## xbar is not feasible with respect to the inequality
        ## constraints.  Compute a step in the null space of the
        ## equality constraints, by solving a QP.  If the slack is
        ## small, we have a feasible initial guess.  Otherwise, the
        ## problem is infeasible.
        if (n_eq > 0)
          Z = null (Aeq);
          if (isempty (Z))
            ## The problem is infeasible because Aeq is square and full
            ## rank, but xbar is not feasible.
            exitflag = 6;
          endif
        endif

        if (exitflag != 6)
          ## Solve an LP with additional slack variables to find
          ## a feasible starting point.
          gamma = eye (n_in);
          if (n_eq > 0)
            Atmp = [A*Z, gamma];
            btmp = -res;
          else
            Atmp = [A, gamma];
            btmp = b;
          endif
          ctmp = [zeros(n-n_eq, 1); ones(n_in, 1)];
          lb = [-Inf(n-n_eq,1); zeros(n_in,1)];
          ub = [];
          ctype = repmat ("L", n_in, 1);
          [P, dummy, status] = glpk (ctmp, Atmp, btmp, lb, ub, ctype);
          if ((status == 0)
              && all (abs (P(n-n_eq+1:end)) < rtol * (1 + norm (btmp))))
            ## We found a feasible starting point
            if (n_eq > 0)
              x0 = xbar + Z * P(1:n-n_eq);
            else
              x0 = P(1:n);
            endif
          else
            ## The problem is infeasible
            exitflag = 6;
          endif
        endif
      else
        ## xbar is feasible.  We use it a starting point.
        x0 = xbar;
      endif
    else
      ## xbar is feasible.  We use it a starting point.
      x0 = xbar;
    endif
  endif

  if (exitflag == 0)
    ## The initial (or computed) guess is feasible.
    ## We call the solver.
     [x, qp_lambda, exitflag, iter] = __qp__ (x0, H, f, Aeq, beq, A, b, maxit);

  else
    iter = 0;
    x = x0;
  endif

 varargout{1} = x;

  if (n_out >= 2)
    varargout{2} = 0.5 * x' * H * x + f' * x;;
  endif

  if (n_out >= 3)
    switch (exitflag)
      case 0
        varargout{3} = 1;
      case 1
        varargout{3} = 4;
      case 2
        varargout{3} = -3;
      case 3
        varargout{3} = 0;
      case 6
        varargout{3} = -2;
    endswitch
  endif

  if (n_out >= 4)
    varargout{4}.iterations = iter;
  endif

  if (n_out >= 5 && exitflag == 0)
    lm_idx=1; lambda_not_ineq = [];
    if (nargs > 4 && (! isempty (varargin{3}) && ! isempty (varargin{4}) || count_not_ineq > 0))
      lambda.eqlin = qp_lambda(lm_idx:lm_idx + n_eq - count_not_ineq - 1);
      lambda_not_ineq = qp_lambda(lm_idx + n_eq - count_not_ineq: lm_idx + n_eq -1);
      lm_idx = lm_idx + n_eq;
    endif

    if (nargs > 2 && ! isempty (varargin{1}) && ! isempty (varargin{2}))
      ineq_tmp = qp_lambda(lm_idx:lm_idx + sum (! idx_ineq) - 1);
      lambda.ineqlin = ineq_tmp;
      lm_idx = lm_idx + sum (! idx_ineq);
    endif

    if (nargs > 6 && ! isempty (varargin{5}))
      lb_tmp = qp_lambda(lm_idx:lm_idx + sum (! idx_lb) - count_not_ineq - 1);
      idx = idx_bounds_ineq & ! idx_lb;
      lambda.lower(idx) = lb_tmp;
      lambda.lower(! idx) = 0;
      lambda.lower = lambda.lower(:);
      lm_idx = lm_idx + sum (! idx_lb) - count_not_ineq;
    endif

    if (nargs > 7 && ! isempty (varargin{6}))
      ub_tmp = qp_lambda(lm_idx:lm_idx + sum (! idx_ub) - count_not_ineq - 1);
      idx = idx_bounds_ineq & ! idx_ub;
      lambda.upper(idx) = ub_tmp;
      lambda.upper(! idx) = 0;
      lambda.upper(! idx_bounds_ineq) = lambda_not_ineq;
      lambda.upper = lambda.upper(:);
    endif
    varargout{5}.lower = lambda.lower;
    varargout{5}.upper = lambda.upper;
    varargout{5}.eqlin = lambda.eqlin;
    varargout{5}.ineqlin = lambda.ineqlin;
  endif

endfunction

%!test
%! H= diag([1; 0]);
%! f = [3; 4];
%! A= [-1 -3; 2 5; 3 4];
%! b = [-15; 100; 80];
%! l= zeros(2,1);
%! [x,fval,exitflag,output] = quadprog(H,f,A,b,[],[],l,[])
%! assert(x,[0;5])
%! assert(fval,20)
%! assert(exitflag,1)
%! assert(output.iterations,1)

%!demo
%!  C = [0.9501    0.7620    0.6153    0.4057
%!      0.2311    0.4564    0.7919    0.9354
%!      0.6068    0.0185    0.9218    0.9169
%!      0.4859    0.8214    0.7382    0.4102
%!      0.8912    0.4447    0.1762    0.8936];
%!  %% Linear Inequality Constraints
%!  d = [0.0578; 0.3528; 0.8131; 0.0098; 0.1388];
%!  A =[0.2027    0.2721    0.7467    0.4659
%!      0.1987    0.1988    0.4450    0.4186
%!      0.6037    0.0152    0.9318    0.8462];
%!  b =[0.5251; 0.2026; 0.6721];
%!  %% Linear Equality Constraints
%!  Aeq = [3 5 7 9];
%!  beq = 4;
%!  %% Bound constraints
%!  lb = -0.1*ones(4,1);
%!  ub = ones(4,1);
%!  H = C' * C;
%!  f = -C' * d;
%!  [x, obj, flag, output, lambda]=quadprog (H, f, A, b, Aeq, beq, lb, ub)