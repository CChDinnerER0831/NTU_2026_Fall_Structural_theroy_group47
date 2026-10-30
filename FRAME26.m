classdef FRAME26 < handle
    % FRAME26: A linear analysis program for framed structures
    %..........................................................................
    %    Programmer:  C. H. Chen R15521239  & Jay Wu R15521221
    %                 Supervised by Assistant Professor Chun-Yu Ke
    %                 For the course: Advanced Structural Theory
    %                 Department of Civil Engineering
    %                 National Taiwan University
    %                 Fall 2026   All Rights Reserved
    
    properties
        % File properties
        FILENAME
        TITLE
        FUNIT
        LUNIT
        
        % Programmer Info
        PRPGRAMMER = sprintf("C. H. Chen R15521239  & Jay Wu R15521221 \n Supervised by Assistant Professor Chun-Yu Ke")
        
        % Structural counts & options
        NNOD; NBC; NMAT; NSEC; ITP; NNE; IFORCE
        NCO; NDN; NDE
        
        % Structural Data Arrays
        COOR
        NFIX
        EXLD
        IDBC
        VECTY
        FEF
        PROP
        SECT
        
        % PROG 2 Calculated Properties
        IDND
        NEQ
        LM
        NSBAND
        GLOAD
        
        % Mapping array for coordinates (NCO) and DOFs (NDN) per element type
        IPR = [1,2,2,2,3,3; 2,2,3,3,3,6];
    end
    
    methods
        % Constructor
        function obj = FRAME26(filename)
            if nargin == 0
                [file, path] = uigetfile('*.ipt', 'Select Input file');
                if isequal(file, 0)
                    return;
                end
                obj.FILENAME = fullfile(path, file);
            else
                obj.FILENAME = filename;
            end
            
            if exist(obj.FILENAME, 'file') ~= 2
                error(['Cannot find file: ', obj.FILENAME, '. Ensure path is correct.']);
            end
            
            % 1. Read input data (PROG 1)
            obj.readInput();
            
            % 2. Perform degree-of-freedom and load setup (PROG 2)
            obj.computeProg2();
        end
        
        % --- PROG 1: Read Input File ---
        function obj = readInput(obj)
            IREAD = fopen(obj.FILENAME, 'r');
            obj.TITLE = fgets(IREAD);
            obj.FUNIT = fgets(IREAD);
            obj.LUNIT = fgets(IREAD);
            
            obj.headLine('*', IREAD);
            
            args = [];
            while ~feof(IREAD) && length(args) < 7
                line = fgets(IREAD);
                if ischar(line)
                    args = str2num(line); %#ok<ST2NM>
                end
            end
            
            if length(args) < 7
                error('EORROR INPUT FILE');
            end
            
            obj.NNOD = args(1); obj.NBC = args(2); obj.NMAT = args(3); 
            obj.NSEC = args(4); obj.ITP = args(5); obj.NNE = args(6); obj.IFORCE = args(7);
            
            obj.NCO = obj.IPR(1, obj.ITP);
            obj.NDN = obj.IPR(2, obj.ITP);
            obj.NDE = obj.NDN * obj.NNE;
            
            % Read Coordinate (COOR)
            obj.headLine('*', IREAD);
            obj.COOR = obj.readMatrix(IREAD, obj.NCO, obj.NNOD);
            
            % Read Boundary Conditions (NFIX)
            obj.headLine('*', IREAD);
            obj.NFIX = obj.readMatrix(IREAD, obj.NDN, obj.NNOD);
            
            % Read External Nodal Loads (EXLD)
            obj.headLine('*', IREAD);
            obj.EXLD = obj.readMatrix(IREAD, obj.NDN, obj.NNOD);
            
            % Read Element Connectivity (IDBC)
            obj.headLine('*', IREAD);
            obj.IDBC = obj.readMatrix(IREAD, 5, obj.NBC);
            
            % Read Local y-axis vectors (VECTY) for Space Frame
            if obj.ITP == 6
                obj.headLine('*', IREAD);
                obj.VECTY = obj.readMatrix(IREAD, 3, obj.NBC);
            end
            
            % Read Fixed-End Forces (FEF)
            if obj.IFORCE == 2
                obj.headLine('*', IREAD);
                obj.FEF = obj.readMatrix(IREAD, obj.NDE, obj.NBC);
            end
            
            % Read Material Properties (PROP)
            obj.headLine('*', IREAD);
            obj.PROP = obj.readMatrix(IREAD, 5, obj.NMAT);
            
            % Read Cross-Section Properties (SECT)
            obj.headLine('*', IREAD);
            obj.SECT = obj.readMatrix(IREAD, 5, obj.NSEC);
            
            fclose(IREAD);
        end
        
        % --- PROG 2: Compute DOF Mapping & Load Vector ---
        function obj = computeProg2(obj)
            % 1. Compute IDND & NEQ
            [obj.IDND, obj.NEQ] = obj.computeIDMAT();
            
            % 2. Compute LM Matrix
            obj.LM = obj.computeMEMDOF();
            
            % 3. Compute Semiband Width
            obj.NSBAND = obj.computeSEMIBAND();
            
            % 4. Compute Global Load Vector
            obj.GLOAD = obj.computeLOAD();     
        end
        
        % IDMAT: Transform NFIX to IDND and calculate NEQ
        function [IDND, NEQ] = computeIDMAT(obj)
            IDND = zeros(obj.NDN, obj.NNOD);
            neq = 0;
            for j = 1:obj.NNOD
                for i = 1:obj.NDN
                    if obj.NFIX(i, j) == 0
                        neq = neq + 1;
                        IDND(i, j) = neq;
                    else
                        IDND(i, j) = 0;
                    end
                end
            end
            NEQ = neq;
        end
        
        % MEMDOF: Compute Member Location Matrix (LM)
        function LM = computeMEMDOF(obj)
            LM = zeros(obj.NDE, obj.NBC);
            for e = 1:obj.NBC
                n1 = obj.IDBC(1, e);
                n2 = obj.IDBC(2, e);
                
                dof_n1 = obj.IDND(:, n1);
                dof_n2 = obj.IDND(:, n2);
                
                LM(:, e) = [dof_n1; dof_n2];
            end
        end
        
        % SEMIBAND: Calculate Semiband Width (NSBAND)
        function NSBAND = computeSEMIBAND(obj)
            max_band = 0;
            for e = 1:obj.NBC
                active_dofs = obj.LM(obj.LM(:, e) > 0, e);
                if ~isempty(active_dofs)
                    current_band = max(active_dofs) - min(active_dofs) + 1;
                    if current_band > max_band
                        max_band = current_band;
                    end
                end
            end
            NSBAND = max_band;
        end
        
        % LOAD: Compute Global Load Vector (GLOAD)
        function GLOAD = computeLOAD(obj)
            GLOAD = zeros(obj.NEQ, 1);
            for j = 1:obj.NNOD
                for i = 1:obj.NDN
                    dof = obj.IDND(i, j);
                    if dof > 0
                        GLOAD(dof) = GLOAD(dof) + obj.EXLD(i, j);
                    end
                end
            end
        end
        
        % --- Visualization ---
        function drawStructure(obj, FORMAT)
            if nargin < 2
                FORMAT = 'b-';
            end
            
            NCO_local = size(obj.COOR, 1);
            X = zeros(3, obj.NNOD);  
            X(1:NCO_local, :) = obj.COOR;       
            is3D = obj.ITP >= 5;
            
            figure; hold on
            
            % Draw members
            for e = 1:obj.NBC
                n1 = obj.IDBC(1, e);  n2 = obj.IDBC(2, e);
                if is3D
                    plot3(X(1, [n1 n2]), X(2, [n1 n2]), X(3, [n1 n2]), FORMAT, 'LineWidth', 2)
                else
                    plot(X(1, [n1 n2]), X(2, [n1 n2]), FORMAT, 'LineWidth', 2)
                end
            end
            
            d = 0.025 * max(max(X, [], 2) - min(X, [], 2));
            
            % Joint No.
            for n = 1:obj.NNOD
                if is3D
                    text(X(1, n)+d, X(2, n)+d, X(3, n)+d, num2str(n), 'FontWeight', 'bold');
                else
                    text(X(1, n)+d, X(2, n)+d, num2str(n), 'FontWeight', 'bold'); 
                end
            end
            
            % Member No.
            for e = 1:obj.NBC
                xm = mean(X(:, obj.IDBC(1:2, e)), 2);
                if is3D
                    text(xm(1), xm(2), xm(3), num2str(e), 'Color', 'r', 'HorizontalAlignment', 'center', 'BackgroundColor', 'w');
                else
                    text(xm(1), xm(2), num2str(e), 'Color', 'r', 'HorizontalAlignment', 'center', 'BackgroundColor', 'w'); 
                end
            end
            
            % Joint and support
            for n = 1:obj.NNOD
                r = obj.NFIX(:, n) == -1;
                if all(r)
                    mk = 's';  fc = 'k';       % Fully fixed
                elseif any(r)
                    mk = '^';  fc = 'k';       % Hinge/Roller
                else
                    mk = 'o';  fc = 'w';       % Free
                end
                
                if is3D
                    plot3(X(1, n), X(2, n), X(3, n), mk, 'MarkerSize', 8, 'MarkerFaceColor', fc, 'MarkerEdgeColor', 'k');
                else
                    plot(X(1, n), X(2, n), mk, 'MarkerSize', 8, 'MarkerFaceColor', fc, 'MarkerEdgeColor', 'k'); 
                end
            end
            
            xlabel(['X ', strtrim(obj.LUNIT)])
            switch obj.ITP
                case 1, title('Beam');     ylim([-0.15 0.15] * max(d/0.025, 1));
                case 2, title('2D truss'); ylabel(['Y ', strtrim(obj.LUNIT)]); axis equal;
                case 3, title('2D frame'); ylabel(['Y ', strtrim(obj.LUNIT)]); axis equal;
                case 4, title('2D grid');  ylabel(['Z ', strtrim(obj.LUNIT)]); axis equal;
                case 5, title('3D truss'); ylabel(['Y ', strtrim(obj.LUNIT)]); zlabel(['Z ', strtrim(obj.LUNIT)]); axis equal; view(3);
                case 6, title('3D frame'); ylabel(['Y ', strtrim(obj.LUNIT)]); zlabel(['Z ', strtrim(obj.LUNIT)]); axis equal; view(3);
            end
            grid on; hold off
        end
    end
    
    methods (Access = private)
        % Helper: Skip headline comments
        function headLine(~, ID, IREAD)
            while ~feof(IREAD)
                temp = fgets(IREAD);
                if ~isempty(temp) && temp(1) == ID
                    return
                end
            end
        end
        
        % Helper: Read Matrix Data
        function mat = readMatrix(~, IREAD, row, col)
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
    end
end

