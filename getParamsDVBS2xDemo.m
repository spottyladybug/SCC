function dvb = getParamsDVBS2xDemo(subsystemType, EsNodB, numLDPCDecIterations)
%getParamsDVBS2xDemo DVB-S.2x link parameters
%   DVB = getParamsDVBS2xDemo(TYPE, ESN0, NUMITER) returns DVB-S.2x link
%   parameters for subsystem type, TYPE, energy per symbol to noise power
%   spectral density ratio in dB, ESN0, and number of LDPC decoder
%   iterations, NUMITER. The output, DVB, is a structure with fields
%   specifying the parameter name and value.

validatestring(subsystemType, {'QPSK 1/4', ...
'QPSK 1/3', ...
'QPSK 2/5', ...
'QPSK 1/2', ...
'QPSK 3/5', ...
'QPSK 2/3', ...
'QPSK 3/4', ...
'QPSK 4/5', ...
'QPSK 5/6', ...
'QPSK 8/9', ...
'QPSK 9/10', ...
'QPSK 13/45', ...
'QPSK 9/20', ...
'QPSK 11/20', ...
'QPSK 11/45', ...
'QPSK 4/15', ...
'QPSK 14/45', ...
'QPSK 7/15', ...
'QPSK 8/15', ...
'QPSK 32/45', ...
'8PSK 3/5', ...
'8PSK 4/5', ...
'8PSK 2/3', ...
'8PSK 3/4', ...
'8PSK 5/6', ...
'8PSK 8/9', ...
'8PSK 9/10', ...
'8PSK 23/36', ...
'8PSK 25/36', ...
'8PSK 13/18', ...
'8PSK 7/15', ...
'8PSK 8/15', ...
'8PSK 26/45', ...
'8PSK 32/45', ...
'8APSK 100/180', ...
'8APSK 104/180', ...
'16APSK 2/3', ...
'16APSK 3/4', ...
'16APSK 4/5', ...
'16APSK 5/6', ...
'16APSK 8/9', ...
'16APSK 9/10', ...
'16APSK 26/45', ...
'16APSK 3/5', ...
'16APSK 28/45', ...
'16APSK 23/36', ...
'16APSK 25/36', ...
'16APSK 13/18', ...
'16APSK 140/180', ...
'16APSK 154/180', ...
'32APSK 3/4', ...
'32APSK 4/5', ...
'32APSK 5/6', ...
'32APSK 8/9', ...
'32APSK 9/10', ...
'32APSK 2/3', ...
'32APSK 128/180', ...
'32APSK 132/180', ...
'32APSK 140/180', ...
'64APSK 128/180', ...
'64APSK 132/180', ...
'64APSK 4/5', ...
'64APSK 5/6', ...
'64APSK 7/9', ...
'128APSK 135/180', ...
'128APSK 140/180', ...
'256APSK 116/180', ...
'256APSK 20/30', ...
'256APSK 124/180', ...
'256APSK 128/180', ...
'256APSK 22/30', ...
'256APSK 135/180', ...
}, 'getParamsDVBS2xDemo', 'TYPE', 1);
        
validateattributes(EsNodB, {'numeric'}, ...
    {'finite', 'scalar'}, 'getParamsDVBS2xDemo', 'ESNO', 2);

validateattributes(numLDPCDecIterations, {'numeric'}, ...
    {'positive', 'integer', 'scalar'}, 'getParamsDVBS2xDemo', 'NUMITER', 3);

systemInfo = split(subsystemType, " ");
modulationType = char(systemInfo(1));
dvb.CodeRate = char(systemInfo(2));
codeRate = str2num(dvb.CodeRate); %#ok<ST2NM>

dvb.EsNodB = EsNodB;
dvb.ModulationType = modulationType;

%--------------------------------------------------------------------------
% Source

dvb.NumBytesPerPacket = 188;
byteSize = 8;
dvb.NumBitsPerPacket = dvb.NumBytesPerPacket * byteSize;

%--------------------------------------------------------------------------
% BCH coding

[dvb.BCHCodewordLength, ...
 dvb.BCHMessageLength, ...
 dvb.BCHGeneratorPoly] = getbchparameters(codeRate);
dvb.BCHPrimitivePoly = de2bi(65581, 'left-msb');
dvb.NumPacketsPerBBFrame =floor(dvb.BCHMessageLength/dvb.NumBitsPerPacket);
dvb.NumInfoBitsPerCodeword = dvb.NumPacketsPerBBFrame*dvb.NumBitsPerPacket;
dvb.BitPeriod = 1/dvb.NumInfoBitsPerCodeword;

%--------------------------------------------------------------------------
% LDPC coding

dvb.LDPCCodewordLength = 64800;
dvb.LDPCParityCheckMatrix = dvbs2xldpc(codeRate);
if isempty(numLDPCDecIterations)
    dvb.LDPCNumIterations = 50;
else
    dvb.LDPCNumIterations = numLDPCDecIterations;
end

%--------------------------------------------------------------------------
% Interleaver: Section 5.3.3, p. 23

% No interleaving (for BPSK and QPSK)
dvb.InterleaveOrder = (1:dvb.LDPCCodewordLength).';

switch modulationType
    case '8PSK'
        Ncol = 3;
        iTemp = reshape(dvb.InterleaveOrder, ...
            dvb.LDPCCodewordLength/Ncol, Ncol).';
        if codeRate == 3/5
            % Special Case - Figure 8
            iTemp = flipud(iTemp);
        end
        dvb.InterleaveOrder = iTemp(:);
	case '8APSK'
        Ncol = 3;
        iTemp = reshape(dvb.InterleaveOrder, ...
            dvb.LDPCCodewordLength/Ncol, Ncol).';
        dvb.InterleaveOrder = iTemp(:);
    case '16APSK'
        Ncol = 4;
        iTemp = reshape(dvb.InterleaveOrder, ...
            dvb.LDPCCodewordLength/Ncol, Ncol).';
        dvb.InterleaveOrder = iTemp(:);
    case '32APSK'
        Ncol = 5;
        iTemp = reshape(dvb.InterleaveOrder, ...
            dvb.LDPCCodewordLength/Ncol, Ncol).';
        dvb.InterleaveOrder = iTemp(:);
    case '64APSK'
        Ncol = 6;
        iTemp = reshape(dvb.InterleaveOrder, ...
            dvb.LDPCCodewordLength/Ncol, Ncol).';
        dvb.InterleaveOrder = iTemp(:);
	case '128APSK'
        Ncol = 7;
        iTemp = reshape(dvb.InterleaveOrder, ...
            dvb.LDPCCodewordLength/Ncol, Ncol).';
        dvb.InterleaveOrder = iTemp(:);
	case '256APSK'
        Ncol = 8;
        iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
        dvb.InterleaveOrder = iTemp(:);
end

%--------------------------------------------------------------------------
% Modulation

switch modulationType
    case 'BPSK'
        Ry = [+1; -1];
        dvb.Constellation = complex(Ry);
        dvb.SymbolMapping = [0 1];
        dvb.PhaseOffset = 0;
        warning(message('comm:getParamsDVBS2Demo:InvalidModulationType')); 
    case 'QPSK'
        Ry = [+1; +1; -1; -1];
        Iy = [+1; -1; +1; -1];
        dvb.Constellation = (Ry + 1i*Iy)/sqrt(2);
        dvb.SymbolMapping = [0 2 3 1];
        dvb.PhaseOffset = pi/4;
    case '8PSK'
        A = sqrt(1/2);
        Ry = [+A +1 -1 -A  0 +A -A  0].';
        Iy = [+A  0  0 -A  1 -A +A -1].';
        dvb.Constellation = Ry + 1i*Iy;
        dvb.SymbolMapping  = [1 0 4 6 2 3 7 5];
        dvb.PhaseOffset = 0;
    case '8APSK'
        dvb.Constellation = dvbsapskmod((0:7)', 8, 's2x', ...
                        dvb.CodeRate, 'UnitAveragePower', true);
        dvb.SymbolMapping  = [4 0 6 2 1 5 7 3];
        dvb.PhaseOffset = [pi/2 pi/4 pi/2];
    case '16APSK'
        dvb.Constellation = dvbsapskmod((0:15)', 16, 's2x', ...
                        dvb.CodeRate, 'UnitAveragePower', true);
        if ismember(codeRate, [90/180, 96/180, 100/180, 18/30, 20/30])
            dvb.PhaseOffset = [pi/8 pi/8];
            dvb.SymbolMapping = [0 1 3 2 6 7 5 4 8 9 11 10 14 15 13 12];
        else
            dvb.PhaseOffset = [pi/4 pi/12];
            dvb.SymbolMapping = [12 14 15 13 4 0 8 10 2  6 7 3 11 9 1 5];
        end
    case '32APSK'
        dvb.Constellation = dvbsapskmod((0:31)', 32, 's2x', ...
                          dvb.CodeRate, 'UnitAveragePower', true);
        if ismember(codeRate, [128/180 132/180 140/180])
            dvb.PhaseOffset = [pi/4 pi/8 pi/4 pi/16];
            dvb.SymbolMapping = [0 4 6 2 8 16 20 12 14 22 18 10 ...
                24 28 30 26 9 25 17 1 5 21 29 15 31 23 7 3 19 27 11];
        else
            dvb.PhaseOffset = [pi/4 pi/12 pi/16];
            dvb.SymbolMapping = [15 13 29 31 14 6 7 5 4 12 28 20 21 23 22 30 ...
                11 10 2 3 1 0 8 9 25 24 16 17 19 18 26 27];
        end
    case '64APSK'
        dvb.Constellation = dvbsapskmod((0:63)', 64, 's2x', ...
                          dvb.CodeRate, 'UnitAveragePower', true);
        if codeRate == 128/180
            dvb.PhaseOffset = [pi/4 pi/8 pi/4 pi/16];
            dvb.SymbolMapping = [0 1 3 2 6 7 5 4 12 13 15 14 10 11 9 8 ...
                16 17 19 18 22 23 21 20 28 29 31 30 26 27 25 24 ...
                48 49 51 50 54 55 53 52 60 61 63 62 58 59 57 56 ...
                32 33 37 36 38 39 37 36 44 45 47 46 42 43 41 40];
        end
        if ismember(codeRate, [7/9 4/5 5/6])
            dvb.PhaseOffset = [pi/8 pi/16 pi/20 pi/20];
            dvb.SymbolMapping = [52 48 56 60 28 24 16 20 ...
                64 50 34 32 40 42 58 62 30 26 10 8 0 2 18 32 ...
                61 51 35 39 46 47 43 59 63 31 27 11 15 14 6 7 3 19 23 ...
                53 49 33 37 36 44 45 41 57 61 29 25 9 13 12 4 5 1 17 21];
        end
        if codeRate == 132/180
            dvb.PhaseOffset = [pi/4 pi/12 pi/20 pi/28];
            dvb.SymbolMapping = [12 14 15 13 ...
                28 60 44 46 62 30 31 63 47 45 61 29 ...
                24 56 48 52 36 38 54 62 50 26 27 59 51 55 39 37 53 49 57 25 ...
                8 40 32 0 16 20 4 6 22 18 2 34 42 10 11 43 35 3 19 23 7 5 21 17 1 33 41 9];
        end
    case '128APSK'
        dvb.Constellation = dvbsapskmod((0:127)', 128, 's2x', ...
                          dvb.CodeRate, 'UnitAveragePower', true);
        dvb.PhaseOffset = 0;
    case '256APSK'
        dvb.Constellation = dvbsapskmod((0:255)', 256, 's2x', ...
                          dvb.CodeRate, 'UnitAveragePower', true);
        dvb.PhaseOffset = 0;
    otherwise
        error(message('comm:getParamsDVBS2Demo:ModulationUnsupported'));
end

numModLevels = length(dvb.Constellation);
dvb.BitsPerSymbol = log2(numModLevels);
dvb.ModulationOrder = 2^dvb.BitsPerSymbol;
%--------------------------------------------------------------------------
% Complex scrambling sequence

dvb.SequenceIndex = 2;

%--------------------------------------------------------------------------
% Number of symbols per codeword

dvb.NumSymsPerCodeword = dvb.LDPCCodewordLength/dvb.BitsPerSymbol;

%--------------------------------------------------------------------------
% Noise variance for channel and estimate for LDPC coding

dvb.NoiseVar  = 1/(10^(dvb.EsNodB/10));
dvb.NoiseVarEst = dvb.NoiseVar/(2*sin(pi/numModLevels)); 
% Note that NoiseVarEst for QPSK is NoiseVar/(2*sqrt(2))

%--------------------------------------------------------------------------
% Delays

dvb.RecDelayPreBCH = dvb.BCHMessageLength;

%--------------------------------------------------------------------------
function [nBCH, kBCH, genBCH] = getbchparameters(R)

table5a = [
    2/9 14208 14400 12 61560
    1/4 16008 16200 12 64800 
    13/45 18528 18720 12 64800
    1/3 21408 21600 12 64800 
    2/5 25728 25920 12 64800
    9/20 28968 29160 12 64800
    1/2 32208 32400 12 64800
    11/20 35448 35640 12 64800
    100/180 35248 37440 12 64800
    104/180 37248 37440 12 64800
    26/45 37248 37440 12 64800
    3/5 38688 38880 12 64800
    28/45 40128 40320 12 64800
    23/36 41208 41400 12 64800
    116/180 41568 41760 12 64800
    20/30 43008 43200 12 64800
    2/3 43040 43200 10 64800
    124/180 44448 44640 12 64800
    25/36 44808 45000 12 64800
    13/18 46328 46800 12 64800
    132/180 47328 47520 12 64800
    22/30 48408 48600 12 64800
    4/5 51648 51840 12 64800
    5/6 53840 54000 10 64800
    8/9  57472 57600 8 64800
    9/10 58192 58320 8 64800
    7/9 50208 50400 12 64800
    154/180 55248 55440 12 64800];

[~,rowidx] = ismember(R,table5a(:,:));
kBCH = table5a(rowidx,2);
nBCH = table5a(rowidx,3);
tBCH = table5a(rowidx,4);

a8 = [1  0  0  0  1  1  1  0  0  0  0  0  0  0  1 ...
    1  1  0  0  1  0  0  1  0  1  0  1  0  1  1 ...
    1  1  1  0  1  1  1  0  0  0  1  0  0  1  0 ...
    0  1  1  1  1  0  0  1  0  1  1  1  1  0  1 ...
    1  1  1  0  1  0  0  0  1  1  0  0  1  1  1 ...
    1  1  1  1  0  0  0  1  1  0  1  1  0  1  0 ...
    1  1  1  0  1  0  1  0  0  0  0  0  1  0  0 ...
    1  1  1  1  1  0  0  1  0  1  1  0  0  1  1 ...
    0  0  0  1  0  1  0  1  1];

a10 = [1  0  1  1  0  0  0  0  0  0  0  0  1  0  1 ...
    0  1  0  0  0  0  1  1  0  0  1  1  1  0  1 ...
    1  0  1  1  1  1  1  1  1  0  0  0  0  1  0 ...
    1  0  1  0  0  0  1  1  0  0  1  1  0  0  0 ...
    1  1  1  1  1  0  1  1  0  1  0  1  0  0  1 ...
    1  1  1  0  0  0  0  1  0  1  0  1  1  1  0 ...
    0  0  0  0  0  1  1  1  1  1  0  1  1  1  1 ...
    1  1  0  1  0  0  0  1  0  0  1  0  0  0  1 ...
    1  0  0  0  0  0  0  0  1  1  0  1  1  1  0 ...
    0  0  1  0  1  1  1  0  1  1  0  1  1  0  0 ...
    1  0  1  1  0  0  1  0  0  0  1];

a12 = [1  0  1  0  0  1  1  1  0  0  0  1  0  0  1 ...
    1  0  0  0  0  0  1  1  1  0  1  0  0  0  0 ...
    0  1  1  1  0  0  0  0  1  0  0  0  1  0  1 ...
    1  1  0  0  0  1  0  1  0  0  0  1  0  0  0 ...
    1  1  1  0  0  0  1  0  1  0  0  0  0  1  1 ...
    0  0  1  1  1  1  0  0  1  0  1  1  0  0  1 ...
    1  0  1  1  0  0  0  1  1  0  1  1  1  0  0 ...
    0  0  1  1  0  1  0  1  0  0  0  0  1  0  0 ...
    0  1  0  0  0  1  0  0  1  0  0  0  0  0  0 ...
    1  1  0  1  0  0  0  1  1  1  1  0  0  0  0 ...
    1  0  1  1  1  1  1  0  1  1  1  0  1  1  0 ...
    0  1  1  0  0  0  0  0  0  0  1  0  0  1  0 ...
    1  0  1  0  1  1  1  1  0  0  1  1  1];

switch tBCH
case 8
    genBCH = a8;
case 10
    genBCH = a10;
case 12
    genBCH = a12;
end
