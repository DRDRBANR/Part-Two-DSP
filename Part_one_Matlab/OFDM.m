rng('shuffle'); % Инициализация генератора случайных чисел от системного времени

% === ПАРАМЕТРЫ OFDM ПЕРЕДАТЧИКА (TX) ===
sc_spacing = 15000;     % 1. Subcarrier spacing (15 кГц)
fft_size = 16;          % 2. FFT Size (размер преобразования)
cp_size = 5;           % 3. CP Size (размер защитного интервала)

% Вид модуляции
QPSK = 4; QAM16 = 16; QAM64 = 64; QAM256 = 256;
M = QAM16;              % ВЫБОР ТЕКУЩЕЙ МОДУЛЯЦИИ

num_ofdm_symbols = 20;  % Генерируем сразу 20 OFDM-символов подряд
total_symbols = fft_size * num_ofdm_symbols; 

% РАСЧЕТ ВРЕМЕНИ
t_sub = 1 / sc_spacing;          
t_s = t_sub / fft_size;          % Шаг дискретизации (время одного отсчета в секундах)
t_s_micro = t_s * 1e6;           % Шаг дискретизации в МИКРОСЕКУНДАХ (мкс)
len_with_cp = fft_size + cp_size; 

% КОНВЕЙЕР ПЕРЕДАЧИ 
data_tx = randi([0, M-1], total_symbols, 1);
mod_symbols = qammod(data_tx, M);
freq_matrix = reshape(mod_symbols, fft_size, num_ofdm_symbols);
time_matrix = ifft(freq_matrix, fft_size);
cp_matrix = time_matrix(end - cp_size + 1 : end, :);
tx_signal_matrix = [cp_matrix; time_matrix];
tx_signal_final = tx_signal_matrix(:);

% ВЫДЕЛЕНИЕ ДАННЫХ ДЛЯ АНАЛИЗА CP 
sym1 = tx_signal_final(1 : len_with_cp);
cp_part = sym1(1 : cp_size);
tail_part = sym1(end - cp_size + 1 : end);


% ВИЗУАЛИЗАЦИЯ СОЗВЕЗДИЯ ТХ
figure;
plot(real(mod_symbols), imag(mod_symbols), 'b.', 'MarkerSize', 12);
grid on; axis square;
title(['Созвездие передатчика (TX): ', num2str(M)]);
xlabel('Синфазная составляющая (I)');
ylabel('Квадратурная составляющая (Q)');


% === ГРАФИК 2: ВИЗУАЛИЗАЦИЯ ВСЕГО ПАКЕТА В МИКРОСЕКУНДАХ ===
figure;
t_packet_micro = (0 : length(tx_signal_final)-1) * t_s_micro;
plot(t_packet_micro, real(tx_signal_final), 'b-', 'LineWidth', 1); hold on;
plot(t_packet_micro, imag(tx_signal_final), 'r-', 'LineWidth', 1);

% пунктирные линии границ OFDM-символов
time_per_symbol_micro = len_with_cp * t_s_micro;
for k = 1 : num_ofdm_symbols
    xline(k * time_per_symbol_micro, 'k--', 'LineWidth', 0.8);
end
title(['Осциллограмма пакета из ', num2str(num_ofdm_symbols), ' OFDM-символов']);
xlabel('Время, мкс (\mu s)'); ylabel('Амплитуда');
legend('Синфазная часть (I)', 'Квадратурная часть (Q)');
grid on;


% === ГРАФИК 3: ПРОВЕРКА CP ДЛЯ ОДНОГО СИМВОЛА В МИКРОСЕКУНДАХ ===
figure;

subplot(2,1,1);
t_sym_micro = (0 : length(sym1)-1) * t_s_micro;
plot(t_sym_micro, real(sym1), 'k-', 'LineWidth', 1.2); hold on;

% Подсвечиваем зоны CP и Хвоста
t_cp_micro = (0 : cp_size-1) * t_s_micro;
t_tail_micro = ((length(sym1) - cp_size) : length(sym1)-1) * t_s_micro;

plot(t_cp_micro, real(cp_part), 'g.', 'MarkerSize', 16);
plot(t_tail_micro, real(tail_part), 'r.', 'MarkerSize', 16);

xline(cp_size * t_s_micro, 'k--', 'Граница CP', 'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom');

grid on;
title('Анализ одного OFDM-символа (Зеленый = CP, Красный = Хвост-источник)');
xlabel('Время внутри символа, мкс (\mu s)'); ylabel('Амплитуда (Real)');
legend('Тело сигнала', 'Циклический префикс (CP)', 'Оригинальный хвост', 'Location', 'best');

subplot(2,1,2);
plot(t_cp_micro, real(cp_part), 'g-o', 'LineWidth', 2, 'MarkerSize', 6); hold on;
plot(t_cp_micro, real(tail_part), 'r--x', 'LineWidth', 1.5, 'MarkerSize', 8);
grid on;
title('Проверка совпадения: CP и Хвост наложены друг на друга');
xlabel('Длительность защитного интервала, мкс (\mu s)'); ylabel('Амплитуда (Real)');
legend('Вырезанный префикс CP', 'Оригинальный хвост', 'Location', 'best');

figure;

grid_to_plot = abs(fftshift(freq_matrix, 1));

% Строим карту матрицы
imagesc(1:num_ofdm_symbols, (-fft_size/2 : fft_size/2 - 1), grid_to_plot);
colorbar; 
colormap('jet'); 

title('Частотно-временная сетка (Frequency Domain Grid)');
xlabel('Номер OFDM-символа (Время)');
ylabel('Индекс поднесущей (Частота)');