
% -----------    Tests  ------------

% GENERAL TESTS

% generalTests()

% TESTS ON CANADA

% canadaTests();

% TESTS ON ANTELOPE

% antelopeTest();

% TESTS ON FLWOER

% flowerTest();


% -----------  FUNCTIONS -----------

%function that calculates the energy matrix of an image
function result = calcEnergy(image)
     image = im2double(rgb2gray(image));
     [xGradient, yGradient] = imgradientxy(image, "sobel");
     [result, ~] = imgradient(xGradient, yGradient);
end

function result = calcEnergyV2(image)
     image = im2double(rgb2gray(image));
     [xGradient, yGradient] = imgradientxy(image, "intermediate");
     [result, ~] = imgradient(xGradient, yGradient);
end

%function that calculates the gradient of an image in the x direction
function result = calcXGradient(image)
    h = [-1, 0, 1];
    grayImage = rgb2gray(image);
    result = imfilter(grayImage, h);
end

%function that calculates the gradient of an image in the y direction
function result = calcYGradient(image)
    h = [1; -1];
    grayImage = rgb2gray(image);
    result = imfilter(grayImage, h);
end

%function that takes in an image, carves the seam horizontaly, and returns the 
%image without the seam in result, and the seam that was removed in seam
%which is a logical matrix
function [result, seam, minEnergyMap] = horizontalSeam(image, efunction)

    s = size(image);
    if (efunction == 0)
        minEnergyMap = calcEnergy(image);
    else 
        minEnergyMap = calcEnergyV2(image);
    end





    for col = 2:1:s(2)
        for row = 1:1:s(1)

            if (row == 1)
                minEnergyMap(row, col) = minEnergyMap(row, col) + min([minEnergyMap(row, col - 1), minEnergyMap(row + 1, col - 1)]);
            elseif (row == s(1))
                minEnergyMap(row, col) = minEnergyMap(row, col) + min([minEnergyMap(row, col - 1), minEnergyMap(row - 1, col - 1)]);
            else
                minEnergyMap(row, col) = minEnergyMap(row, col) + min([minEnergyMap(row, col - 1), minEnergyMap(row - 1, col - 1), minEnergyMap(row + 1, col - 1)]);
            end   
        end
    end
    
    [~ , I] = min(minEnergyMap(:, end));
    minEnergyMap(I, end) = -1;

    for i = s(2) - 1:-1:1
        if (I == 1)
            [~, change] = min([minEnergyMap(I, i), minEnergyMap(I + 1, i)]);
            I = I + change - 1;

        elseif(I == s(1))
            [~, change] = min([minEnergyMap(I - 1, i), minEnergyMap(I, i)]);
            I = I + change - 2;
        else
            [~, change] = min([minEnergyMap(I - 1, i), minEnergyMap(I, i), minEnergyMap(I + 1, i)]);
            I = I + change - 2;
        end

        minEnergyMap(I, i) = -1;
    end
    
    seam = (minEnergyMap == -1);
    result = filterChannelUsingDp(seam, image);

end

%function that takes in an image, carves the seam vertically, and returns the 
%image without the seam in result, and the seam that was removed in seam
%which is a logical matrix
function [result, seam, minEnergyMap] = verticalSeam(image, efunction)

    transposedImage = image(:, :, 1)';
    transposedImage(:, :, 2) = image(:,:,2)'; 
    transposedImage(:, :, 3) = image(:,:,3)'; 

    [transposedImage, transposedSeam, transposedMinEnergyMap] = horizontalSeam(transposedImage, efunction);

    result = transposedImage(:, :, 1)';
    result(:, :, 2) = transposedImage(:, :, 2)';
    result(:, :, 3) = transposedImage(:, :, 3)';

    seam = transposedSeam';

    minEnergyMap = transposedMinEnergyMap';

end

%given an image a seam, removes the pixels where the seam is
function result = filterChannelUsingDp(seam, image)

    s = size(image);

    seam = (seam ~= 1);

    rChannel = image(:,:,1);
    gChannel = image(:,:,2);
    bChannel = image(:,:,3);

    rChannel = rChannel(seam);
    gChannel = gChannel(seam);
    bChannel = bChannel(seam);

    result = reshape([rChannel, gChannel, bChannel], [s(1) - 1, s(2), s(3)]);
end

%function that takes in an image an an integer and removes that many
%pixels from the vertical direction (reduces the height)
function output = removeVertical(im, numPixels)
    
    output = im;

    for i = 1:1:numPixels
        [output, ~] = verticalSeam(output, 0);
    end

end

function output = removeVerticalV2(im, numPixels)
    
    output = im;

    for i = 1:1:numPixels
        [output, ~] = verticalSeam(output, 1);
    end

end

%function that takes in an image an an integer and removes that many
%pixels from the horizontal direction (reduces the width)
function output = removeHorizontal(im, numPixels)
    
    output = im;

    for i = 1:1:numPixels
        [output, ~] = horizontalSeam(output, 0);
    end

end

function output = removeHorizontalV2(im, numPixels)
    
    output = im;

    for i = 1:1:numPixels
        [output, ~] = horizontalSeam(output, 1);
    end

end

%given the origianl image and the seam that was carved, returns the
%image with red pizels (255, 0, 0) where the seam was carved.
function displaySeam(im, seam)

    result = im;
    temp = result(:, :, 1);
    temp(seam) = 255;
    result(:, :, 1) = temp;
    
    temp = result(:, :, 2);
    temp(seam) = 0;
    result(:, :, 2) = temp;
    
    temp = result(:, :, 3);
    temp(seam) = 0;
    result(:, :, 3) = temp;

    imshow(result)

end

function generalTests()
    ut = imread("Pics/ut.jpg");
    river = imread("Pics/river.jpg");
       
    subplot(4, 3, 1);
    imshow(ut);
    title("ORIGINAL UT")
    
    subplot(4, 3, 2);
    imshow(river);
    title("ORIGINAL RIVER")
    
    resizedUT = removeVertical(ut, 100);
    subplot(4, 3, 3);
    imshow(resizedUT);
    title("RESIZED UT")
    
    resizedRiver = removeHorizontal(river, 100);
    subplot(4, 3, 4);
    imshow(resizedRiver);
    title("RESIZED RIVER")
    
    UTEnergy = calcEnergy(ut);
    subplot(4, 3, 5);
    imagesc(UTEnergy);
    title("UT ENERGY USING SOBEL")
    
    [~, UTHorizontalSeam, UTMinEnergyMapHorizontal] = horizontalSeam(ut, 0);
    subplot(4, 3, 6);
    imagesc(UTMinEnergyMapHorizontal);
    title("UT MIN ENERGY MAP HORIZONTAL")
    
    [~, UTVerticalSeam, UTMinEnergyMapVeritcal] = verticalSeam(ut, 0);
    subplot(4, 3, 7);
    imagesc(UTMinEnergyMapVeritcal);
    title("UT MIN ENERGY MAP VERTICAL")
    
    subplot(4, 3, 8);
    displaySeam(ut, UTHorizontalSeam)
    title("UT Horizontal Seam")
    
    subplot(4, 3, 9);
    displaySeam(ut, UTVerticalSeam)
    title("UT Vertical Seam")
    
    subplot(4, 3, 10);
    imagesc(calcEnergyV2(ut))
    title("UT ENERGY USING INTERMEDIATE")
    
    subplot(4, 3, 11);
    imshow(removeVerticalV2(ut, 100))
    title("RESIZED UT USING ALTERNATE ENERGY")

end

function canadaTests()

    canada = imread("Pics/canada.JPG");

    subplot(3, 2, 1);
    imshow(canada);
    title("ORIGINAL CANADA (1536 x 2304)")
    
    resizeCanada = removeHorizontal(canada, 500);
    subplot(3, 2, 3);
    imshow(resizeCanada);
    title("HORIZONTAL SEAM CARVED CANADA (1036 x 2304)");

    imResizeCanada = imresize(canada , [1036, 2304]);
    subplot(3, 2, 4);
    imshow(imResizeCanada);
    title("HORIZONTAL IMRESIZE CANADA (1036 x 2304)");

    resizeCanada = removeVertical(resizeCanada, 500);
    subplot(3, 2, 5);
    imshow(resizeCanada);
    title("HORIZONTAL AND VERTICAL SEAM CARVED CANADA (1036 x 1804)");

    imResizeCanada = imresize(canada , [1036, 1804]);
    subplot(3, 2, 6);
    imshow(canada);
    title("HORIZONTAL AND VERTICAL IMRESIZE CANADA (1036 x 1804)");

end

function antelopeTest()

    antelope = imread("Pics/antelope.JPG");
    
    subplot(1, 3, 1);
    imshow(antelope);
    title("ORIGINAL ANTELOPE (1536 x 2730)")
    
    resizeAntelope = removeHorizontal(antelope, 500);
    resizeAntelope = removeVertical(resizeAntelope, 1000);

    subplot(1, 3, 2);
    imshow(resizeAntelope);
    title("SEAM CARVED ANTELOPE (1036 x 1730)");

    imResizeAntelope = imresize(antelope , [1036, 1730]);
    subplot(1, 3, 3);
    imshow(imResizeAntelope);
    title("IMRESIZE ANTELOPE (1036 x 1730)");
    
end

function flowerTest()

    flower = imread("Pics/flower.JPG");
    
l    subplot(1, 3, 1);
    imshow(flower);
    title("ORIGINAL FLOWER (568 x 1010)")
    
    resizeFlower = removeHorizontal(flower, 300);
    resizeFlower = removeVertical(resizeFlower, 600);

    subplot(1, 3, 2);
    imshow(resizeFlower);
    title("SEAM CARVED FLOWER (268 x 410)");

    imResizeFlower = imresize(flower , [268, 410]);
    subplot(1, 3, 3);
    imshow(imResizeFlower);
    title("IMRESIZE FLOWER (268 x 410)");
    
end

