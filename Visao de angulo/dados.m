% Exemplo: vídeos organizados em pastas "Direita", "Esquerda", "Cima", "Baixo"
direcoes = {'Direita','Esquerda','Cima','Baixo'};
X = [];
Y = [];

for d = 1:numel(direcoes)
    folder = fullfile('C:\Users\Familia Guimarães\Documents\Visao de angulo\DataSet\', direcoes{d});
    videos = dir(fullfile(folder,'*.mp4'));
    
    for k = 1:numel(videos)
        videoReader = VideoReader(fullfile(folder,videos(k).name));
        opticFlow = opticalFlowLK('NoiseThreshold',0.01);
        u_total = 0; v_total = 0; frames = 0;
        
        while hasFrame(videoReader)
            frameGray = rgb2gray(readFrame(videoReader));
            flow = estimateFlow(opticFlow, frameGray);
            u_total = u_total + mean(flow.Vx(:));
            v_total = v_total + mean(flow.Vy(:));
            frames = frames + 1;
        end
        
        % Média do vídeo inteiro
        u = u_total/frames;
        v = v_total/frames;
        
        % Adiciona ao dataset
        X = [X; u v];
        Y = [Y; categorical(string(direcoes{d}))];
    end
end

% Salva dataset para usar no treino
save('meuDataset.mat','X','Y');