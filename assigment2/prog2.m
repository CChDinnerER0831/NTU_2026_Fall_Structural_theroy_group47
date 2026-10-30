%     Advanced Structural Theory 2026
%
%     Program Assignment No. 2
%
%        Assigned:  10/15/2026
%        Due:       11/05/2026
%
%      (1) Complete the functions IDMAT, MEMDOF and SEMIBAND below and add
%          them (together with LOAD, which is given) to your FRAME26.m. =Done=
%      (2) Complete the main program FRAME26 up to the point marked
%          % ^^ UP TO HERE --- PROG 2 ^^  =Done=
%      (3) Test your program with the five input files described in
%          "prog2.pdf": the three files of Programming Assignment 1, the
%          frame with an internal hinge, and the renumbered truss. For each
%          file, print IDND, NEQ, LM, NSBAND and GLOAD to the command window.
%      (4) Submit a zip file named with the student ID of the member who
%          uploads it, containing FRAME26.m, the five input files and
%          README.txt (see prog2.pdf). One submission per programming group.
%


%==========================================================================
% IDMAT FUNCTION
%==========================================================================
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
%==========================================================================
% MEMDOF FUNCTION
%==========================================================================
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
%==========================================================================
% LOAD FUNCTION
%==========================================================================
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


% You don't have to change anything in this function.
GLOAD = zeros(NEQ,1);
for j = 1:NNOD
    for i = 1:NDN
        if IDND(i,j) > 0
            GLOAD(IDND(i,j)) = GLOAD(IDND(i,j))+EXLD(i,j);
        end
    end
end
end