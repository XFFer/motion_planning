clc;clear;close all
v_max = 400;
a_max = 400;
color = ['r', 'b', 'm', 'g', 'k', 'c', 'c'];

%% specify the center points of the flight corridor and the region of corridor
path = [50, 50;
       100, 120;
       180, 150;
       250, 80;
       280, 0];
x_length = 100;
y_length = 100;

n_order = 7;   % 8 control points
n_seg = size(path, 1);

corridor = zeros(4, n_seg);
for i = 1:n_seg
    corridor(:, i) = [path(i, 1), path(i, 2), x_length/2, y_length/2]';
end

%% specify ts for each segment
ts = zeros(n_seg, 1);
for i = 1:n_seg
    ts(i,1) = 1;
end

poly_coef_x = MinimumSnapCorridorBezierSolver(1, path(:, 1), corridor, ts, n_seg, n_order, v_max, a_max);
poly_coef_y = MinimumSnapCorridorBezierSolver(2, path(:, 2), corridor, ts, n_seg, n_order, v_max, a_max);

%% display the trajectory and cooridor
plot(path(:,1), path(:,2), '*r'); hold on;
for i = 1:n_seg
    plot_rect([corridor(1,i);corridor(2,i)], corridor(3, i), corridor(4,i));hold on;
end
hold on;
x_pos = [];y_pos = [];
idx = 1;

%% #####################################################
% STEP 4: draw bezier curve
for k = 1:n_seg
    for t = 0:0.01:1
        x_pos(idx) = 0.0;
        y_pos(idx) = 0.0;
        for i = 0:n_order
            basis_p = nchoosek(n_order, i) * t^i * (1-t)^(n_order-i);
%             x_pos(idx) = 
                x_pos(idx) = x_pos(idx) + basis_p * poly_coef_x((k-1)*(n_order+1)+i+1);
%             y_pos(idx) = 
                y_pos(idx) = y_pos(idx) + basis_p * poly_coef_y((k-1)*(n_order+1)+i+1);
        end
        
        idx = idx + 1;
    end
    
end
% scatter(...);
scatter(poly_coef_x(1:8,1), poly_coef_y(1:8,1),20,'b', 'filled'); 
scatter(poly_coef_x(9:16,1), poly_coef_y(9:16,1),20,'m', 'filled'); 
scatter(poly_coef_x(17:24,1), poly_coef_y(17:24,1),20,'g', 'filled'); 
scatter(poly_coef_x(25:32,1), poly_coef_y(25:32,1),20,'k', 'filled'); 
scatter(poly_coef_x(33:40,1), poly_coef_y(33:40,1),20,'c', 'filled'); 
% plot(...);
plot(x_pos(1:100),y_pos(1:100), 'b', 'LineWidth', 1);
plot(x_pos(101:200),y_pos(101:200), 'm', 'LineWidth', 1);
plot(x_pos(201:300),y_pos(201:300), 'g', 'LineWidth', 1);
plot(x_pos(301:400),y_pos(301:400), 'k', 'LineWidth', 1);
plot(x_pos(401:500),y_pos(401:500), 'c', 'LineWidth', 1);

function poly_coef = MinimumSnapCorridorBezierSolver(axis, waypoints, corridor, ts, n_seg, n_order, v_max, a_max)
    start_cond = [waypoints(1), 0, 0];
    end_cond   = [waypoints(end), 0, 0];   
    
    %% #####################################################
    % STEP 1: compute Q_0 of c'Q_0c
    [Q, M]  = getQM(n_seg, n_order, ts);
    Q_0 = M'*Q*M;
    Q_0 = nearestSPD(Q_0);
    
    %% #####################################################
    % STEP 2: get Aeq and beq
    [Aeq, beq] = getAbeq(n_seg, n_order, ts, start_cond, end_cond);
    Aeq = Aeq * M;
    %% #####################################################
    % STEP 3: get corridor_range, Aieq and bieq 
    
    % STEP 3.1: get corridor_range of x-axis or y-axis,
    % you can define corridor_range as [p1_min, p1_max;
    %                                   p2_min, p2_max;
    %                                   ...,
    %                                   pn_min, pn_max ];
    if axis == 1
        for i = 1:n_seg
            corridor_range(i, 1) = corridor(1,i) - corridor(3,i) ;
            corridor_range(i, 2) = corridor(1,i) + corridor(3,i) ;
        end

    
    elseif axis == 2
        for i = 1:n_seg
            corridor_range(i, 1) = corridor(2,i) - corridor(4,i) ;
            corridor_range(i, 2) = corridor(2,i) + corridor(4,i) ;
        end
    end  
    
    % STEP 3.2: get Aieq and bieq
    [Aieq, bieq] = getAbieq(n_seg, n_order, corridor_range, ts, v_max, a_max);
    
    f = zeros(size(Q_0,1),1);
    poly_coef = quadprog(Q_0,f,Aieq, bieq, Aeq, beq);
end

function plot_rect(center, x_r, y_r)
    p1 = center+[-x_r;-y_r];
    p2 = center+[-x_r;y_r];
    p3 = center+[x_r;y_r];
    p4 = center+[x_r;-y_r];
    plot_line(p1,p2);
    plot_line(p2,p3);
    plot_line(p3,p4);
    plot_line(p4,p1);
end

function plot_line(p1,p2)
    a = [p1(:),p2(:)];    
    plot(a(1,:),a(2,:),'b');
end