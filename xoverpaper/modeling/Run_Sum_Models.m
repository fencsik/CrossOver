% This is a script that will handle the modeling all at once.

Ks=1:8;

SS=[1 2 4 8];

AES_OrF_HR=[0.855	0.905	0.785	0.720];
EMP_OrF_HR=[0.785	0.830	0.735	0.705];
RER_OrF_HR=[0.850	0.885	0.865	0.775];
KWP_OrF_HR=[0.900	0.820	0.820	0.860];
CAT_OrF_HR=[0.985	0.970	0.930	0.970];

AES_OrF_FA=[0.040	0.170	0.135	0.085];
EMP_OrF_FA=[0.040	0.155	0.285	0.245];
RER_OrF_FA=[0.030	0.250	0.450	0.420];
KWP_OrF_FA=[0.080	0.095	0.125	0.115];
CAT_OrF_FA=[0.025	0.085	0.070	0.055];

AES_2v5_HR=[0.965	0.875	0.635	0.515];
EMP_2v5_HR=[0.975	0.860	0.640	0.700];
RER_2v5_HR=[0.990	0.930	0.830	0.655];
KWP_2v5_HR=[0.965	0.895	0.750	0.730];
CAT_2v5_HR=[0.990	0.930	0.825	0.770];

AES_2v5_FA=[0.055	0.285	0.240	0.415];
EMP_2v5_FA=[0.055	0.320	0.345	0.540];
RER_2v5_FA=[0.010	0.410	0.350	0.375];
KWP_2v5_FA=[0.035	0.150	0.190	0.270];
CAT_2v5_FA=[0.020	0.135	0.235	0.475];

for n=1:length(Ks)

    K=[Ks(n) Ks(n) Ks(n) Ks(n)];

    AES_OrF_data=[K' SS' AES_OrF_HR' AES_OrF_FA'];
    EMP_OrF_data=[K' SS' EMP_OrF_HR' EMP_OrF_FA'];
    RER_OrF_data=[K' SS' RER_OrF_HR' RER_OrF_FA'];
    KWP_OrF_data=[K' SS' KWP_OrF_HR' KWP_OrF_FA'];
    CAT_OrF_data=[K' SS' CAT_OrF_HR' CAT_OrF_FA'];

    AES_2v5_data=[K' SS' AES_2v5_HR' AES_2v5_FA'];
    EMP_2v5_data=[K' SS' EMP_2v5_HR' EMP_2v5_FA'];
    RER_2v5_data=[K' SS' RER_2v5_HR' RER_2v5_FA'];
    KWP_2v5_data=[K' SS' KWP_2v5_HR' KWP_2v5_FA'];
    CAT_2v5_data=[K' SS' CAT_2v5_HR' CAT_2v5_FA'];


    [AES_OrF_S,AES_OrF_C,AES_OrF_SSE]=sumrulefit(AES_OrF_data);
    [EMP_OrF_S,EMP_OrF_C,EMP_OrF_SSE]=sumrulefit(EMP_OrF_data);
    [RER_OrF_S,RER_OrF_C,RER_OrF_SSE]=sumrulefit(RER_OrF_data);
    [KWP_OrF_S,KWP_OrF_C,KWP_OrF_SSE]=sumrulefit(KWP_OrF_data);
    [CAT_OrF_S,CAT_OrF_C,CAT_OrF_SSE]=sumrulefit(CAT_OrF_data);


    [AES_2v5_S,AES_2v5_C,AES_2v5_SSE]=sumrulefit(AES_2v5_data);
    [EMP_2v5_S,EMP_2v5_C,EMP_2v5_SSE]=sumrulefit(EMP_2v5_data);
    [RER_2v5_S,RER_2v5_C,RER_2v5_SSE]=sumrulefit(RER_2v5_data);
    [KWP_2v5_S,KWP_2v5_C,KWP_2v5_SSE]=sumrulefit(KWP_2v5_data);
    [CAT_2v5_S,CAT_2v5_C,CAT_2v5_SSE]=sumrulefit(CAT_2v5_data);


    fprintf('\n\n-----------------------------------\n')
    fprintf('\nOrientation Search\n')
    fprintf('Sum Rule\tK=%d\n',K(1));
    fprintf('Sub\t S\t C\tSSE\n')
    fprintf('AES\t%1.3f\t%1.3f\t%1.3f\n',AES_OrF_S, AES_OrF_C, AES_OrF_SSE);
    fprintf('EMP\t%1.3f\t%1.3f\t%1.3f\n',EMP_OrF_S, EMP_OrF_C, EMP_OrF_SSE);
    fprintf('RER\t%1.3f\t%1.3f\t%1.3f\n',RER_OrF_S, RER_OrF_C, RER_OrF_SSE);
    fprintf('KWP\t%1.3f\t%1.3f\t%1.3f\n',KWP_OrF_S, KWP_OrF_C, KWP_OrF_SSE);
    fprintf('CAT\t%1.3f\t%1.3f\t%1.3f\n',CAT_OrF_S, CAT_OrF_C, CAT_OrF_SSE);

    fprintf('\n\n2v5 Search\n')
    fprintf('Sum Rule\tK=%d\n',K(1));
    fprintf('Sub\t S\t C\tSSE\n')
    fprintf('AES\t%1.3f\t%1.3f\t%1.3f\n',AES_2v5_S, AES_2v5_C, AES_2v5_SSE);
    fprintf('EMP\t%1.3f\t%1.3f\t%1.3f\n',EMP_2v5_S, EMP_2v5_C, EMP_2v5_SSE);
    fprintf('RER\t%1.3f\t%1.3f\t%1.3f\n',RER_2v5_S, RER_2v5_C, RER_2v5_SSE);
    fprintf('KWP\t%1.3f\t%1.3f\t%1.3f\n',KWP_2v5_S, KWP_2v5_C, KWP_2v5_SSE);
    fprintf('CAT\t%1.3f\t%1.3f\t%1.3f\n',CAT_2v5_S, CAT_2v5_C, CAT_2v5_SSE);

end