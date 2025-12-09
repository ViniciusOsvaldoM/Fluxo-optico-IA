%Carrega rede treinada
load('redeDirecao.mat','net');

% Leitura do vídeo
videoReader = VideoReader('C:\Users\Familia Guimarães\Documents\Visao de angulo\Resultados\Validacao\validacao.mp4');
opticFlow = opticalFlowLK('NoiseThreshold',0.01);

movimentos = [];
frameCount = 0;

% Cria figura com dois subplots: vídeo e gráfico
hFig = figure;
subplot(2,1,1); % parte de cima para o vídeo
hVideo = imshow(zeros(videoReader.Height, videoReader.Width, 3, 'uint8'));
title('Vídeo com análise');

subplot(2,1,2); % parte de baixo para o gráfico
hPlot = plot(0,0,'b',0,0,'r');
xlabel('Frame');
ylabel('Valor');
legend('u (horizontal)','v (vertical)');
title('Evolução de u e v ao longo do tempo');
grid on;

% Inicializa Kalman para u e v 
dt = 1; % intervalo entre frames
A = [1 dt; 0 1];   % transição de estado (posição + velocidade)
H = [1 0];         % medição (só posição)
Q = 1e-4 * eye(2); % ruído do processo
R = 1e-2;          % ruído da medição
P_u = eye(2);      % covariância inicial para u
P_v = eye(2);      % covariância inicial para v
xU = [0; 0];       % estado inicial u
xV = [0; 0];       % estado inicial v

while hasFrame(videoReader)
    frameRGB = readFrame(videoReader);
    frameGray = rgb2gray(frameRGB);
    frameCount = frameCount + 1;

    % Calcula fluxo óptico
     flow = estimateFlow(opticFlow, frameGray);
    

    % Média dos vetores de movimento
    u_measured = mean(flow.Vx(:));
    v_measured = mean(flow.Vy(:));
     
    % Kalman para u
    % Predição
    xU = A * xU;
    P_u = A * P_u * A' + Q;
    % Correção
    K_u = P_u * H' / (H * P_u * H' + R);
    xU = xU + K_u * (u_measured - H * xU);
    P_u = (eye(2) - K_u * H) * P_u;
    u = xU(1);

    % Kalman para v 
    xV = A * xV;
    P_v = A * P_v * A' + Q;
    K_v = P_v * H' / (H * P_v * H' + R);
    xV = xV + K_v * (v_measured - H * xV);
    P_v = (eye(2) - K_v * H) * P_v;
    v = xV(1);

    % Guarda valores filtrados
    movimentos = [movimentos; u v];

    % --- Usa rede neural para classificar ---
    direcao = classify(net,[u_measured v_measured]);

    movimentos = [movimentos; u v];

    %Usa rede neural para classificar
    direcao = classify(net,[u v]); %rede decide a direção

    % Escreve direção na imagem
    framOut = insertText(frameRGB,[20 20],string(direcao),'FontSize',24,'BoxColor','yellow','BoxOpacity',0.6);

    % Atualiza subplot do vídeo
    subplot(2,1,1);
    imshow(framOut);
    hold on;
    plot(flow, 'DecimationFactor',[5 5],'ScaleFactor',10);
    hold off;

    % Atualiza subplot do gráfico
    subplot(2,1,2);
    set(hPlot(1),'XData',1:size(movimentos,1),'YData',movimentos(:,1)); % u
    set(hPlot(2),'XData',1:size(movimentos,1),'YData',movimentos(:,2)); % v
    drawnow;
end

