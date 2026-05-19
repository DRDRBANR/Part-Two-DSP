t = 0:0.5:10;
x = sin(t);

y_out = resample(x, 3, 5);

figure;
% Построение исходного сигнала 
plot(1:3:length(x)*3, x, 'ko-', 'LineWidth', 1.5, 'MarkerSize', 8);
hold on;

% Построение полученного сигнала
plot(1:5:length(y_out)*5, y_out, 'r*', 'LineWidth', 1.5, 'MarkerSize', 8);

legend('Исходный сигнал', 'Результат resample(x, 3, 5)');
title('Дробное ресэмплирование (3/5) встроенной функцией');
grid on;