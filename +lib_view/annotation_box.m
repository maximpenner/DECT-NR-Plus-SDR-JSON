function [] = annotation_box(dim, str)

    assert(numel(dim) == 2)
    assert(size(dim, 2) == 2)

    dim = [dim, zeros(1,2)];

    annotation('textbox',dim,'String',str,'FitBoxToText','on', 'Interpreter', 'none');
end

