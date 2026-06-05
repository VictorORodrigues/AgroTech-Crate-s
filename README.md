# Agrotech - Crateús

O que é o Agrotech?

O **Agrotech** é uma plataforma de inteligência preditiva, gestão reprodutiva e rastreabilidade digital (Agro 4.0) desenvolvida especificamente para a realidade da pecuária (Bovinos, Caprinos e Ovinos) no Semiárido crateuense. 

Mais do que uma simples caderneta digital, o sistema atua como um **cérebro zootécnico embarcado no celular**, automatizando cálculos complexos baseados em ciclos biológicos, mitigando os impactos do estresse térmico regional (THI) e transformando dados de campo em indicadores de viabilidade econômica e evolução genética.

---

## 🚀 Principais Funcionalidades

### 1. Automação de Ciclos Biológicos (Agenda Preditiva)
O Agrotech elimina a necessidade de o produtor calcular manualmente os prazos reprodutivos. Ao registrar uma ação principal (como uma IATF ou um Parto), o aplicativo calcula e agenda de forma automatizada no calendário:
* **Confirmação de Gestação:** Alertas para exames de toque ou ultrassom (30-60 dias).
* **Retorno ao Cio:** Monitoramento crítico no 21º dia pós-manejo para identificar falhas reprodutivas precocemente.
* **Secagem do Leite:** Avisos para interrupção de ordenha pré-parto respeitando a fisiologia de cada espécie.
* **Previsão de Parto:** Planejamento de lotes maternidade e protocolos vacinais pré-natais.

### 📊 2. Dashboard de Inteligência Zootécnica e Financeira
Central de controle reativa e filtrável por espécie (Bovinos, Caprinos e Ovinos) e período, apresentando:
* **Custo do Ócio:** Indicador financeiro que calcula o prejuízo invisível acumulado por manter fêmeas vazias consumindo recursos.
* **ROI Genético:** Gráfico de valorização de mercado dos filhotes oriundos de acasalamento direcionado.
* **Mapeamento por THI:** Correlação estatística entre o Índice de Temperatura e Umidade e a taxa de concepção, apontando os meses de maior estresse térmico em Crateús.
* **Ranking Elite:** Identificação automática das fêmeas com melhor habilidade materna para replicação genética e sugestões de descarte econômico.

### 🔲 3. Rastreabilidade Digital (Agro 4.0) via QR Code
O aplicativo implementa o conceito de transparência de cadeia e auditoria externa através de links dinâmicos:
* **Bypass de Segurança:** A leitura do QR Code físico do brinco do animal por qualquer smartphone comum abre uma URL pública do portal web.
* **Acesso Sem Barreiras:** Compradores, veterinários ou fiscais sanitários acessam a ficha técnica, árvore genealógica de linhagem e certificados de vacinação **sem precisar realizar login ou ter o app instalado**.

### 📱 4. Operação Híbrida e Resiliente (Offline-First)
Desenhado para o interior onde a conectividade é escassa:
* Armazenamento local seguro das informações do rebanho.
* Sincronização automática em background com a nuvem assim que o dispositivo detecta sinal de internet.

---

## 🛠️ Arquitetura Técnica e Engenharia de Dados

O ecossistema foi projetado utilizando padrões de projetos rigorosos, garantindo alta escalabilidade, manutenibilidade e conformidade com a **LGPD (Lei Geral de Proteção de Dados)**.

### Modelo de Dados Orientado a Objetos (UML)
* **Especialização por Herança:** Implementação de classes específicas para `Macho` (métricas andrológicas, sêmen, perímetro escrotal) e `Femea` (histórico de partos, status reprodutivo), estendendo uma classe base abstrata `Animal`.
* **Consistência de Dados:** Uso de `Enumerations (Enums)` para o atributo de **Aptidão** (`rustica` vs `alta_producao`), blindando o banco contra inconsistências e otimizando filtros da IA.

### Stack Tecnológica
* **Frontend/Mobile:** Flutter & Dart (Arquitetura limpa com gerência de estado reativa).
* **Banco de Dados Local:** SQLite/Isar para suporte completo a operações Offline.
* **Infraestrutura em Nuvem:** Google Cloud Firestore (Banco de dados NoSQL estruturado via JSON).
* **Hospedagem Web:** Firebase Hosting para o portal de consulta pública do QR Code e documentos de privacidade.

### 🔒 Política de Segurança (Firestore Security Rules)
O banco de dados utiliza regras granulares de acesso:
```javascript
match /animals/{animalId} {
  allow read: if true;               // Leitura pública via link do QR Code
  allow write: if request.auth != null; // Escrita estritamente trancada para usuários autenticados
}
