classdef FRAME26 < handle

    % FRAME26: A linear analysis program for framed structures
    %..........................................................................
    %    Programmer:  C. H. Chen R15521239  & Jay Wu R15521221
    %                 Supervised by Assistant Professor Chun-Yu Ke
    %                 For the course: Advanced Structural Theory
    %                 Department of Civil Engineering
    %                 National Taiwan University
    %                 Fall 2026 © All Rights Reserved
    properties
        % file property
        FILENAME
        TITLE
        FUNIT
        LUNIT
        %programmer
        PRPGRAMMER = "C. H. Chen R15521239  & Jay Wu R15521221 \n Supervised by Assistant Professor Chun-Yu Ke"
        % Structural property
        NNOD, NBC, NMAT, NSEC, ITP, NNE, IFORCE
        NCO, NDN, NDE
        
        %Coordinate properties
        COOR
        NFIX
        EXLD
        IDBC
        VECTY
        FEF
        PROP
        SECT

        IPR = [1,2,2,2,3,3; 2,2,3,3,3,6];
    end
    
    methods

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
                error(['cant find file: ', obj.FILENAME, 'ensure path is correct']);
            end
            obj.readInput();
        end
        
        % ˇ ˇ Starting from here --- PROG 1
        function obj = readInput(obj)
            IREAD = fopen(obj.FILENAME, 'r');
            obj.TITLE = fgets(IREAD);
            obj.FUNIT = fgets(IREAD);
            obj.LUNIT = fgets(IREAD);
            
            % 讀取控制參數
            obj.headLine('*', IREAD);
            args = str2num(fgets(IREAD));
            
            obj.NNOD = args(1); obj.NBC = args(2); obj.NMAT = args(3); 
            obj.NSEC = args(4); obj.ITP = args(5); obj.NNE = args(6); obj.IFORCE = args(7);
            
            obj.NCO = obj.IPR(1, obj.ITP);
            obj.NDN = obj.IPR(2, obj.ITP);
            obj.NDE = obj.NDN * obj.NNE;
            
            % COOR
            obj.headLine('*', IREAD);
            obj.COOR = obj.readMatrix(IREAD, obj.NCO, obj.NNOD);
            
            % NFIX
            obj.headLine('*', IREAD);
            obj.NFIX = obj.readMatrix(IREAD, obj.NDN, obj.NNOD);
            
            % EXLD
            obj.headLine('*', IREAD);
            obj.EXLD = obj.readMatrix(IREAD, obj.NDN, obj.NNOD);
            
            % IDBC
            obj.headLine('*', IREAD);
            obj.IDBC = obj.readMatrix(IREAD, 5, obj.NBC);
            
            % VECTY (ITP=6)
            if obj.ITP == 6
                obj.headLine('*', IREAD);
                obj.VECTY = obj.readMatrix(IREAD, 3, obj.NBC);
            end
            
            % FEF (IFORCE=2)
            if obj.IFORCE == 2
                obj.headLine('*', IREAD);
                obj.FEF = obj.readMatrix(IREAD, obj.NDE, obj.NBC);
            end
            
            % PROP
            obj.headLine('*', IREAD);
            obj.PROP = obj.readMatrix(IREAD, 5, obj.NMAT);
            
            % SECT
            obj.headLine('*', IREAD);
            obj.SECT = obj.readMatrix(IREAD, 5, obj.NSEC);
            
            fclose(IREAD);
        end
        % ^ ^ Up to Here --- PROG 1

        function drawStructure(obj, FORMAT)
       
            if nargin < 2
                FORMAT = 'b-';
            end
            
            NCO_local = size(obj.COOR, 1);
            X = zeros(3, obj.NNOD);  
            X(1:NCO_local, :) = obj.COOR;       
            is3D = obj.ITP >= 5;
            
            figure; hold on
            
            %draw members
            for e = 1:obj.NBC
                n1 = obj.IDBC(1,e);  n2 = obj.IDBC(2,e);
                if is3D
                    plot3(X(1,[n1 n2]), X(2,[n1 n2]), X(3,[n1 n2]), FORMAT, 'linewidth', 2)
                else
                    plot(X(1,[n1 n2]), X(2,[n1 n2]), FORMAT, 'linewidth', 2)
                end
            end
            
            d = 0.025 * max(max(X,[],2) - min(X,[],2));   
            
            % Joint No.
            for n = 1:obj.NNOD                                
                if is3D
                    text(X(1,n)+d, X(2,n)+d, X(3,n)+d, num2str(n), 'FontWeight', 'bold');
                else
                    text(X(1,n)+d, X(2,n)+d, num2str(n), 'FontWeight', 'bold'); 
                end
            end
            
            % member NO.
            for e = 1:obj.NBC                                 
                xm = mean(X(:, obj.IDBC(1:2,e)), 2);
                if is3D
                    text(xm(1), xm(2), xm(3), num2str(e), 'Color', 'r', 'HorizontalAlignment', 'center', 'BackgroundColor', 'w');
                else
                    text(xm(1), xm(2), num2str(e), 'Color', 'r', 'HorizontalAlignment', 'center', 'BackgroundColor', 'w'); 
                end
            end
            
            % joint and support
            for n = 1:obj.NNOD                                
                r = obj.NFIX(:,n) == -1;
                if all(r)
                    mk = 's';  fc = 'k';       %fixed end
                elseif any(r)
                    mk = '^';  fc = 'k';       % hinge
                else
                    mk = 'o';  fc = 'w';       % free end
                end
                
                if is3D
                    plot3(X(1,n), X(2,n), X(3,n), mk, 'MarkerSize', 8, 'MarkerFaceColor', fc, 'MarkerEdgeColor', 'k');
                else
                    plot(X(1,n), X(2,n), mk, 'MarkerSize', 8, 'MarkerFaceColor', fc, 'MarkerEdgeColor', 'k'); 
                end
            end
            
            xlabel(['X ', strtrim(obj.LUNIT)])
            switch obj.ITP
                case 1
                    title('Beam');     ylim([-0.15 0.15] * max(d/0.025, 1));
                case 2
                    title('2D truss'); ylabel(['Y ', strtrim(obj.LUNIT)]); axis equal;
                case 3
                    title('2D frame'); ylabel(['Y ', strtrim(obj.LUNIT)]); axis equal;
                case 4
                    title('2D grid');  ylabel(['Z ', strtrim(obj.LUNIT)]); axis equal;
                case 5
                    title('3D truss'); ylabel(['Y ', strtrim(obj.LUNIT)]); zlabel(['Z ', strtrim(obj.LUNIT)]); axis equal; view(3);
                case 6
                    title('3D frame'); ylabel(['Y ', strtrim(obj.LUNIT)]); zlabel(['Z ', strtrim(obj.LUNIT)]); axis equal; view(3);
            end
            grid on; hold off
        end
    end 
    
    methods (Access = private)
        %find headline 
        function headLine(~, ID, IREAD)
            while ~feof(IREAD)
                temp = fgets(IREAD);
                if ~isempty(temp) && temp(1) == ID
                    return
                end
            end
        end
        
        % get Matrix
        function mat = readMatrix(~, IREAD, row, col)
            mat = zeros(row, col);
            for j = 1:col
                line = fgets(IREAD);
                num = str2num(line);
                if isempty(num)
                    continue;
                end
                mat(:, j) = num(2:row+1);
            end
        end
    end 
    
end 