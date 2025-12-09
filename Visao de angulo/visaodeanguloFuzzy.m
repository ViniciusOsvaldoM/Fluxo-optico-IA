% Leitura do vídeo
videoReader = VideoReader('C:\Users\Familia Guimarães\Documents\Visao de angulo\Resultados\Validacao\validacao.mp4');
opticFlow = opticalFlowLK('NoiseThreshold',0.01);
%-----------------------------------------------------------------
medidos   = []; % valores brutos u,v
filtrados = []; % valores filtrados u,v
frameCount = 0;
%-----------------------------------------------------------------
% Cria figura com dois subplots: vídeo e gráfico
hFig = figure;
subplot(2,1,1); % parte de cima para o vídeo
hVideo = imshow(zeros(videoReader.Height, videoReader.Width, 3, 'uint8'));
title('Vídeo com análise');

subplot(2,1,2); % parte de baixo para o gráfico
hPlot = plot(0,0,'b',0,0,'r',0,0,'g--',0,0,'m--');
xlabel('Frame');
ylabel('Valor');
legend('u medido','v medido','u Kalman','v Kalman');
title('Evolução de u e v (medido vs Kalman)');
grid on;
%-----------------------------------------------------------------
% Inicializa Kalman para u e v 
dt = 1; % intervalo entre frames
A = [1 dt; 0 1];   % transição de estado (posição + velocidade)
H = [1 0];         % medição (só posição)
Q = 1e-3 * eye(2); % ruído do processo
R = 1e-3;          % ruído da medição
P_u = eye(2);      % covariância inicial para u
P_v = eye(2);      % covariância inicial para v
xU = [0; 0];       % estado inicial u
xV = [0; 0];       % estado inicial v
%-----------------------------------------------------------------
% Cria sistema fuzzy
fis = sugfis('Name','Direcao');

% Entradas
fis = addInput(fis,[-1 1],'Name','u');
fis = addInput(fis,[-1 1],'Name','v');

% Funções de pertinência para u
fis = addMF(fis,'u','trimf',[-1 -1 0],'Name','Esquerda');
fis = addMF(fis,'u','trimf',[-0.2 0 0.2],'Name','Centro');
fis = addMF(fis,'u','trimf',[0 1 1],'Name','Direita');

% Funções de pertinência para v
fis = addMF(fis,'v','trimf',[-1 -1 0],'Name','Cima');
fis = addMF(fis,'v','trimf',[-0.2 0 0.2],'Name','Centro');
fis = addMF(fis,'v','trimf',[0 1 1],'Name','Baixo');

% Saída
fis = addOutput(fis,[0 4],'Name','Direcao');
fis = addMF(fis,'Direcao','constant',1,'Name','Esquerda');
fis = addMF(fis,'Direcao','constant',2,'Name','Direita');
fis = addMF(fis,'Direcao','constant',3,'Name','Cima');
fis = addMF(fis,'Direcao','constant',4,'Name','Baixo');

% Regras
ruleList = [...
    1 0 1 1 1;  % Se u=Esquerda -> Direcao=Esquerda
    3 0 2 1 1;  % Se u=Direita -> Direcao=Direita
    0 1 3 1 1;  % Se v=Cima -> Direcao=Cima
    0 3 4 1 1]; % Se v=Baixo -> Direcao=Baixo
fis = addRule(fis,ruleList);
%---------------------------------------------------------------
while hasFrame(videoReader)
    frameRGB = readFrame(videoReader);
    frameGray = rgb2gray(frameRGB);
    frameCount = frameCount + 1;

    % --- Calcula fluxo óptico ---
    flow = estimateFlow(opticFlow, frameGray);

    % --- Medidas ---
    u_measured = mean(flow.Vx(:));
    v_measured = mean(flow.Vy(:));

    % --- Kalman para u ---
    xU = A * xU;
    P_u = A * P_u * A' + Q;
    K_u = P_u * H' / (H * P_u * H' + R);
    xU = xU + K_u * (u_measured - H * xU);
    P_u = (eye(2) - K_u * H) * P_u;
    u = xU(1);

    % --- Kalman para v ---
    xV = A * xV;
    P_v = A * P_v * A' + Q;
    K_v = P_v * H' / (H * P_v * H' + R);
    xV = xV + K_v * (v_measured - H * xV);
    P_v = (eye(2) - K_v * H) * P_v;
    v = xV(1);

    % Guarda valores
    medidos   = [medidos; u_measured v_measured];
    filtrados = [filtrados; u v];

    % --- Inferência fuzzy ---
    direcaoNum = evalfis(fis,[u v]);
    switch round(direcaoNum)
        case 1, direcao = "Esquerda";
        case 2, direcao = "Direita";
        case 3, direcao = "Cima";
        case 4, direcao = "Baixo";
        otherwise, direcao = "Indefinido";
    end


    % --- Escreve direção na imagem ---
    framOut = insertText(frameRGB,[20 20],string(direcao), ...
        'FontSize',24,'BoxColor','yellow','BoxOpacity',0.6);

    % Atualiza subplot do vídeo
    subplot(2,1,1);
    imshow(framOut);
    hold on;
    plot(flow, 'DecimationFactor',[5 5],'ScaleFactor',10);
    hold off;

    % Atualiza subplot do gráfico
    subplot(2,1,2);
    set(hPlot(1),'XData',1:size(medidos,1),'YData',medidos(:,1));   % u medido
    set(hPlot(2),'XData',1:size(medidos,1),'YData',medidos(:,2));   % v medido
    set(hPlot(3),'XData',1:size(filtrados,1),'YData',filtrados(:,1)); % u Kalman
    set(hPlot(4),'XData',1:size(filtrados,1),'YData',filtrados(:,2)); % v Kalman
    drawnow;
end