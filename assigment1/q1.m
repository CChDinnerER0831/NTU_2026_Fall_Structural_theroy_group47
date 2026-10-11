function FRAME26(FILENAME)

%    VARIABLES:
%        NNOD   = number of nodes
%        NBC    = number of Beam-column elements
%        NCO    = number of coordinates per node
%        NDN    = number of DOFs per node
%        NNE    = number of nodes per element
%        NDE    = number of DOFs per element
%        NMAT   = number of material types
%        NSEC   = number of cross-sectional types
%        IFORCE = 1 if only concentrated loads are applied
%               = 2 if fixed-end forces are required.
%                   (e.g. problems with distributed loads, fabrication
%                   errors, temperature change, or support settlement)
%    CHARACTERS
%        FUNIT  = unit of force (such as kN and kip)
%        LUNIT  = unit of length (such as mm and in)
%..........................................................................
%    FRAME TYPE    ITP  NCO  NDN   (NCO and NDN are stored in Array IPR)
%    BEAM           1    1    2
%    PLANAR TRUSS   2    2    2
%    PLANAR FRAME   3    2    3
%    PLANAR GRID    4    2    3
%    SPACE  TRUSS   5    3    3
%    SPACE  FRAME   6    3    6
FTYPE = {'BEAM';'PLANE TRUSS';'PLANE FRAME';'PLANE GRID';'SPACE TRUSS';'SPACE FRAME'};
IPR = [1,2,2,2,3,3;2,2,3,3,3,6];

if nargin == 0 % no input argument
    % Open file with user interface
    [~,FILENAME] = fileparts(uigetfile('*.ipt','Select Input file'));
end

% Get starting time
startTime = clock;

% {FILENAME}.ipt is the input data file.
% {FILENAME}.dat includes the output of the input data and the nodal 
% displacements and member end forces.
IREAD = fopen([FILENAME '.ipt'], 'r');

% Read in the problem title and the structural data
TITLE = fgets(IREAD);
FUNIT = fgets(IREAD);
LUNIT = fgets(IREAD);
ID = '*';

HEADLINE(ID,IREAD);
line = fgets(IREAD);
args = str2num(line);
temp = num2cell(args(1:7));
[NNOD,NBC,NMAT,NSEC,ITP,NNE,IFORCE] = deal(temp{:});

NCO = IPR(1,ITP);
NDN = IPR(2,ITP);
NDE = NDN*NNE;

% Read the remaining data
%%%%% Finish the INPUT function
% ˇ ˇ Starting from here --- PROG 1
[COOR, NFIX, EXLD, IDBC, VECTY, FEF, PROP, SECT] = INPUT(IREAD, ID, NNOD, NBC, NMAT, NSEC, ITP, NCO, NDN, NDE, IFORCE);

% please use the function - drawStructure - here to plot the structure
drawStructure(ITP, COOR, IDBC, NFIX, NBC, NNOD, LUNIT, 'b-');

fclose(IREAD);
% ^ ^ Up to Here --- PROG 1

% 
% % DOF numbering
% % Finish the IDMAT function.
% [IDND,NEQ] = IDMAT( ~ );
% 
% % Create the member DOF table:  LM(NDE,NBC)
% % Finish the MEMDOF function.
% LM = MEMDOF( ~ );
% 
% % Compute the semi-band width,NSBAND, of the global stiffness matrix.
% % Finish the SEMIBAND function.
% NSBAND = SEMIBAND( ~ );
% 
% % Form the global load vector GLOAD(NEQ) from the concentrated nodal loads.
% % Finish the LOAD function.
% GLOAD = LOAD(EXLD, ~ );
% 
% % ^^ UP TO HERE --- PROG 2 ^^
% 
% % Form the global stiffness matrix GLK(NEQ,NSBAND) and obtain the
% % equivalent nodal vector by assembling -(fixed-end forces) of each member
% % into the load vector.
% [GLK,GLOAD] = FORMKP(COOR,IDBC,VECTY,PROP,SECT,LM,FEF,GLOAD,NNOD,NBC,NMAT...
%     ,NSEC,IFORCE,ITP,NCO,NDN,NDE,NNE,NEQ);
% 
% % ^^ UP TO HERE --- PROG 3 ^^
% 
% DISP = SOLVE(GLK, ~ );
% 
% % Determine the member end forces ELFOR(NDE,NBC)
% ELFOR = FORCE( ~ );
% 
% % Get ending time and count the elapased time
% endTime = clock;
% 
% % Print out the results
% IWRITE = fopen([FILENAME '.dat'], 'w');
% OUTPUT( ~ );
% fclose(IWRITE);
% 
% 
% % ^^ UP TO HERE --- PROG 4 ^^
end

function HEADLINE(ID,IREAD)
    while ~feof(IREAD)
        temp = fgets(IREAD);
        if ~isempty(temp) && temp(1) == ID
            return
        end
    end
end

function [COOR, NFIX, EXLD, IDBC, VECTY, FEF, PROP, SECT] = INPUT(IREAD, ID, NNOD, NBC, NMAT, NSEC, ITP, NCO, NDN, NDE, IFORCE)
%..........................................................................
%
%    PURPOSE: Reads in the following data: nodal coordinates,
%             boundary conditions, external nodal loads, identification
%             data (connectivity), direction cosines of the local y-axis
%             (for space frame only; ITP=6), fixed-end forces, material
%             and cross sectional properties.
%..........................................................................
% ˇ ˇ Starting from here --- PROG 1
% COOR - Nodal coordinates
    HEADLINE(ID,IREAD);
    COOR = ReadMatrix(IREAD,NCO,NNOD);
    disp('COOR :');
    disp(COOR');

% NFIX - Boundary conditions
    HEADLINE(ID,IREAD);
    NFIX = ReadMatrix(IREAD,NDN,NNOD);
    disp('NFIX :');
    disp(NFIX');

% EXLD - External nodal loads
    HEADLINE(ID,IREAD);
    EXLD = ReadMatrix(IREAD,NDN,NNOD);
    disp('EXLD :');
    disp(EXLD');

% IDBC - Beam-column identification data
    HEADLINE(ID,IREAD);
    IDBC = ReadMatrix(IREAD,5,NBC);
    disp('IDBC :');
    disp(IDBC');

% VECTY - Direction cosines of the local y-axis (only needed when ITP=6)
    if ITP == 6
        HEADLINE(ID,IREAD);
        VECTY = ReadMatrix(IREAD,3,NBC);
        disp('VECTY :');
        disp(VECTY');
    else
        VECTY = [];
    end

% FEF - Fixed-end forces (only needed when IFORCE=2)
    if IFORCE == 2
        HEADLINE(ID,IREAD);
        FEF = ReadMatrix(IREAD,NDE,NBC);
        disp('FEF :');
        disp(FEF');
    else
        FEF = [];
    end

% PROP - Material properties
    HEADLINE(ID,IREAD);
    PROP = ReadMatrix(IREAD,5,NMAT);
    disp('PROP :');
    disp(PROP');

% SECT - Beam-column properties
    HEADLINE(ID,IREAD);
    SECT = ReadMatrix(IREAD,5,NSEC);
    disp('SECT :');
    disp(SECT');

% ^ ^ Up to here --- PROG 1
end

function mat = ReadMatrix(IREAD, row, col)
% for INPUT function
    mat = zeros(row,col);
    for j = 1:col
        line = fgets(IREAD);
        num = str2num(line);
        mat(:,j) = num(2:row+1);
    end
end

function drawStructure(ITP,COOR,IDBC,NFIX,NBC,NNOD,LUNIT,FORMAT)
% Draw the structure: members in the line style FORMAT, node numbers in
% black, element numbers in red, and the restrained nodes marked with a
% filled triangle (partially restrained) or a filled square (fully restrained).
    NCO = size(COOR,1);
    X = zeros(3,NNOD);  X(1:NCO,:) = COOR;       % pad to 3 rows: one routine serves all ITP
    is3D = ITP >= 5;
    figure; hold on
    for e = 1:NBC
        n1 = IDBC(1,e);  n2 = IDBC(2,e);
        if is3D
            plot3(X(1,[n1 n2]),X(2,[n1 n2]),X(3,[n1 n2]),FORMAT,'linewidth',2)
        else
            plot(X(1,[n1 n2]),X(2,[n1 n2]),FORMAT,'linewidth',2)
        end
    end
    d = 0.025*max(max(X,[],2) - min(X,[],2));   % label offset, 2.5% of the largest dimension
    for n = 1:NNOD                                % node numbers
        if is3D, text(X(1,n)+d,X(2,n)+d,X(3,n)+d,num2str(n),'FontWeight','bold');
        else,    text(X(1,n)+d,X(2,n)+d,num2str(n),'FontWeight','bold'); end
    end
    for e = 1:NBC                                 % element numbers at the midpoints
        xm = mean(X(:,IDBC(1:2,e)),2);
        if is3D, text(xm(1),xm(2),xm(3),num2str(e),'Color','r','HorizontalAlignment','center','BackgroundColor','w');
        else,    text(xm(1),xm(2),num2str(e),'Color','r','HorizontalAlignment','center','BackgroundColor','w'); end
    end
    for n = 1:NNOD                                % nodes and supports
        r = NFIX(:,n) == -1;
        if all(r),     mk = 's';  fc = 'k';       % fully restrained
        elseif any(r), mk = '^';  fc = 'k';       % partially restrained
        else,          mk = 'o';  fc = 'w';       % free node
        end
        if is3D, plot3(X(1,n),X(2,n),X(3,n),mk,'MarkerSize',8,'MarkerFaceColor',fc,'MarkerEdgeColor','k');
        else,    plot(X(1,n),X(2,n),mk,'MarkerSize',8,'MarkerFaceColor',fc,'MarkerEdgeColor','k'); end
    end
    xlabel(['X ', LUNIT])
    switch ITP
        case 1,     title('Beam');     ylim([-0.15 0.15]*max(d/0.025,1))
        case 2,     title('2D truss'); ylabel(['Y ', LUNIT]); axis equal
        case 3,     title('2D frame'); ylabel(['Y ', LUNIT]); axis equal
        case 4,     title('2D grid');  ylabel(['Z ', LUNIT]); axis equal
        case 5,     title('3D truss'); ylabel(['Y ', LUNIT]); zlabel(['Z ', LUNIT]); axis equal; view(3)
        case 6,     title('3D frame'); ylabel(['Y ', LUNIT]); zlabel(['Z ', LUNIT]); axis equal; view(3)
    end
    grid on; hold off
end

