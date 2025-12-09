# Fluxo-optico-IA

O arquivo atual tem duas técnicas de processamento
----------------------------------------------------------------
Rede neural

Primeiro o arquivo dados processa o DataSet que é
composto por 4 pastas com 24 vídeos em cada pasta
sendo cada pasta com uma orientação. O programa dados
gera um arquivo processado, que se chama meuDataset.

O meuDataset é utilizado no programa rede, que é a base 
para o treinamento da rede neural. O programa rede gera um arquivo 
que se chama redeDirecao, que será usado no programa 
visaodeanguloRedeneural.

No programa visaodeanguloRedeneural os valores de v e u serão comparados
aos parâmetros da redeDirecao retornando a direção do objeto na 
câmera.


----------------------------------------------------------------
Fuzzy

A técnica de inferência Fuzzy é bem mais compacta, utilizando somente 
o programa visaodeanguloFuzzy, excluindo a necessidade de dataset e fazendo 
a inferência somente nos dados u e v com filtro de Kalman.

-----------------------------------------------------------------
