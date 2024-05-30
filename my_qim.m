imgpath = "C:\Users\Lisa\Desktop\для НИРС\nirs-2024\datasets\1\img (2).dcm";
watermarkpath = "C:\Users\Lisa\Desktop\для НИРС\nirs-2024\ЦВЗ.png";

% deltas - известны всегда и выбираются впервые при встраивании в roi

run(imgpath, watermarkpath)

function run(imgpath, watermarkpath)
    % Вручную необходимо настроить размер блока и размер водяного знака,
    % который будет встраиваться
    % размер блока
    r = 8;
    % размеры водяного знака
    watermarkR = 64;
    watermarkC = 64;
    
    % заглашка пути до водяного знака для встраивания в roni
    emptyS = "";

    % % Визуализация входных данных
    % [roi, roni, watermark] = imgPreparation(imgpath, watermarkpath);
    % img = dicomread(imgpath);
    % figure, imshow(img,[]); title("Изначальное изображение");
    % figure, imshow(roi,[]); title("Область интереса");
    % figure, imshow(roni,[]); title("Область неинтереса");
    % figure, imshow(watermark,[]); title("Встраиваемый водяной знак");

    % встраивание в roi
    [roiAddWatermark, keyDeltas, keyRoi] = qimRoi(imgpath, watermarkpath, r);
    
    % встраивание в roni
    roniAddWatermark = qimRoni(imgpath, emptyS, keyRoi, keyDeltas);

    newImg = roniAddWatermark;
    newImg(60:429, 110:409) = roiAddWatermark;
    figure, imshow(newImg,[]); title("Изображение после встраивания в roi и roni");

    % извлечение из roni
    keyRoi = recoveryRoni(roiAddWatermark, roniAddWatermark, keyDeltas);
    figure, imshow(keyRoi,[]); title("Позиции извлечения из roi");

    % извлечение из roi
    w = recoveryRoi(roiAddWatermark, keyDeltas, keyRoi, r);
    w = reshape(w, [watermarkR, watermarkC]);
    figure, imshow(w,[]); title("Извлеченный водяной знак");
end



function [roi, roni, watermark] = imgPreparation(imgpath, watermarkpath)
    % На вход принимает: 
    %   imgpath - путь до dicom изображения для встраивания
    %   watermarkpath - путь до цвз
    % Возвращает: 
    %   roi - ROI для встраивания
    %   roni - RONI для встраивания ключа
    %   watermark - ЦВЗ для встривания

    img = dicomread(imgpath);
    [minBrightness,maxBrightness] = bounds(img, "all");

    roi = img(60:429, 110:409);
    [sizeR, sizeC] = size(roi);

    roni = img;
    roni(60:429, 110:409) = maxBrightness+20;
    
    if strcmp(watermarkpath, "") == 0
        watermark = imread(watermarkpath);
        watermark = imresize(watermark, [64, 64]); 
        watermark = imbinarize(watermark, 0.5);
    else
        watermark = [];
    end
end


function maxDelta = getMaxDelta(D)
    % На вход принимает глубину цвета
    % Возвращает максимальное значение шага квантования

    if D == 8
        maxDelta = 5;
    elseif D == 10
        maxDelta = 7;
    elseif D == 12
        maxDelta = 8;
    elseif D == 16
        maxDelta = 11;
    else
        maxDelta = 0;
    end
end


function key = getNewKey(maxValue, size)
    % На вход принимает 
    %   maxValue - максимальное значение
    %   size - длина ключа
    % Возвращает ключ, состоящий из элементов, перемешанных в случайном
    % порядке

    arr = 1:maxValue;
    key = arr(randi(numel(arr), 1, size));
end


function [newBlock, keyBlock] = blockEmbedding(block, r, c, w, deltas)
    % Встраивание в блок 
    %
    % На вход принимает:
    %   block - блок, в который встраиваем
    %   r - размер блока
    %   с - количество пикселей для встраивания в блок
    %   w - встраиваемые биты
    %   deltas - шаги квантования для встраивания
    % 
    % Возвращает:
    %   newBlock - блок после встраивания
    %   keyBlock - блок, где 1 помечены позиции встраивания

    newBlock = block;

    % Определение позиций встраивания
    arr = 1:(r*r);
    idx = randperm(r*r);
    arr_shuffled = arr(idx);
    positions = sort(arr_shuffled(1:c));

    keyBlock = zeros(r, r);

    % Встраивание
    for i = 1:c
        n1 = ceil(double(positions(i))/double(r));
        n2 = mod(positions(i), r);
        if (n2 == 0)
            n2 = r;
        end

        CW = floor(double(block(n1, n2))/double((2 * deltas(i)))) * 2 * deltas(i) + w(i) * deltas(i) + mod(block(n1, n2), deltas(i));

        newBlock(n1, n2) = CW;
        keyBlock(n1, n2) = 1;
    end
end

function [resImg, keyDeltas, keyRoi]  = qimRoi(imgpath, watermarkpath, r)
    % Встраивание водяного знака в roi
    %
    % На вход принимает:
    %   imgpath - путь до изображения для встраивания
    %   watermarkpath - путь до встраиваемого изображения
    % 
    % Возвращает: 
    %   deltas - все возможные значения шага квантования 
    %   key - ключ для встраивания
    %   roiAddWatermark - область интереса с уже встроенным ЦВЗ

    % Подготовка изображений
    [roi, roni, watermark] = imgPreparation(imgpath, watermarkpath);
    [sizeR, sizeC] = size(roi);

    % Поиск глубины цвета (бит/пиксель)
    info = dicominfo(imgpath);
    D = info.BitDepth;
    
    % Максимальное значение шага дискретизации брала из таблицы в описании
    % метода
    maxDelta = getMaxDelta(D);

    % r - размер блока
    % R - количество блоков в строке
    rowR = floor(double(sizeR)/double(r));
    columnR = floor(double(sizeC)/double(r));

    % генерация случайного ключа для выбора с в каждом блоке, заполнится
    % максимум 1/(r/2)^2 часть возможной области

    keyC = getNewKey((r^2)/(r/2)^2, rowR*columnR);
    keyDeltas = getNewKey(maxDelta, sizeR*sizeC);

    watermark = watermark(:);
    deltas = keyDeltas;
    resImg = roi;

    % позиции встраивания
    size(watermark);
    keyRoi = zeros(sizeR, sizeC);

    for n1 = 1:rowR
        for n2 = 1:columnR
            % выделение блока
            block = roi(((n1-1)*r+1):n1*r, ((n2-1)*r+1):n2*r);

            % с для текущего блока
            currentC = keyC((n1-1)*columnR + n2);
            
            [row, column] = size(watermark);
            if row == 0 || column == 0
                disp("Встраивать нечего");
            else
                % w для встраивания
                if row < currentC
                    currentC = row;
                end
                w = watermark(1:currentC);
    
                % дельты для встраивания
                deltasForBlock = deltas(1:currentC);
    
                [resImg(((n1-1)*r+1):n1*r, ((n2-1)*r+1):n2*r), keyBlock] = blockEmbedding(block, r, currentC, w, deltasForBlock);
                keyRoi(((n1-1)*r+1):n1*r, ((n2-1)*r+1):n2*r) = keyBlock; 
    
                watermark(1:currentC) = [];
                deltas(1:currentC) = [];
            end
        end
    end
    % diff = resImg - roi;
    % figure, imshow(diff,[]);
    % figure, imshow(keyRoi,[]);
end


function w = blockRecovery(block, r, c, positions, deltas)
    % Извлечение битов из блока
    %
    % Принимает на вход:
    %   block - блок из которого извлекаем
    %   r - размер блока
    %   c - количество пкселей для извлечения
    %   positions - позиции битов для извлечения
    %   deltas - шаги квантования для извлечения
    %
    % Возвращает извлеченные биты

    newBlock = block;
    % tmp = double(-1);
    w = [];

    % Встраивание
    for i = 1:c
        n1 = ceil(double(positions(i))/double(r));
        n2 = mod(positions(i), r);

        if (n2 == 0)
            n2 = r;
        end
        
        tmp = double(mod(block(n1, n2), 2*deltas(i))) - double(deltas(i));
            if tmp >= 0
                w = horzcat(w, 1);
            elseif tmp < 0
                w = horzcat(w, 0);
            end
    end
end

function positions = findPositions(blockKey, r)
    % На вход принимает:
    %   blockKey - блок с позициями встраивания отмечеными 1
    %   r - размер блока
    %
    % Возвращает позиции встривания в построчной развертке

    positions = [];
    for n1 = 1:r
        for n2 = 1:r
            if blockKey(n1, n2) == 1
                positions = horzcat(positions, (n1-1)*r+n2);
            end
        end
    end
end


function w = recoveryRoi(roi, keyDeltas, keyRoi, r)
    % На вход принимает:
    %   roi - область для извлечения
    %   keyDeltas - все шаги квантования
    %   keyRoi - двумерный массив с позициями встраивания, отмеченными 1
    %   r - размер блока
    %
    % Возвращает извлеченный ЦВЗ

    [sizeR, sizeC] = size(roi);
    rowR = floor(double(sizeR)/double(r));
    columnR = floor(double(sizeC)/double(r));

    deltas = keyDeltas;
    w = [];

    for n1 = 1:rowR
        for n2 = 1:columnR
            
            % выделение блока
            block = roi(((n1-1)*r+1):n1*r, ((n2-1)*r+1):n2*r);
            blockKey = keyRoi(((n1-1)*r+1):n1*r, ((n2-1)*r+1):n2*r);

            % с для текущего блока
            currentC = sum(sum(blockKey == 1));
            if currentC ~= 0
                % дельты для встраивания
                deltasForBlock = deltas(1:currentC);
    
                % Позиции встраивания
                positions = findPositions(blockKey, r);
    
                blockW = blockRecovery(block, r, currentC, positions, deltasForBlock);
                w = horzcat(w, blockW);
    
                % удаляем то, что уже было использовано
                deltas(1:currentC) = [];
            end
        end
    end
end


function roniAddWatermark = qimRoni(imgpath, watermarkpath, watermark, key)
    % На вход получает:
    %   impath - путь до полного изображения
    %   watermarkpath - ключ до водяного знака, просто заглушка
    %   watermark - что встраиваем в roni
    %   key - ключ для встраивания = deltas как и в roi
    % Возвращает область roni с уже встроенными данными
    
    % Подготовка изображений
    [roi, roni, watermarkDelete] = imgPreparation(imgpath, watermarkpath);
    [sizeR, sizeC] = size(roni);
    [minBrightness,maxBrightness] = bounds(roni, "all");

    roniWatermark = watermark(:);

    % Сам процесс встраивания ==============================================
    wCount = 0;
    deltaCount = 0;
    roniAddWatermark = zeros(sizeR, sizeC);

    for n1 = 1:sizeR
        for n2 = 1:sizeC
            if (roni(n1,n2) ~= (maxBrightness)) && (wCount + 1 <= length(roniWatermark))
                wCount = wCount + 1;

                if (deltaCount + 1) <= length(key)
                    deltaCount = deltaCount + 1;
                else
                    deltaCount = 1;
                end
                
                roniDelta = key(deltaCount);
                roniCW = floor(double(roni(n1,n2)) / double(2 * roniDelta)) * 2 * roniDelta + roniWatermark(wCount) * roniDelta + mod(roni(n1, n2), roniDelta);
    
                roniAddWatermark(n1, n2) = roniCW;
            elseif roni(n1,n2) == (maxBrightness)
                roniAddWatermark(n1, n2) = maxBrightness;
            elseif wCount + 1 > length(roniWatermark)
                roniAddWatermark(n1, n2) = roni(n1, n2);
            end
        end
    end
end


function key = recoveryRoni(roi, roni, roniKey)
    % На вход получает:
    %   roi - roi с уже встроенным ЦВЗ
    %   roni - roni с уже встроенным ключем
    %   roniKey - ключ для roni
    % Возвращает ключ содержащий позиции для извлечения

    [rowsRoi, columnsRoi] = size(roi);
    [sizeR, sizeC] = size(roni);

    [minBrightness,maxBrightness] = bounds(roni, "all");

    wCount = 0;
    deltaCount = 0;
    key = [];
    % tmp = double(-1);

    for n1 = 1:sizeR
        for n2 = 1:sizeC
            if roni(n1,n2) ~= (maxBrightness)
                [keyR, keyC] = size(key);
                if keyC == rowsRoi*columnsRoi
                    break;
                end

                wCount = wCount + 1;
                if (deltaCount + 1) <= length(roniKey)
                    deltaCount = deltaCount + 1;
                else
                    deltaCount = 1;
                end
                
                roniDelta = roniKey(deltaCount);
                tmp = double(mod(roni(n1, n2), 2*roniDelta)) - double(roniDelta);
                if tmp >= 0
                    key(wCount) = 1;
                elseif tmp < 0
                    key(wCount) = 0;
                end
            end
        end
    end
    key(rowsRoi*columnsRoi+1:end) = [];
    key = reshape(key, [rowsRoi, columnsRoi]); 
end
