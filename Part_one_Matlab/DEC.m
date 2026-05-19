t = 0:0.5:10;
x = sin(t);         
L = 3;              
M = 5;              

% Интерполяция (Увеличение частоты в L=3 раз)
N_in = length(x);
x_up = zeros(1, N_in * L);
for i = 1:N_in
    x_up((i - 1) * L + 1) = x(i); 
end

% Фильтрация
% Частота среза ФНЧ берется как 1/max(L, M), поэтому 1/M (т.к. 5 > 3).
b = L * fir1(30, 1/M); 
M_filt = length(b);
N_up = length(x_up);
y_filtered = zeros(1, N_up);

for n = 1:N_up
    summa = 0;
    for k = 1:M_filt
        index = n - k + 1; % Смещение во времени
        if index > 0 && index <= N_up
            summa = summa + b(k) * x_up(index);
        end
    end
    y_filtered(n) = summa;
end

% Вычисляем задержку фильтра
delay = (M_filt - 1) / 2; 

y_shifted = y_filtered(delay + 1 : end);
y_out = y_shifted(1:M:end);

figure;
% Исходный сигнал (шаг L)
plot(1:L:N_in*L, x, 'ko-', 'LineWidth', 1.5, 'MarkerSize', 8);
hold on;

% Итоговый сигнал (шаг M).
t_out = 1:M:(length(y_out) * M);
plot(t_out, y_out, 'r*', 'LineWidth', 1.5, 'MarkerSize', 8);

legend('Исходный сигнал', 'После ресэмплирования (3/5)');
title('Ресэмплирование с учетом задержки');
grid on;