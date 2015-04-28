%%%-----------------------------------------------------------------------------------------------------------
%%%     This is an image to RGB converter
%%%     Video frames must be first exctracted using another tool (
%%%     Direct video to RGB conversion not supported here!!!!
%%%     The default RGB output format is for 4 bit per color depth as shown:
%%%     BLUE | GREEN | RED
%%%     0011   0010    0110     =>  "001100100110" final output
%%%-----------------------------------------------------------------------------------------------------------

fileID = fopen('image_hex.txt','a');

%read concecutive PNG image files named 'image_X' (X=60 in this example)
for k=1:60
    eval(['a = imread(''image_' num2str(k) '.png'');']);
    red = a(:,:,1);
    green = a(:,:,2);
    blue = a(:,:,3);

    
    for i=1:size(red,1)
        for j=1:size(red,2)
            r = dec2bin(red(i,j),8);
            r = r(1:4);
            g = dec2bin(green(i,j),8);
            g = g(1:4);
            b = dec2bin(blue(i,j),8);
            b = b(1:4);

            pixel = strcat(b,g,r);
            pixel1 = bin2dec(pixel(1:4));
            pixel1 = dec2hex(pixel1);
            pixel2 = bin2dec(pixel(5:8));
            pixel2 = dec2hex(pixel2);
            pixel3 = bin2dec(pixel(9:12));
            pixel3 = dec2hex(pixel3);

            fseek(fileID , 0 , 'eof');
            fprintf( fileID, '%1s%1s', pixel1 , pixel2 , pixel3);
        end
    end
end

fclose(fileID);