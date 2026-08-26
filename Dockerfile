FROM python:3.10-slim

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Instala dependências de sistema (necessárias para algumas bibliotecas gráficas e de imagem)
RUN apt-get update && apt-get install -y \
    gcc \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copia todos os arquivos do projeto para o container
COPY . /app/

# Instala as bibliotecas exatas utilizadas nos seus notebooks
RUN pip install --no-cache-dir \
    jupyter \
    pandas \
    numpy \
    scipy \
    scikit-learn \
    matplotlib \
    seaborn \
    shap

# Expõe a porta 8888 (padrão do Jupyter Notebook)
EXPOSE 8888

# Comando para iniciar o Jupyter Notebook automaticamente ao rodar o container
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
