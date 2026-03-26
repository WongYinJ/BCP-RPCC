function [y] = xlnx(x,tol)
%XLNX 此处显示有关此函数的摘要
%   此处显示详细说明
y=zeros(size(x));
ind=x>tol;
y(ind)=x(ind).*log(x(ind));
end

