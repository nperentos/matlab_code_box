function dt = load_session_date(fn)

try;
    settings = xml2struct(get_lfp_filename(fn,'oe.xml'));
    dt = settings.SETTINGS.INFO.DATE.Text;
catch
    disp(['No .oe.xml found - ' fn])
    dt = [];
end