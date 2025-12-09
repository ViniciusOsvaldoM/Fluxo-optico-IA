% Treinamento da Rede Neural
load('meuDataset.mat'); % obtendo X e Y


% Define arquitetura da rede
layers = [
    featureInputLayer(2)              % entrada: u e v
    fullyConnectedLayer(100)           % camada oculta
    reluLayer
    fullyConnectedLayer(50)           % camada oculta
    reluLayer
    fullyConnectedLayer(4)            % saída: 4 classes
    softmaxLayer
    classificationLayer];


cv = cvpartition(Y,'HoldOut',0.2);
XTrain = X(training(cv),:);
YTrain = Y(training(cv));
XVal = X(test(cv),:);
YVal = Y(test(cv));

% Opções de treino
options = trainingOptions('adam', ...
    'MaxEpochs',50, ...
    'ValidationData',{XVal,YVal}, ...
    'Plots','training-progress');

% Treina a rede
net = trainNetwork(X, Y, layers, options);

% Salva o modelo treinado
save('redeDirecao.mat','net');