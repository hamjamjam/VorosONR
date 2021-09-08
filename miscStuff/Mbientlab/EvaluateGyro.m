function [NewData, angles, Cov, bias] = EvaluateGyro(Xall,Yall,Zall,Truth,bounds)

Zm = max(Zall);
i = find(Zall==Zm);
Xm = Xall(i(1));
Ym = Yall(i(1));

% Search for Euler Angles tx and ty
fun = @(x) [0 0 -1]*[1 0 0;0 cos(x(1)) -sin(x(1));0 sin(x(1)) cos(x(1))]*[cos(x(2)) 0 -sin(x(2)); 0 1 0;sin(x(2)) 0 cos(x(2))]*[Xm;Ym;Zm];
p = fminsearch(fun,[0 0]);
tx = p(1);
ty = p(2);

QY = [cos(ty) 0 -sin(ty); 0 1 0;sin(ty) 0 cos(ty)];
QX = [1 0 0;0 cos(tx) -sin(tx);0 sin(tx) cos(tx)];

NewData = QX*QY*[Xall, Yall, Zall]';
Xnew = NewData(1,bounds(1):bounds(end))';
Ynew = NewData(2,bounds(1):bounds(end))';
Znew = NewData(3,bounds(1):bounds(end))';

% Noise Cov of measurements
CovXY = cov(Xnew-Truth(1),Ynew-Truth(2));
CovXZ = cov(Xnew-Truth(1),Znew-Truth(3));
CovYZ = cov(Ynew-Truth(2),Znew-Truth(3));

angles = [tx;ty];
Cov = [CovXY(1,1) CovXY(1,2) CovXZ(1,2);CovXY(1,2) CovXY(2,2), CovYZ(1,2);CovXZ(1,2) CovYZ(1,2) CovXZ(2,2)];
bias = [mean(Xnew)-Truth(1);mean(Ynew)-Truth(2);mean(Znew)-Truth(3)];

end