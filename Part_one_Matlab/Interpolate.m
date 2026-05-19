t = 0:0.5:10;       
x = sin(t);         
L = 3;              
N_in = length(x);

x_up = zeros(1, length(x) * L);
for i = 1:length(x)
    x_up((i - 1) * L + 1) = x(i);
end

b = [1/3, 2/3, 1, 2/3, 1/3];
M = length(b);         
N_out = length(x_up);  
y = zeros(1, N_out);   

for n = 1:N_out
    summa = 0;
    for k = 1:M
        index = n - k + 1; 
        
        if index > 0 && index <= N_out 
            summa = summa + b(k) * x_up(index);
        end
    end
    y(n) = summa; 
end
figure; 
plot(y(3:end), 'r*', 'LineWidth', 1.5, 'MarkerSize', 8); 
hold on; 
plot(1:L:length(x)*L, x, 'ko-', 'LineWidth', 1.5, 'MarkerSize', 8);
%plot(x_up, 'ro'); 

legend('Сигнал после сэмплирования (y)', 'Исходные сигнал (x_up)');
title('Результат ручной интерполяции в 3 раза');
grid on;