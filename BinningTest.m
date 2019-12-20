
%%
I = magic(1000);

%%
b = [4 4];

%%
t = tic();
for i = 1:100
    y = Binning(I, b);
end
toc(t)

%%
t = tic();
for i = 1:100
    y = Binning2(I, b);
end
toc(t)

%%
t = tic();
for i = 1:10
    y = imresize(I, size(I)./b);
end
toc(t)

