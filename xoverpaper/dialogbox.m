function xtest

try
    prompt={'Enter initials:','1=Col,2=Ori,3-Conj,4-TLconj,5-TvL,6-easyTvL,7-2v5','Practice Trials:','Number Reversals Until Stable','Trials Per Cell After Stable',...
            'proportion noise (0-1)','noise UP step', 'noise DOWN step', 'color1','color2','orient1','orient2','palmerStyle 0=AccNo 1=AccYes, 2=RTno, 3=RTyes '};
    def={['x' num2str(randi(100))],'3','50','20','50','.5','.025','.1','170 170 170', '0 255 255','0','90','1'};
    title='Input Variables';
    lineNo=1;
    userinput=inputdlg(prompt,title,lineNo,def,'on');
catch
    ple;
end


% upstep = .025
% downstep = .1