% Чтение и визуализация исходного изображения
filepath = "C:\Users\Lisa\Desktop\для НИРС\Отчет\datasets\1\img (1).dcm";
img = dicomread(filepath); 
figure, imshow(img,[]); title("Исходное изображение");

% Поворот
rotateImg1 = imrotate(img, 10);
figure, subplot(1,2,1), imshow(rotateImg1,[]); title("Изображение при повороте на 10 градусов против часовой стрелки");
dicomwrite(rotateImg1, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\rotateImg10.dcm");

rotateImg2 = imrotate(img, -20);
subplot(1,2,2), imshow(rotateImg2,[]); title("Изображение при повороте на 20 градусов по часовой стрелке");
dicomwrite(rotateImg2, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\rotateImg20.dcm");

% Масштабирование
reductionImg = imresize(img, 0.5);
restoredImg = imresize(reductionImg, 2);
figure, subplot(1,2,1), imshow(restoredImg,[]); title("Изображение после сжатия и растяжения в 2 раза");
dicomwrite(restoredImg, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\scaledImg.dcm");

diffImg = img - restoredImg;
subplot(1,2,2), imshow(diffImg,[]); title("Разность между исходным и дважды масштабированным изображением");

% Добавление шума
% Гауссовский шум
img
gaussianImg = imnoise(img*255, 'gaussian', 0.3, 0.01);
figure, subplot(1,2,1), imshow(gaussianImg,[]); title("Изображение с гауссовским шумом");
dicomwrite(gaussianImg, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\gaussianImg.dcm");

% Импульсный шум
spImg = imnoise(img*255, 'salt & pepper', 0.03);
subplot(1,2,2), imshow(spImg,[]); title("Изображение с шумом соль и перец");
dicomwrite(spImg, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\spImg.dcm");

% Медианная фильтрация
medianImg = medfilt2(img,[5 5]);
figure, imshow(medianImg,[]); title("Изображение после медианной фильтрации");
dicomwrite(medianImg, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\medianImg.dcm");

% фильтр Виннера
wienerImg = wiener2(img,[5 5], 0.3);
figure, imshow(wienerImg,[]); title("Изображение после фильтра Виннера");
dicomwrite(wienerImg, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\wienerImg.dcm");

% сглаживание по Гауссу
gaussFiltImg = imgaussfilt(img, 2);
figure, imshow(gaussFiltImg,[]); title("Изображение после сглаживания по Гауссу");
dicomwrite(gaussFiltImg, "C:\Users\Lisa\Desktop\для НИРС\Отчет\task_6\gaussFiltImg.dcm");









