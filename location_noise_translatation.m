r = 10;
theta = pi/4;
var_theta = deg2rad(5)^2;
var_r = 0.01^2;

Sigma_sensor = r*r*var_theta*var_theta/2*[2*sin(theta)^2 -sin(2*theta); -sin(2*theta) 2*cos(theta)^2]+...
    var_r*var_r/2 * [2*cos(theta)^2 sin(2*theta); sin(2*theta) 2*sin(theta)^2];
mu = [cos(theta)*r sin(theta)*r];

Sigma_robot = [0.1^2 0.0^2; 0.0^2 0.1^2];

Sigma =  Sigma_sensor + Sigma_robot;

x1 = 0:0.01:10; x2=0:0.01:10;

[X1,X2] = meshgrid(x1,x2);
F = mvnpdf([X1(:) X2(:)],mu,Sigma);
F = reshape(F,length(x2),length(x1));

mvncdf([0 0],[1 1],mu,Sigma);
contour(x1,x2,F,[.0001 .001 .01 .05:.1:.95 .99 .999 .9999]);
xlabel('x'); ylabel('y');
%line([0 0 1 1 0],[1 0 0 1 1],'linestyle','--','color','k');