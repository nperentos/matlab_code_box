%% Add to example code python path
cd /Users/nikolas/Dropbox/code/data_suite/

if count(py.sys.path,'') == 0
    insert(py.sys.path,int32(0),'');
end

%% Reload module after changes
modul = py.importlib.import_module('pactools');
py.importlib.reload(modul);

%%
import py.pactools.simulate_pac
import py.pactools.Comodulogram

signal = simulate_pac(10000,200,50,5,1,0.4,0);
signal = ndarray2double(signal);

methods = {'ozkurt', 'canolty', 'tort', 'penny', 'vanwijk', 'duprelatour', 'colgin', 'sigl', 'bispectrum'};
tmp = py.numpy.linspace(1, 10, 50);
%tmp = linspace(1,10,50);
estimator = Comodulogram(200,tmp,1);
estimator.progress_bar=0;
estimator.method=methods{6};

tmp = estimator.fit(signal);
tmp1 = ndarray2double(tmp.comod_);

fig; imagesc(ndarray2double(tmp.low_fq_range),ndarray2double(tmp.high_fq_range),tmp1);
axis xy
colormap winter