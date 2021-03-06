clc
clear all
%k = 1:10;
%func = @(x) 2 + 2*k-exp(k*x(1))-exp(k*x(2));
%%x0 = [0.3; 0.5];                        % Starting guess
%x0=[0;0.5];
%********lsqnonlin==nonlin_residmin*******
%settings = optimset("TolFun",1e-9)
%[x1,resnorm] = lsqnonlin(func,x0,[],[], settings)  
%x = nonlin_residmin(func,x0)   
%[x,resnorm] = nonlin_residmin(func,x0)
%[x,resnorm,residual] = lsqnonlin(func,x0)
%[x,resnorm,flag] = nonlin_residmin(func,x0)
%[x,resnorm,residual,flag] = lsqnonlin(func,x0)

%%test
%ub = [1;1];
%opts = optimset('TolFun',1e-10, 'MAxITer', 1000, 'TolX', 1e-10 )
%[x,resnorm,residual,flag,output,lambda,jacobian] = lsqnonlin (func, x0, [], ub, opts)

%*********bounds********
%settings = optimset ("lbound",[0.3;0.3])
%settings = struct();%dummy options
%settings = optimset (settings,struct())
%settings = optimset ("lbound",[0.3;0.3])
%settings = optimset (settings,"ubound",[0.5;0.5])
%[x,resnorm] = nonlin_residmin(func,x0,settings)
%lb = [0.3;0.3];
%ub = [0.5;0.5];
%%[x,resnorm,residual] = lsqnonlin(func,x0,lb,[],struct())%empty upper bounds
%%[x,resnorm,residual] = lsqnonlin(func,x0,lb,ub,settings)%all 5 inputs
%[x,resnorm,residual] = lsqnonlin(func,x0,lb,[])

%****check row/col input
%x0 = [0.3 0.4];
%[x,resnorm,residual] = lsqnonlin(func,x0)

%******Settings*****
%settings = optimset("MaxIter",300)
%[x,resnorm,flag,output] = nonlin_residmin(func,x0,settings)
%lb = [0.3 0.3];
%ub = [0.5 0.5];
%[x,resnorm,residual,flag,output] = lsqnonlin(func,x0,settings)
%*********Lambda**********
%lb = [0.1;0.3];
%ub = [0.3; 0.1];
%settings = optimset (settings,"lbound", lb, "TolFun", 1e-30, "TolX", 1e-30);
%settings = optimset (settings,"ubound", ub)
%[x,resnorm,cvg,output] = nonlin_residmin(func,x0,settings);

%lb=[0.4 0.3]
%[x,resnorm,residual,flag,output,lambda,jacobian] = lsqnonlin(func,x0,lb)

%*******Jacobian*********
%settings=optimset(settings, "ret_dfdp", true);
%[x,resnorm,flag,output] = nonlin_residmin(func,x0,settings)
%[x,resnorm,residual,flag,output,lambda,jacobian] = lsqnonlin(func,x0)

%info = residmin_stat(func,x0,settings)
% x = [1:10:100]';
%func=@(p) p(1)*exp(-p(2)*x);
% p = [1; 0.1];
% data = func (p);
% rnd = [0.352509; -0.040607; -1.867061; -1.561283; 1.473191; ...
%        0.580767;  0.841805;  1.632203; -0.179254; 0.345208];
% wt1 = (1 + 0 * x) ./ sqrt (data); 
% data = data + 0.05 * rnd ./ wt1; 
%df=@ (p) [exp(-p(2)*x),-p(1)*x.*exp(-p(2)*x)];
%p0=[.8; .05]; 
%opts=optimset("dfdp",df);
%nonlin_residmin(@(p)func(p)-data,p0,opts)
%*******Eg.2
%
%t = [0 .3 .8 1.1 1.6 2.3];
%y = [.82 .72 .63 .60 .55 .50];
%yhat = @(c,t) c(1) + c(2)*exp(-t);
%opt = optimset('TolFun',1e-10)
%[c,res,resid,flag,out,lambda,jacob] = lsqnonlin(@(c)yhat(c,t)-y,[1 1],[0 0],[],opt)

%*****user specified jacobian*******
%t = [0 .3 .8 1.1 1.6 2.3];
%y = [.82 .72 .63 .60 .55 .50];
%c0=[1;1];
%opt=optimset("Jacobian","on");
%c = nonlin_residmin(@(c) myfun(c,t,y),c0,opt)
%c = lsqnonlin(@(c) myfun(c,t,y),c0,opt)
 x = 1:10:100;
 x=x';
 y=[9.2160e-001, 3.3170e-001, 8.9789e-002, 2.8480e-002, 2.6055e-002,...
     8.3641e-003,  4.2362e-003,  3.1693e-003,  1.4739e-004,  2.9406e-004]';
opts=optimset("Jacobian","on");
p0=[0.8;0.05];
p=lsqnonlin(@(p)diff(p,x,y),p0,[],[],opts) 

%*****Complex Input******

%N = 100; % number of observations
%v0 = [2;3+4i;-.5+.4i]; % coefficient vector
%xdata = -log(rand(N,1)); % exponentially distributed
%noisedata = randn(N,1).*exp((1i*randn(N,1))); % complex noise
%cplxydata = v0(1) + v0(2).*exp(v0(3)*xdata) + noisedata;
%objfcn = @(v)v(1)+v(2)*exp(v(3)*xdata) - cplxydata;
%x0 = (1+1i)*[1;1;1]; % arbitrary initial guess
%[vest,resnorm,exitflag,output] = nonlin_residmin(objfcn,real(x0))
%%%%%%%%%%Test Example%%%%%%%%%%%%%%%%%%%%


