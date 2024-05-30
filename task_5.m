% filepath = "C:\Users\Lisa\Desktop\для НИРС\nirs\datasets\2.dcm";
filepath = "C:\Users\Lisa\Desktop\для НИРС\Отчет\datasets\7\img (1).dcm";
% Чтение файла
img = dicomread(filepath);

% Просмотр изображения
imshow(img,[]);

% Вывести описание файла
disp("Описание файла: ");
dicomdisp(filepath);

% Высота и ширина изображения (количество пикселей в кадре)
info = dicominfo(filepath)
disp("Ширина изображения: ");
info.Rows

disp("Высота изображения: ");
info.Columns

% Количество бит на пиксель (размер пикселя)
disp("Размер пикселя (бит/пиксель): ");
info.BitDepth

% Минимальное максимальное значение
[minA,maxA] = bounds(img, "all");
disp("Минимальное значение пикселя: ");
minA
disp("Максимальное значение пикселя: ");
maxA
