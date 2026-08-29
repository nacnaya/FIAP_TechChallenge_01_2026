@echo off
setlocal EnableExtensions EnableDelayedExpansion
title FIAP Tech Challenge
cd /d "%~dp0"

set "IMAGE_NAME=fiap-tech-challenge"
set "CONTAINER_NAME=fiap-tech-challenge"

goto MENU


:: ============================================================
:: MENU PRINCIPAL
:: ============================================================

:MENU
cls

echo.
echo ============================================================
echo                    FIAP TECH CHALLENGE
echo ============================================================
echo.

call :VERIFICAR_DOCKER

if "!DOCKER_INSTALADO!"=="0" (
    echo Status: DOCKER NAO INSTALADO
) else if "!DOCKER_ATIVO!"=="0" (
    echo Status: DOCKER DESATIVADO
) else (
    docker inspect -f "{{.State.Running}}" "%CONTAINER_NAME%" 2>nul | findstr /x "true" >nul

    if not errorlevel 1 (
        echo Status: PROJETO EM EXECUCAO
    ) else (
        echo Status: PROJETO PARADO
    )
)

echo.
echo ------------------------------------------------------------
echo.
echo [1] Iniciar projeto
echo [2] Encerrar projeto
echo [3] Verificar status
echo [4] Sair
echo.
echo ------------------------------------------------------------
echo.

set "OPCAO="
set /p "OPCAO=Escolha uma opcao: "

if "%OPCAO%"=="1" goto INICIAR
if "%OPCAO%"=="2" goto ENCERRAR
if "%OPCAO%"=="3" goto STATUS
if "%OPCAO%"=="4" goto SAIR

echo.
echo Opcao invalida.
timeout /t 2 /nobreak >nul
goto MENU


:: ============================================================
:: INICIAR PROJETO
:: ============================================================

:INICIAR
cls

echo.
echo ============================================================
echo                   INICIANDO PROJETO
echo ============================================================
echo.

call :VERIFICAR_DOCKER

if "!DOCKER_INSTALADO!"=="0" (
    echo ERRO: Docker nao foi encontrado neste computador.
    echo.
    echo Instale o Docker Desktop e tente novamente.
    echo.
    pause
    goto MENU
)

if "!DOCKER_ATIVO!"=="0" (
    echo ERRO: Docker Desktop nao esta em execucao.
    echo.
    echo Abra o Docker Desktop, aguarde iniciar e tente novamente.
    echo.
    pause
    goto MENU
)


:: Verificar se o container ja esta funcionando

docker inspect -f "{{.State.Running}}" "%CONTAINER_NAME%" 2>nul | findstr /x "true" >nul

if not errorlevel 1 (
    echo O projeto ja esta em execucao.
    echo.
    echo Abrindo o Jupyter novamente...
    echo.

    call :ABRIR_JUPYTER

    echo.
    pause
    goto MENU
)


:: Remover container antigo, caso exista

docker rm -f "%CONTAINER_NAME%" >nul 2>&1


echo [1/4] Docker funcionando corretamente.
echo.

echo [2/4] Preparando a imagem Docker...
echo.

docker build -t "%IMAGE_NAME%" .

if errorlevel 1 (
    echo.
    echo ============================================================
    echo ERRO AO CONSTRUIR A IMAGEM DOCKER
    echo ============================================================
    echo.
    echo Verifique as mensagens acima.
    echo.
    pause
    goto MENU
)

echo.
echo Imagem preparada com sucesso.
echo.


:: ============================================================
:: INICIAR CONTAINER
:: Docker escolhe automaticamente uma porta livre no Windows
:: ============================================================

echo [3/4] Iniciando o container...
echo.

docker run -d --rm ^
    --name "%CONTAINER_NAME%" ^
    -p 127.0.0.1::8888 ^
    "%IMAGE_NAME%" >nul

if errorlevel 1 (
    echo.
    echo ERRO: Nao foi possivel iniciar o container.
    echo.
    pause
    goto MENU
)

echo Container iniciado com sucesso.
echo.


:: ============================================================
:: AGUARDAR JUPYTER
:: ============================================================

echo [4/4] Aguardando o Jupyter...
echo.

set "JUPYTER_PRONTO=0"

for /L %%I in (1,1,30) do (

    docker exec "%CONTAINER_NAME%" jupyter server list 2>nul | findstr /I "http://" >nul

    if not errorlevel 1 (
        set "JUPYTER_PRONTO=1"
        goto JUPYTER_ENCONTRADO
    )

    timeout /t 1 /nobreak >nul
)


:JUPYTER_ENCONTRADO

if "!JUPYTER_PRONTO!"=="0" (
    echo.
    echo ERRO: O Jupyter demorou muito para iniciar.
    echo.
    echo Para verificar os detalhes:
    echo docker logs %CONTAINER_NAME%
    echo.
    pause
    goto MENU
)


echo Jupyter iniciado com sucesso.
echo.

call :ABRIR_JUPYTER

echo.
echo ============================================================
echo               PROJETO INICIADO COM SUCESSO
echo ============================================================
echo.
echo O navegador foi aberto automaticamente.
echo.
echo Voce pode minimizar esta janela.
echo Quando terminar, volte aqui e escolha:
echo.
echo [2] Encerrar projeto
echo.
echo ============================================================
echo.

pause
goto MENU


:: ============================================================
:: ABRIR JUPYTER
:: ============================================================

:ABRIR_JUPYTER

set "HOST_PORT="
set "JUPYTER_URL="
set "QUERY="
set "LOCAL_URL="


:: Descobrir a porta escolhida automaticamente pelo Docker

for /f "tokens=2 delims=:" %%P in ('docker port "%CONTAINER_NAME%" 8888/tcp 2^>nul') do (
    set "HOST_PORT=%%P"
)

if not defined HOST_PORT (
    echo ERRO: Nao foi possivel identificar a porta do Jupyter.
    exit /b 1
)


:: Obter URL e token diretamente do Jupyter

for /f "tokens=1" %%U in ('docker exec "%CONTAINER_NAME%" jupyter server list 2^>nul ^| findstr /I "http://"') do (
    set "JUPYTER_URL=%%U"
)


if defined JUPYTER_URL (

    for /f "tokens=2 delims=?" %%Q in ("!JUPYTER_URL!") do (
        set "QUERY=%%Q"
    )

)


if defined QUERY (
    set "LOCAL_URL=http://127.0.0.1:!HOST_PORT!/tree?!QUERY!"
) else (
    set "LOCAL_URL=http://127.0.0.1:!HOST_PORT!/tree"
)


echo Jupyter:
echo !LOCAL_URL!
echo.
echo Abrindo o navegador...

start "" "!LOCAL_URL!"

exit /b 0


:: ============================================================
:: ENCERRAR PROJETO
:: ============================================================

:ENCERRAR
cls

echo.
echo ============================================================
echo                   ENCERRANDO PROJETO
echo ============================================================
echo.

call :VERIFICAR_DOCKER

if "!DOCKER_INSTALADO!"=="0" (
    echo Docker nao esta instalado.
    echo.
    pause
    goto MENU
)

if "!DOCKER_ATIVO!"=="0" (
    echo Docker Desktop nao esta em execucao.
    echo.
    pause
    goto MENU
)


docker inspect -f "{{.State.Running}}" "%CONTAINER_NAME%" 2>nul | findstr /x "true" >nul

if errorlevel 1 (
    echo O projeto ja esta parado.
    echo.
    pause
    goto MENU
)


echo Encerrando o container...
echo.

docker stop "%CONTAINER_NAME%" >nul 2>&1

if errorlevel 1 (
    echo ERRO: Nao foi possivel encerrar o projeto.
) else (
    echo Projeto encerrado com sucesso.
)

echo.
echo A aba do navegador pode ser fechada manualmente.
echo.

pause
goto MENU


:: ============================================================
:: STATUS
:: ============================================================

:STATUS
cls

echo.
echo ============================================================
echo                    STATUS DO PROJETO
echo ============================================================
echo.

call :VERIFICAR_DOCKER

if "!DOCKER_INSTALADO!"=="0" (
    echo Docker: NAO INSTALADO
    echo.
    pause
    goto MENU
)

echo Docker instalado: SIM

if "!DOCKER_ATIVO!"=="0" (
    echo Docker Desktop: DESATIVADO
    echo Projeto: PARADO
    echo.
    pause
    goto MENU
)

echo Docker Desktop: ATIVO


docker inspect -f "{{.State.Running}}" "%CONTAINER_NAME%" 2>nul | findstr /x "true" >nul

if errorlevel 1 (

    echo Projeto: PARADO

) else (

    echo Projeto: EM EXECUCAO

    set "HOST_PORT="

    for /f "tokens=2 delims=:" %%P in ('docker port "%CONTAINER_NAME%" 8888/tcp 2^>nul') do (
        set "HOST_PORT=%%P"
    )

    if defined HOST_PORT (
        echo Porta local: !HOST_PORT!
    )
)

echo.
pause
goto MENU


:: ============================================================
:: VERIFICAR DOCKER
:: ============================================================

:VERIFICAR_DOCKER

set "DOCKER_INSTALADO=0"
set "DOCKER_ATIVO=0"

where docker >nul 2>&1

if errorlevel 1 (
    exit /b
)

set "DOCKER_INSTALADO=1"

docker info >nul 2>&1

if errorlevel 1 (
    exit /b
)

set "DOCKER_ATIVO=1"

exit /b


:: ============================================================
:: SAIR
:: ============================================================

:SAIR
endlocal
exit /b