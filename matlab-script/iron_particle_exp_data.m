%% 弯管段铁屑床迁移模型曲线（对应正文式 Q^2(theta_c) = A + B*sin(theta_c)）
% 用途：复现正文报告的模型曲线、基准启动流量及其 95% 置信区间端点；
%      实验标定点（20 个）待补充后叠加显示。
clear; clc; close all;

A = 208.57;          % 基线项，(m^3/h)^2
B = 122.69;          % 重力切向分量系数，(m^3/h)^2
Aci = [202.43, 216.75];   % A 的 Bootstrap 95% 置信区间
Bci = [107.72, 134.89];   % B 的 Bootstrap 95% 置信区间

theta = linspace(0, 72, 100);                     % 弯管角度 theta_c，(度)
q = sqrt(A + B*sin(theta*pi/180));                % 流量 Q，(m^3/h)，由 Q^2 = A + B*sin(theta_c) 反解

% TODO(待补)：读入 20 个标定实验点并叠加散点与误差棒
% theta_exp = [...]；
% q_exp     = [...]；
% plot(theta_exp, q_exp, 'ko', 'MarkerFaceColor', 'w', 'LineWidth', 1.0);

fprintf('模型基准启动流量 Q0 = %.2f m^3/h（95%% 区间 %.2f-%.2f m^3/h）\n', ...
    sqrt(A), sqrt(Aci(1)), sqrt(Aci(2)));

figure('Color', 'w');
plot(theta, q, 'b-', 'LineWidth', 1.5);
grid on; box on;
xlabel('弯管角度 \theta_c / (^\circ)');
ylabel('流量 Q / (m^3 \cdot h^{-1})');
title('弯管段铁屑床迁移模型');
legend('式(2) 模型曲线', 'Location', 'northwest');

% 注意：导出文件名与正文实验标定图区分，避免覆盖 bed-position-VS-flow-rate-inclined-section.png
exportgraphics(gcf, 'bend-migration-model-curve.png', 'Resolution', 300);

