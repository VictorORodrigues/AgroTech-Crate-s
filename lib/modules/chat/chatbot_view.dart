import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../utils/agro_alerts.dart';

/// --- VOZ DO CURRAL: ASSISTENTE VIRTUAL EDGE AI ---
/// Este widget simula um processamento de linguagem natural (NLP) 100% offline.
/// Ele atua como uma interface de conversação para os motores de Machine Learning
/// e Recomendação Genética do aplicativo AgroTech Crateús.

class Message {
  final String text;
  final bool isUser;
  final DateTime time;

  Message({required this.text, required this.isUser, required this.time});
}

class ChatbotView extends StatefulWidget {
  @override
  _ChatbotViewState createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  // Variáveis para Speech-to-Text
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  double _confidence = 1.0;
  late AnimationController _micAnimationController;

  @override
  void initState() {
    super.initState();
    // Mensagem de boas-vindas inicial
    _messages.add(Message(
      text: "Olá, produtor! Eu sou a Voz do Curral. 🤠\nComo posso ajudar seu rebanho hoje? Posso calcular chances de prenhez ou sugerir cruzamentos genéticos.",
      isUser: false,
      time: DateTime.now(),
    ));

    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    _speech.stop();
    super.dispose();
  }

  /// --- LÓGICA DE RECONHECIMENTO DE VOZ ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
          localeId: 'pt_BR',
          listenMode: stt.ListenMode.dictation, // Otimizado para fala longa
          listenFor: const Duration(minutes: 5), // Tempo total máximo
          pauseFor: const Duration(seconds: 20), // Tolera pausas longas
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// --- MOTOR DE NLP LOCAL (BASEADO EM INTENÇÕES) ---
  /// Esta função analisa as palavras-chave para disparar as lógicas do sistema.
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true, time: DateTime.now()));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Simula tempo de processamento da "IA Embarcada"
    Timer(const Duration(milliseconds: 1500), () {
      String response = _processOfflineIntelligence(text.toLowerCase());
      setState(() {
        _isTyping = false;
        _messages.add(Message(text: response, isUser: false, time: DateTime.now()));
      });
      _scrollToBottom();
    });
  }

  String _processOfflineIntelligence(String input) {
    // --- 1. INTENÇÃO: ANÁLISE DE PRENHEZ E IATF ---
    if (input.contains("analisar") || input.contains("prenhez") || input.contains("previsão") || input.contains("chance")) {
      return "🔍 Iniciando Protocolo de Análise Preditiva...\n\nBaseado no THI atual (76.8) e no histórico de Escore Corporal (ECC médio 3.2) do seu rebanho, a probabilidade de concepção para protocolos de IATF realizados hoje é de 74%.\n\n💡 Dica da IA: Animais do lote 'Elite' podem chegar a 88% se a inseminação ocorrer no período noturno.";
    }

    // --- 2. INTENÇÃO: RESUMO E DADOS DO REBANHO ---
    if (input.contains("rebanho") || input.contains("meus animais") || input.contains("quantos") || input.contains("matrizes")) {
      return "📊 Resumo Técnico do seu Rebanho:\n\nDetectei 45 animais ativos em seu banco de dados.\n- Matrizes Prenhes: 18 (40% do plantel)\n- Fêmeas Vazias: 12 (Custo de Ócio detectado)\n- IEP Médio: 13.2 meses.\n\nDeseja que eu identifique quais fêmeas precisam entrar em protocolo hormonal hoje?";
    }

    // --- 3. INTENÇÃO: MELHORAMENTO GENÉTICO E CRUZAMENTO ---
    if (input.contains("cruzamento") || input.contains("touro") || input.contains("macho") || input.contains("reprodutor") || input.contains("match")) {
      return "🧬 Analisando Árvore Genealógica e Heterose...\n\nPara as suas matrizes Nelore (linhagem Maranhão), o sistema recomenda o uso do reprodutor 'Sertão Valente'.\n\nJustificativa: Detectamos 0% de consanguinidade e um potencial de ganho de peso (GMD) no filhote superior a 0.95kg/dia em sistema extensivo.";
    }

    // --- 4. INTENÇÃO: EXPLICAÇÃO DA IA ---
    if (input.contains("ia") || input.contains("inteligência") || input.contains("algoritmo") || input.contains("como funciona")) {
      return "🤖 Como minha inteligência funciona:\n\nEu utilizo modelos de Edge AI para processar três pilares:\n1. Clima (THI de Crateús em tempo real)\n2. Genética (Bloqueio de parentesco e choque de sangue)\n3. Zootecnia (ECC e IEP).\n\nEu aprendo com cada parto registrado para tornar as próximas previsões mais precisas.";
    }

    // --- 5. INTENÇÃO: SAÚDE E ALERTAS ---
    if (input.contains("saúde") || input.contains("vacina") || input.contains("doente") || input.contains("problema")) {
      return "💉 Monitoramento Sanitário Ativo:\n\nNão identifiquei surtos epidemiológicos na região de Crateús nas últimas 24h. No entanto, 5 matrizes do seu lote B estão com a vacina de reforço agendada para daqui a 3 dias.\n\nDeseja ver a lista desses animais?";
    }

    // --- 6. CUMPRIMENTOS E NAVEGAÇÃO ---
    if (input.contains("olá") || input.contains("oi") || input.contains("ajuda")) {
      return "Olá! Sou a Voz do Curral. 🤠\nPosso fazer uma análise de prenhez, listar suas melhores matrizes ou sugerir o melhor cruzamento genético para seu gado. O que deseja saber agora?";
    }

    // --- FALLBACK (Caso não entenda) ---
    return "Ainda estou processando essa informação no meu banco de dados local. 🚜 Tente perguntar: 'Qual a chance de prenhez?', 'Resumo do meu rebanho' ou 'Sugerir um cruzamento'.";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent, width: 1),
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.psychology, color: Colors.greenAccent),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Voz do Curral", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text("AGRO-AI ACTIVE", style: TextStyle(fontSize: 10, color: Colors.greenAccent.withOpacity(0.8), letterSpacing: 1.2)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
            tooltip: "Limpar Chat",
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(Message(
                  text: "Sistemas reiniciados. Como posso ajudar seu rebanho agora?",
                  isUser: false,
                  time: DateTime.now(),
                ));
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E08),
              const Color(0xFF141E10),
              const Color(0xFF0D150B),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildFuturisticBubble(_messages[index]);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft, 
                  child: Text(
                    "PROCESSANDO DADOS...", 
                    style: TextStyle(fontSize: 10, color: Colors.greenAccent.withOpacity(0.5), letterSpacing: 2)
                  )
                ),
              ),
            _buildFuturisticInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(1), // Para borda neon
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: message.isUser 
              ? [Colors.greenAccent.withOpacity(0.5), Colors.green.withOpacity(0.2)]
              : [Colors.white10, Colors.white12],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: message.isUser ? const Color(0xFF1A2E1A) : const Color(0xFF222222),
            borderRadius: BorderRadius.circular(19),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.greenAccent : Colors.white.withOpacity(0.9), 
                  fontSize: 14,
                  height: 1.4
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  DateFormat('HH:mm').format(message.time),
                  style: TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(top: BorderSide(color: Colors.greenAccent.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                style: const TextStyle(color: Colors.white),
                maxLines: null, // Permite expansão infinita para baixo
                minLines: 1,    // Começa com uma linha
                decoration: InputDecoration(
                  hintText: "Terminal de comando IA...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _listen,
            child: AnimatedBuilder(
              animation: _micAnimationController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isListening ? Colors.red : Colors.greenAccent.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.greenAccent,
                    size: 20,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
              tooltip: "Processar com IA",
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
