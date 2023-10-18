im = imread("Pics/bevo.jpeg");

figure(1)
imshow(im)

arr = clusterPixels(im, 5);
figure(2)
imshow(arr)

arr2 = boundaryPixels(arr);
figure(3)
imshow(arr2)

function [labelIm] = clusterPixels(im, k)

    im = imgaussfilt(im,3);

    MAX_ITERATIONS = 30
    
    s = size(im);

    vectors = double(reshape(im, [s(1) * s(2), 3]));
    means = randi(255, [k, 3])

    for i = 1: MAX_ITERATIONS
        newMeans = kMeanCycle(means, vectors)
        if (newMeans == means)
            break
        end
        means = newMeans
    end

    colors = uint8(means)

    for i = 1 : s(1) * s(2)
        node = smallestDistance(vectors(i, :), means);
        vectors(i, :) = colors(node, :);
    end

    labelIm = uint8(reshape(vectors, [s(1), s(2), s(3)]));

end

function [boundaryIm] = boundaryPixels(labelIm)
    labelIm = im2gray(labelIm);
    boundaryIm = edge(labelIm, "canny");
end

function centers = detectCirclesHT(im, radius)
    
    BIN_SIZE = 10;

    s = size(im);
    im = imgaussfilt(im,8);
    grayIm = im2gray(im);
    edges = edge(grayIm, "sobel");

    accumulator = zeros(int32((s(1) + 1) / BIN_SIZE), int32((s(2) + 1) / BIN_SIZE));

    for i = 1 : s(1)
        for j = 1 : s(2)
            if (edges(i, j) == 1)
                circle = makeCircle(int32((s(1) + 1) / BIN_SIZE), ...
                    int32((s(2) + 1) / BIN_SIZE), int32(radius / BIN_SIZE), ...
                    int32(i / BIN_SIZE), int32(j / BIN_SIZE));
                accumulator = accumulator + circle;
            end
        end
    end

    accumulator = rescale(accumulator, 0, 255);
    
    threshold = ((6 * radius) * 0.05);
    
    threshold = (accumulator < threshold);

    accumulator(threshold) = 0;

    accumulator = nonMaximumSuppression(accumulator, int32((radius) / BIN_SIZE));
    
    [row, col] = find(accumulator);
    centers = [col * BIN_SIZE, row * BIN_SIZE];
    
end

function centers = detectCirclesRANSAC(im, radius)

    NUM_CIRCLES = 1;
    INLIER_DISTANCE = 5;
    N = 100;

    im = imgaussfilt(im,8);

    centers = zeros([NUM_CIRCLES, 2]);

    grayIm = im2gray(im);
    edges = edge(grayIm, "sobel");

    [row, col] = find(edges);
    edgeIndexes = [col , row];

    index = 1 
    s = size(edgeIndexes)

    for circleNum = 1 : NUM_CIRCLES
    
        maxCenter = [0, 0, 0];
    
        for i = 1 : N
            temp = oneRANSAC(edgeIndexes, radius, INLIER_DISTANCE);
    
            if (temp(3) > maxCenter(3))
                maxCenter = temp;
            end

            inlierCount(index) = maxCenter(3) * s(1)
            index = index + 1
            
        end

        figure(2)
        title
        plot(1 : N, inlierCount)

        centers(circleNum, 1) = maxCenter(1);
        centers(circleNum, 2) = maxCenter(2);
        edgeIndexes = removeInliers(edgeIndexes, centers(circleNum, :), radius, INLIER_DISTANCE);

    end
end

function newMeans = kMeanCycle(means, vectors)
    s = size(means);

    [belongList, count] = createBelongsList (vectors, means); %rename this variable

    newMeans = zeros(s);

    for i = 1 : s(1)
        tempVectors = selectVectors(vectors, belongList(i, :), count(i));
        newMeans(i, :) = newMean(tempVectors);
    end

    
end


function [list, currentIndexes] = createBelongsList (vectors, means)

    sm = size(means);
    sv = size(vectors);

    list = zeros(sm(1), sv(1));

    currentIndexes = zeros([1, sm(1)]);

    for i = 1 : sv(1)
        node = smallestDistance(vectors(i, :), means);
        currentIndexes(node) = currentIndexes(node) + 1;
        list(node, currentIndexes(node)) = i;
    end

end

function node = smallestDistance(vector, means)
    
    distance = vectorDistance(vector, means(1, :));
    node = 1;

    s = size(means);

    for i = 2 : s(1)
        tempDistance = vectorDistance(vector, means(i, :));
        if (tempDistance < distance)
            node = i;
            distance = tempDistance;
        end
    end
end

function resultVectors = selectVectors(vectors, belongList, count)
    sb = size(belongList);
    sv = size(vectors);
    resultVectors = zeros(count, sv(2));
    for i = 1 : sb(2)
        if (belongList(i) ~= 0)
            resultVectors(i, :) = vectors(belongList(i), :);
        end
    end
end

function distance = vectorDistance(v1, v2)
    distance = 0;
    s = size(v1);

    for i = 1 : s(1)
        distance = distance + (v1(i) - v2(i))^2;
    end

    sqrt(distance);
end

function newVector = newMean(vectors)

    s = size(vectors);
    newVector = sum(vectors) / s(1);

end

function result = nonMaximumSuppression (accumulator, radius)

    s = size(accumulator);

    result = zeros(s(1), s(2));
  
    for i = 1 : s(1)
        for j = 1 : s(2)

            startBoundx = 1;
            if i - radius > 1
                startBoundx = i - radius;
            end
        
            startBoundy = 1;
            if j - radius > 1
                startBoundy = j - radius;
            end
        
            endBoundx = s(1);
            if i + radius < s(1)
                endBoundx = i + radius;
            end
        
            endBoundy = s(2);
            if j + radius < s(2)
                endBoundy = j + radius;
            end


            if (accumulator(i, j) == ...
                    max(max(accumulator(startBoundx : endBoundx, startBoundy : endBoundy))) ...
                    && accumulator(i, j) ~= 0)
                result(i, j) = 1;
            end

        end
    end   
end
    
function circle = makeCircle(rows, cols, radius, xCenter, yCenter) %soon to be depricated

    circle = zeros(rows, cols);

    startBoundx = 1;
    if xCenter - radius > 1
        startBoundx = xCenter - radius;
    end

    startBoundy = 1;
    if yCenter - radius > 1
        startBoundy = yCenter - radius;
    end

    endBoundx = rows;
    if xCenter + radius < rows
        endBoundx = xCenter + radius;
    end

    endBoundy = cols;
    if yCenter + radius < cols
        endBoundy = yCenter + radius;
    end


    for i = startBoundx : endBoundx
        for j = startBoundy: endBoundy
            circle(i, j) = sqrt(double((xCenter - i)^2 + (yCenter - j)^2));
        end
    end

    circle = round(circle, 0);
    circle = (circle == radius);    
end

function result = oneRANSAC (edges, radius, inlierDistance)

    s = size(edges);
    numEdges = s(1);
    randomPoints = randi(numEdges, 3);
    center = fitCircle(edges(randomPoints(1), :), edges(randomPoints(2), :), edges(randomPoints(3), :));
    count = 0;

    for i = 1 : numEdges

        if (distanceFromCircle(edges(i, :), center, radius) < inlierDistance)
            count = count + 1;
        end

    end

    x = center(1);
    y = center(2);
    inlierPercentage = count / numEdges;

    result = [x, y, inlierPercentage];
end

function center = fitCircle(A, B, C)

    if ((A(1) == B(1) && A(2) == B(2))) || ((A(1) == C(1) && A(2) == C(2))) || ((B(1) == C(1) && B(2) == C(2)))
        center = [-1, -1];
        return
    end

    ABslope = (A(2) - B(2)) / (A(1) - B(1));
    ACslope = (A(2) - C(2)) / (A(1) - C(1));

    if (ABslope == ACslope)
        center = [-1, -1];
        return
    end

    ABMidpoint = [(A(1) + B(1)) / 2, (A(2) + B(2)) / 2 ];

    m = -1 / ABslope;
    b = ABMidpoint(2) - m * ABMidpoint(1);

    centerX = (C(1)^2 + C(2)^2 - A(1)^2 - A(2)^2 + 2 * b * (A(2) - C(2))) / (2 * (C(1) - A(1) + m * (C(2) - A(2))));
    centerY = m * (centerX) + b;

    center = [centerX, centerY];

end

function distance = distanceFromCircle (coordinate, center, radius)

    distanceFromRadius = sqrt((center(1) - coordinate(1))^2 + (center(2) - coordinate(2))^2);
    distance = abs(distanceFromRadius - radius);
end

function newEdges = removeInliers(edges, center, radius, inlierDistance)
   
   index = 1;
   s = size(edges);
   for i = 1 : s(1)
       if (distanceFromCircle(edges(i, :), center, radius) > inlierDistance)
        newEdges(index, 1) = edges(i, 1);
        newEdges(index, 2) = edges(i, 2);
        index = index + 1;
       end
   end
end



