function equalizeClims(h)

if ~ishandle(h)
    error('error you must pass a handle');
end
cx = [nan nan];
ii = [];
for  i = 1:length(h)
    if strcmp(h(i).Type, 'axes') 
        ii = [ii,i];
        cx = [cx; caxis(h(i))];
    end
end

cx = max(cx);
for  i = ii
    caxis(h(i),cx);
end


