!pip install "numpy<2.0.0"
import pandas as pd

# Lendo o CSV de treinamento para vermos as colunas
df_imagens = pd.read_csv('csv/mass_case_description_train_set.csv')

# Exibindo as primeiras 3 linhas
display(df_imagens.head(3))
import os
import shutil
import pandas as pd

base_dir = 'dataset_imagens'
os.makedirs(os.path.join(base_dir, 'maligno'), exist_ok=True)
os.makedirs(os.path.join(base_dir, 'benigno'), exist_ok=True)

df = pd.read_csv('csv/mass_case_description_train_set.csv')
pasta_origem_jpegs = 'jpeg'

print("1. Mapeando todas as imagens da pasta 'jpeg' (Isso pode levar alguns segundos)...")
mapa_imagens = {}

# Vasculha a pasta jpeg e guarda o caminho de cada foto associado ao seu código 1.3.6...
for root, dirs, files in os.walk(pasta_origem_jpegs):
    for file in files:
        if file.lower().endswith(('.jpg', '.jpeg', '.png')):
            caminho_completo = os.path.join(root, file)
            # Quebra o caminho para pegar a pasta com o código 1.3.6...
            for parte in caminho_completo.replace('\\', '/').split('/'):
                if '1.3.6.1.4' in parte:
                    mapa_imagens[parte] = caminho_completo

print(f"-> {len(mapa_imagens)} pastas de imagens encontradas e mapeadas!")
print("2. Cruzando os dados com o CSV e copiando para a IA...")

copiados = 0
erros = 0

for index, row in df.iterrows():
    diagnostico = str(row['pathology']).strip().upper()
    pasta_destino = 'maligno' if diagnostico == 'MALIGNANT' else 'benigno'
    
    caminho_csv = str(row['image file path'])
    imagem_encontrada = False
    
    # Procura se algum código 1.3.6... dessa linha do CSV está no nosso mapa
    for parte_csv in caminho_csv.split('/'):
        if '1.3.6.1.4' in parte_csv:
            parte_csv = parte_csv.strip()
            if parte_csv in mapa_imagens:
                origem_arquivo = mapa_imagens[parte_csv]
                
                # Aproveitamos para dar um nome legível para a foto (ex: P_00001_LEFT_CC.jpg)
                nome_novo = f"{row['patient_id']}_{row['left or right breast']}_{row['image view']}.jpg"
                destino_arquivo = os.path.join(base_dir, pasta_destino, nome_novo)
                
                shutil.copy(origem_arquivo, destino_arquivo)
                copiados += 1
                imagem_encontrada = True
                break # Já achou a imagem dessa linha, vai pra próxima
                
    if not imagem_encontrada:
        erros += 1

print(f"--- Processo Concluído! ---")
print(f"✅ {copiados} imagens organizadas com sucesso na pasta 'dataset_imagens'.")
if erros > 0:
    print(f"⚠️ {erros} não encontradas (podem pertencer a outro arquivo CSV ou teste).")
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator

print(f"Versão do TensorFlow: {tf.__version__}")

# 1. Carregando as imagens organizadas para a memória da IA
gerador_treino = ImageDataGenerator(rescale=1./255, validation_split=0.2)

base_treino = gerador_treino.flow_from_directory(
    'dataset_imagens',
    target_size=(150, 150), # Padroniza o tamanho de todas as fotos
    batch_size=32,
    class_mode='binary',    # Alvo: 0 (Benigno) ou 1 (Maligno)
    subset='training'
)

base_validacao = gerador_treino.flow_from_directory(
    'dataset_imagens',
    target_size=(150, 150),
    batch_size=32,
    class_mode='binary',
    subset='validation'
)

# 2. Construindo o "Cérebro" Visual (Rede Neural Convolucional)
modelo_cnn = models.Sequential([
    layers.Conv2D(32, (3, 3), activation='relu', input_shape=(150, 150, 3)),
    layers.MaxPooling2D(2, 2),
    
    layers.Conv2D(64, (3, 3), activation='relu'),
    layers.MaxPooling2D(2, 2),
    
    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D(2, 2),
    
    layers.Flatten(),
    layers.Dense(512, activation='relu'),
    layers.Dense(1, activation='sigmoid') # A decisão final
])

# 3. Compilando o modelo com foco nas métricas médicas
modelo_cnn.compile(optimizer='adam',
                   loss='binary_crossentropy',
                   metrics=['accuracy', 'Recall'])

print("\n🚀 Iniciando o treinamento da Inteligência Artificial Visual...\n")

# 4. Treinamento (A IA olhando foto por foto)
historico = modelo_cnn.fit(
    base_treino,
    epochs=10, # Vai revisar todo o banco de imagens 10 vezes para aprender
    validation_data=base_validacao
)

print("\n--- Treinamento Concluído com Sucesso! ---")