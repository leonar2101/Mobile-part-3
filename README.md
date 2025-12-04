StrideLog - Fitness Tracker 🏃‍♂️📷⛅

StrideLog é um aplicativo móvel desenvolvido em Flutter para monitoramento de atividades físicas. Esta versão (Parte 3) expande o projeto original integrando recursos nativos do dispositivo e consumo de APIs externas para enriquecer a experiência do usuário.

📱 Funcionalidades

Funcionalidades Principais

Autenticação: Cadastro e Login seguro de usuários (com persistência local).

Dashboard: Visualização de estatísticas (tempo total, calorias, distância).

Histórico: Lista de todas as atividades realizadas com opção de filtro e exclusão.

Banco de Dados Local: Uso do SQflite para salvar dados offline.

🌟 Novidades da Parte 3 (Requisitos Cumpridos)

☁️ Integração com API Web (OpenWeatherMap): O aplicativo obtém automaticamente a previsão do tempo baseada na localização do usuário para indicar se as condições são favoráveis para o treino.

📍 Geolocalização (GPS): Uso do GPS nativo para obter as coordenadas (Latitude/Longitude) necessárias para a consulta do clima.

📸 Câmera Nativa: Possibilidade de tirar fotos durante ou após o treino e anexá-las ao registro da atividade.

🧠 Lógica de Avaliação: O app analisa os dados do clima e sugere se é um bom momento para treinar (ex: alerta sobre chuva ou calor extremo).

🛠️ Tecnologias Utilizadas

Linguagem: Dart (SDK >= 3.6.0)

Framework: Flutter (SDK >= 3.29.0)

Gerenciamento de Estado: Provider

Persistência: SQflite & Shared Preferences

Recursos Nativos & API:

http: Consumo da API OpenWeatherMap.

geolocator: Acesso ao GPS.

image_picker: Acesso à Câmera e Galeria.

permission_handler: Gerenciamento de permissões do Android.

🚀 Guia de Instalação e Execução

Siga os passos abaixo para rodar o projeto no seu ambiente local.

1. Pré-requisitos

Flutter SDK instalado e configurado no PATH.

Android Studio ou VS Code.

Um dispositivo Android físico (recomendado para testar Câmera e GPS) ou Emulador.

Uma chave de API (API Key) da OpenWeatherMap.

2. Clonar o Repositório

git clone <URL_DO_SEU_REPOSITORIO>
cd mobile-part-2


3. Instalar Dependências

Baixe os pacotes listados no pubspec.yaml:

flutter pub get


4. Configurar a API Key (Importante! ⚠️)

Para que o clima funcione, você precisa inserir sua chave da OpenWeatherMap.

Abra o arquivo lib/services/weather_service.dart.

Localize a linha:

final String apiKey = 'SUA_API_KEY_AQUI';


Substitua 'SUA_API_KEY_AQUI' pela sua chave real.

5. Executar o Projeto

Conecte seu dispositivo ou inicie o emulador e rode:

flutter run


📱 Permissões do Android

O aplicativo solicitará as seguintes permissões na primeira execução para que os recursos nativos funcionem:

Câmera: Para tirar fotos do treino.

Localização (GPS): Para fornecer dados precisos de clima.

Internet: Para comunicação com a API.

Se estiver usando um emulador, lembre-se de configurar uma localização fictícia nas configurações do emulador (Extended Controls > Location) para testar o clima.

🐛 Solução de Problemas Comuns

Erro de versão do Android (API 35/36):
Se você encontrar erros relacionados a androidx.activity ou versões de API, execute:

flutter clean
flutter pub get


Nota: O projeto já inclui uma configuração no build.gradle para forçar versões compatíveis das bibliotecas Android.

👨‍💻 Autor

Projeto desenvolvido para a disciplina de Programação de Dispositivos Móveis.
