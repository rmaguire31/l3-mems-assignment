function analyse_timestep(fname)
%CHARACTERISE_RESULTS Plots characteristics of COMSOL results `fname`
%
%DESCRIPTION
%
%
%INPUTS
%   fname - COMSOL results .txt file to parse
%
%COPYRIGHT (C) Russell Maguire 2017
[tv, Tv, dzv] = parse_fname(fname);
fname = fname(1:end-4);
tname = 'Time \si{\second}';
Tname = 'Temperature \si{\celsius}';
dzname = 'Displacement \si{\micro\meter}';

tv = tv - 0.05;
Tv = Tv - 293.15;
dzc = dzv(1)+(dzv(end)-dzv(1))*exp(-1);
tc = tv(find(dzv<=dzc, 1));
disp([tc, dzc])
plot_tikz(tv, dzv, Tv, tname, dzname, Tname, [fname '.response.tex'],...
    @plot_tc_cb)
    function plot_tc_cb()
        h = ishold();
        hold('on');
        ax = gca();
        plot(ax.XLim, [dzc dzc], '--k');
        plot([tc tc], ax.YLim, '--k');
        if ~h
            hold('off')
        end
    end
end

function [tv, Tv, dzv] = parse_fname(fname)
%DESCRIPTION
%   param, T, C, dz, cte
%
%INPUTS
%   fname - COMSOL results .txt file to parse

% MATLAB's builtin importdata is pretty effective.
file = importdata(fname);
if iscell(file)
    for i = 1:size(file, 1)
        if file{i,1}(1) ~= '%'
            break
        end
    end
    s = struct();
    s.textdata = file(1:i-1,1);
    s.data = cellfun(@str2double, file(i:end,:));
    file = s;
end

% Get data
data = file.data;

% Parse header.
header = cellfun(@(x)(x(3:end)), file.textdata, 'UniformOutput', false);
headings = strsplit(...
    header{end}, '\s\s+', 'DelimiterType', 'RegularExpression');
header = cellfun(...
    @(x)strsplit(x, ':\s+', 'DelimiterType', 'RegularExpression'),...
    header(1:end-1),...
    'UniformOutput', false);
header = vertcat(header{:})';
header = struct(header{:});
disp(header)
paramname = headings{1};

% Format data vectors
tv = movmean(data(:,1),2);
Tv = movmean(data(:,2),2);
dzv = movmean(data(:,3),2);
end

function plot_tikz(x, y, paramv, xname, yname, paramname, fname, cb)
%DESCRIPTION
%
%
%INPUTS
%
markers = {
    '-','-o','-^','-s','-p','-h','-v','-d'};
figure()
hold('on');
for i = 1:size(y,2)
    if isvector(x)
        plot(x, y(:,i), markers{i});
    else
        plot(x(:,i), y(:,i), markers{i});
    end
end
hold('off');

if ~isvector(y)
    if isnumeric(paramv)
        paramv = arrayfun(@(x)[paramname num2str(x,' %g')], paramv,...
                          'UniformOutput', false);
    end
   legend(paramv, 'AutoUpdate', 'off', 'Location', 'northoutside');
end
ylabel(yname);
xlabel(xname);

% Callback if we need to add anything else.
if exist('cb', 'var')
    cb()
end
matlab2tikz(['tex/tikz/' fname], ...
            'parseStrings', false, ...
            'width', '0.35\textwidth');
end