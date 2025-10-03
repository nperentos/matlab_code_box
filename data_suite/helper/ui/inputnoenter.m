function p=inputnoenter(x)
fprintf(x)
w = waitforbuttonpress;
if w
    p = get(gcf, 'CurrentCharacter');
end