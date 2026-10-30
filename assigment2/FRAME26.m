function FRAME26(FILENAME)%please type or select file path here
% FRAME26: A linear analysis program for framed structures
%..........................................................................
%    Programmer:  C. H. Chen   R15521239  & Jay Wu   R15521221
%                 Supervised by Assistant Professor Chun-Yu Ke
%                 For the course: Advanced Structural Theory
%                 Department of Civil Engineering
%                 National Taiwan University
%                 Fall 2026 © All Rights Reserved
%                 last modify time: 10/30
%..........................................................................
%%=========================================================================
%%                              prog 1
%%=========================================================================
FTYPE = {'BEAM';'PLANE TRUSS';'PLANE FRAME';'PLANE GRID';'SPACE TRUSS';'SPACE FRAME'};
IPR = [1,2,2,2,3,3; 2,2,3,3,3,6];

if nargin == 0 % no input argument
    [file, path] = uigetfile('*.ipt', 'Select Input file');
    if isequal(file, 0)
        return;
    end
    [~, FILENAME] = fileparts(file);
    cd(path);
end

% Get starting time
startTime = clock;

% Read input data file (.ipt)
IREAD = fopen([FILENAME '.ipt'], 'r');
if IREAD == -1
    error('Cannot open file %s.ipt. Please check the file path.', FILENAME);
end

TITLE = fgets(IREAD);
FUNIT = fgets(IREAD);
LUNIT = fgets(IREAD);
ID = '*';

HEADLINE(ID, IREAD);

args = [];
while ~feof(IREAD) && length(args) < 7
    line = fgets(IREAD);
    if ischar(line)
        args = str2num(line); %#ok<ST2NM>
    end
end

if length(args) < 7
    error('error input function');
end

temp = num2cell(args(1:7));
[NNOD, NBC, NMAT, NSEC, ITP, NNE, IFORCE] = deal(temp{:});

NCO = IPR(1, ITP);
NDN = IPR(2, ITP);
NDE = NDN * NNE;

% Read structural matrices (PROG 1)
[COOR, NFIX, EXLD, IDBC, VECTY, FEF, PROP, SECT] = INPUT(IREAD, ID, NNOD, NBC, NMAT, NSEC, ITP, NCO, NDN, NDE, IFORCE);

% Draw the structure
drawStructure(ITP, COOR, IDBC, NFIX, NBC, NNOD, LUNIT, 'b-');
fclose(IREAD);

% =========================================================================
%                       prog 2
% =========================================================================
[IDND, NEQ] = IDMAT(NFIX, NNOD, NDN);
LM = MEMDOF(IDBC, IDND, NBC, NDE);
NSBAND = SEMIBAND(LM, NBC);
GLOAD = LOAD(EXLD, IDND, NDN, NNOD, NEQ);

% display prog-2 result
disp('IDND :');   disp(IDND);
disp('NEQ :');    disp(NEQ);
disp('LM :');     disp(LM);
disp('NSBAND :'); disp(NSBAND);
disp('GLOAD :');  disp(GLOAD);

end
%%=========================================================================
%                   FUNCTIONS FOR PROG 1
%%=========================================================================
function HEADLINE(ID, IREAD)
while ~feof(IREAD)
    temp = fgets(IREAD);
    if ~isempty(temp) && temp(1) == ID
        return
    end
end
end


function [COOR, NFIX, EXLD, IDBC, VECTY, FEF, PROP, SECT] = INPUT(IREAD, ID, NNOD, NBC, NMAT, NSEC, ITP, NCO, NDN, NDE, IFORCE)
HEADLINE(ID, IREAD); COOR = ReadMatrix(IREAD, NCO, NNOD);
HEADLINE(ID, IREAD); NFIX = ReadMatrix(IREAD, NDN, NNOD);
HEADLINE(ID, IREAD); EXLD = ReadMatrix(IREAD, NDN, NNOD);
HEADLINE(ID, IREAD); IDBC = ReadMatrix(IREAD, 5, NBC);

if ITP == 6
    HEADLINE(ID, IREAD); VECTY = ReadMatrix(IREAD, 3, NBC);
else
    VECTY = [];
end

if IFORCE == 2
    HEADLINE(ID, IREAD); FEF = ReadMatrix(IREAD, NDE, NBC);
else
    FEF = [];
end

HEADLINE(ID, IREAD); PROP = ReadMatrix(IREAD, 5, NMAT);
HEADLINE(ID, IREAD); SECT = ReadMatrix(IREAD, 5, NSEC);
end


function mat = ReadMatrix(IREAD, row, col)
mat = zeros(row, col);
for j = 1:col
    line = fgets(IREAD);
    num = str2num(line); %#ok<ST2NM>
    if isempty(num)
        continue;
    end
    mat(:, j) = num(2:row+1);
end
end


function drawStructure(ITP, COOR, IDBC, NFIX, NBC, NNOD, LUNIT, FORMAT)
NCO = size(COOR, 1);
X = zeros(3, NNOD);  X(1:NCO, :) = COOR;
is3D = ITP >= 5;

figure; hold on
for e = 1:NBC
    n1 = IDBC(1, e);  n2 = IDBC(2, e);
    if is3D
        plot3(X(1, [n1 n2]), X(2, [n1 n2]), X(3, [n1 n2]), FORMAT, 'LineWidth', 2)
    else
        plot(X(1, [n1 n2]), X(2, [n1 n2]), FORMAT, 'LineWidth', 2)
    end
end

d = 0.025 * max(max(X, [], 2) - min(X, [], 2));

for n = 1:NNOD
    if is3D, text(X(1, n)+d, X(2, n)+d, X(3, n)+d, num2str(n), 'FontWeight', 'bold');
    else,    text(X(1, n)+d, X(2, n)+d, num2str(n), 'FontWeight', 'bold'); end
end

for e = 1:NBC
    xm = mean(X(:, IDBC(1:2, e)), 2);
    if is3D, text(xm(1), xm(2), xm(3), num2str(e), 'Color', 'r', 'HorizontalAlignment', 'center', 'BackgroundColor', 'w');
    else,    text(xm(1), xm(2), num2str(e), 'Color', 'r', 'HorizontalAlignment', 'center', 'BackgroundColor', 'w'); end
end

for n = 1:NNOD
    r = NFIX(:, n) == -1;
    if all(r),     mk = 's';  fc = 'k';
    elseif any(r), mk = '^';  fc = 'k';
    else,          mk = 'o';  fc = 'w';
    end

    if is3D, plot3(X(1, n), X(2, n), X(3, n), mk, 'MarkerSize', 8, 'MarkerFaceColor', fc, 'MarkerEdgeColor', 'k');
    else,    plot(X(1, n), X(2, n), mk, 'MarkerSize', 8, 'MarkerFaceColor', fc, 'MarkerEdgeColor', 'k'); end
end

xlabel(['X ', LUNIT])
switch ITP
    case 1, title('Beam');     ylim([-0.15 0.15] * max(d/0.025, 1))
    case 2, title('2D truss'); ylabel(['Y ', LUNIT]); axis equal
    case 3, title('2D frame'); ylabel(['Y ', LUNIT]); axis equal
    case 4, title('2D grid');  ylabel(['Z ', LUNIT]); axis equal
    case 5, title('3D truss'); ylabel(['Y ', LUNIT]); zlabel(['Z ', LUNIT]); axis equal; view(3)
    case 6, title('3D frame'); ylabel(['Y ', LUNIT]); zlabel(['Z ', LUNIT]); axis equal; view(3)
end
grid on; hold off
end

% =========================================================================
%                   FUNCTIONS FOR PROG 2
% =========================================================================

function [IDND, NEQ] = IDMAT(NFIX, NNOD, NDN)
    IDND = zeros(NDN, NNOD);
    neq = 0;
    
    for j = 1:NNOD
        for i = 1:NDN
            if NFIX(i, j) == 0
                neq = neq + 1;
                IDND(i, j) = neq;
            else
                IDND(i, j) = 0;
            end
        end
    end
    NEQ = neq;
end


function LM = MEMDOF(IDBC, IDND, NBC, NDE)
    LM = zeros(NDE, NBC);
    for e = 1:NBC
        n1 = IDBC(1, e);
        n2 = IDBC(2, e);
        
        dof_n1 = IDND(:, n1);
        dof_n2 = IDND(:, n2);
        
        LM(:, e) = [dof_n1; dof_n2];
    end
end


function NSBAND = SEMIBAND(LM, NBC)
    max_bandwidth = 0;
    for e = 1:NBC
        active_dofs = LM(LM(:, e) > 0, e);
        if ~isempty(active_dofs)
            dof_max = max(active_dofs);
            dof_min = min(active_dofs);
            current_band = dof_max - dof_min + 1;
            if current_band > max_bandwidth
                max_bandwidth = current_band;
            end
        end
    end
    NSBAND = max_bandwidth;
end


function GLOAD = LOAD(EXLD, IDND, NDN, NNOD, NEQ)
    GLOAD = zeros(NEQ, 1);
    for j = 1:NNOD
        for i = 1:NDN
            dof = IDND(i, j);
            if dof > 0
                GLOAD(dof) = GLOAD(dof) + EXLD(i, j);
            end
        end
    end
end

% % ^^ UP TO HERE --- PROG 2 ^^
