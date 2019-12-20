
mkdir('c:\Users\J\Desktop\Copper');
mkdir('c:\Users\J\Desktop\Jet');
mkdir('c:\Users\J\Desktop\Gray');

for imIdx = 423:427
    i = imread(['c:\Users\J\Desktop\' sprintf('image_00%d.tif', imIdx)]);
    i = double(i);
    i(i < 0) = 0;

    i = i(480:560, 40:120);
    i = kron(i, ones(4));
    
    [~, img] = Matrix2Image(i, 0, 210e3, gray(1024));
    imwrite(img, ['c:\Users\J\Desktop\Gray\' sprintf('image_00%d_gray.png', imIdx)]);
    
    [~, img] = Matrix2Image(i, 0, 210e3, copper(1024));
    imwrite(img, ['c:\Users\J\Desktop\Copper\' sprintf('image_00%d_copper.png', imIdx)]);
    
    [~, img] = Matrix2Image(i, 0, 210e3, jet(1024));
    imwrite(img, ['c:\Users\J\Desktop\Jet\' sprintf('image_00%d_jet.png', imIdx)]);
    
end
